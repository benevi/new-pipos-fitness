import { HttpStatus, Injectable } from '@nestjs/common';
import { daysBetween, nextPendingSession, nextPrescription, PROGRAMMING } from '@pipos/engine-rules';
import type { engineV2, ExerciseRef, TodayExercise, TodaySessionResponse } from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { Clock } from '../../common/clock';
import { localDate } from '../../common/time';
import { PrismaService } from '../../prisma/prisma.service';
import { CatalogService } from '../catalog/catalog.service';
import { EngineInputService } from '../plans/engine-input.service';
import { warmupsFor } from '../plans/plan-mapper';
import { toSetResponse } from './workout-mapper';

/**
 * Semanas dentro del ciclo de descarga (la descarga programada cae cada `deloadEveryWeeks`).
 * `planStart` es el inicio del PLAN (TrainingPlan.createdAt), no de la versión: editar el perfil
 * o regenerar crea versiones nuevas del mismo plan y no debe reiniciar el ciclo.
 */
export function weeksSinceDeload(planStart: string, today: string): number {
  const weeks = Math.max(0, Math.floor(daysBetween(planStart, today) / 7));
  return weeks % (PROGRAMMING.progression.deloadEveryWeeks.value + 1);
}

/** Carga de trabajo actual: la última que hizo (series de trabajo) o la inicial del plan. */
export function currentLoad(
  loadType: 'weighted' | 'unweighted',
  initialLoadKg: number | null,
  history: readonly engineV2.ExerciseSessionLog[],
): number | null {
  if (loadType !== 'weighted') return initialLoadKg;
  const last = [...history].sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : 0)).at(-1);
  const top = last ? Math.max(0, ...last.sets.filter((s) => !s.isWarmup).map((s) => s.loadKg)) : 0;
  return top > 0 ? top : initialLoadKg;
}

/**
 * GET /sessions/today (CUJ-2, CUJ-3, CUJ-5): el entrenamiento en curso o, si no hay, la
 * siguiente sesión pendiente del microciclo (nunca se salta una), con la prescripción de
 * hoy calculada por el motor a partir del historial (progresión, descarga, vuelta tras pausa).
 * Solo lectura.
 */
@Injectable()
export class SessionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly catalog: CatalogService,
    private readonly engineInput: EngineInputService,
    private readonly clock: Clock,
  ) {}

  async today(userId: string): Promise<TodaySessionResponse> {
    const ctx = await this.engineInput.load(userId);
    if (!ctx) throw new ApiError(HttpStatus.CONFLICT, 'PROFILE_REQUIRED', 'Complete your training profile first');
    const tz = ctx.profile.timezone;

    const version = await this.prisma.planVersion.findFirst({
      where: { userId, plan: { status: 'active' } },
      orderBy: { version: 'desc' },
      select: { id: true, plan: { select: { createdAt: true } }, sessions: { select: { id: true, order: true }, orderBy: { order: 'asc' } } },
    });
    if (!version || version.sessions.length === 0) {
      throw new ApiError(HttpStatus.NOT_FOUND, 'PLAN_REQUIRED', 'No training plan yet');
    }

    const workout = await this.prisma.workoutSession.findFirst({
      where: { userId, status: 'in_progress' },
      include: { setLogs: { where: { deletedAt: null }, orderBy: { setIndex: 'asc' } }, substitutions: true },
    });

    let planSessionId: string;
    if (workout) {
      planSessionId = workout.planSessionId;
    } else {
      const done = await this.prisma.workoutSession.findMany({
        where: { userId, status: 'completed', planSession: { planVersionId: version.id } },
        orderBy: { completedAt: 'asc' },
        select: { planSession: { select: { order: true } } },
      });
      const nextOrder = nextPendingSession(
        version.sessions.length,
        done.map((d) => d.planSession.order),
      );
      planSessionId = (version.sessions.find((s) => s.order === nextOrder) ?? version.sessions[0]).id;
    }

    const session = await this.prisma.planSession.findFirstOrThrow({
      where: { id: planSessionId, userId },
      include: {
        exercises: {
          orderBy: { order: 'asc' },
          include: { exercise: { select: { id: true, slug: true, nameEs: true, cuesEs: true, movementPattern: true, loadType: true } } },
        },
      },
    });

    const catalog = await this.catalog.engineCatalog();
    const swaps = new Map(workout?.substitutions.map((s) => [s.planExerciseId, s.exerciseId]) ?? []);
    const performedIds = session.exercises.map((e) => swaps.get(e.id) ?? e.exerciseId);
    const refs = await this.catalog.refs(performedIds);
    const history = await this.engineInput.history(userId, tz, {
      exerciseIds: performedIds,
      ...(workout ? { excludeWorkoutId: workout.id } : {}),
    });
    const today = localDate(this.clock.now(), tz);
    const weeks = weeksSinceDeload(localDate(version.plan.createdAt, tz), today);

    const exercises: TodayExercise[] = session.exercises.map((slot) => {
      const performedId = swaps.get(slot.id) ?? slot.exerciseId;
      const original: ExerciseRef = { id: slot.exercise.id, slug: slot.exercise.slug, nameEs: slot.exercise.nameEs };
      const performed = refs.get(performedId) ?? original;
      const entry = catalog.byId.get(performedId);
      const movementPattern = entry?.movementPattern ?? slot.exercise.movementPattern;
      const loadType = entry?.loadType ?? slot.exercise.loadType;
      const own = history.entries.filter((h) => h.exerciseId === performed.slug);
      const substituted = performedId !== slot.exerciseId;
      const initial = substituted || slot.initialLoadKg === null ? null : Number(slot.initialLoadKg);
      const result = nextPrescription({
        prescription: {
          exerciseId: performed.slug,
          movementPattern,
          loadType,
          sets: slot.sets,
          repMin: slot.repMin,
          repMax: slot.repMax,
          targetRir: slot.targetRir,
          loadKg: currentLoad(loadType, initial, own),
        },
        history: own,
        today,
        weeksSinceDeload: weeks,
      });
      if (!result.ok) {
        throw new ApiError(HttpStatus.INTERNAL_SERVER_ERROR, 'INTERNAL', 'Could not compute the prescription');
      }
      const next = result.next;
      return {
        planExerciseId: slot.id,
        order: slot.order,
        exercise: performed,
        substitutedFrom: substituted ? original : null,
        cuesEs: entry?.cuesEs ?? slot.exercise.cuesEs,
        movementPattern,
        loadType,
        role: slot.role,
        restSeconds: slot.restSeconds,
        prescription: {
          action: next.action,
          sets: next.sets,
          repMin: next.repMin,
          repMax: next.repMax,
          targetRir: next.targetRir,
          loadKg: next.loadKg,
          isDeload: next.isDeload,
          rationale: next.rationale,
        },
        warmupSets: warmupsFor(slot.warmupSets, loadType === 'weighted' ? next.loadKg : null),
        loggedSets: (workout?.setLogs ?? []).filter((s) => s.planExerciseId === slot.id).map(toSetResponse),
      };
    });

    return {
      planVersionId: version.id,
      planSessionId: session.id,
      order: session.order,
      dayIndex: session.dayIndex,
      kind: session.kind,
      name: session.name,
      targetMinutes: session.targetMinutes,
      estimatedMinutes: session.estimatedMinutes,
      generalWarmupMinutes: PROGRAMMING.time.generalWarmupMin.value,
      rationale: Array.isArray(session.rationale) ? (session.rationale as string[]) : [],
      today,
      workout: workout
        ? { id: workout.id, clientId: workout.clientId, status: workout.status, startedAt: workout.startedAt.toISOString() }
        : null,
      exercises,
    };
  }
}
