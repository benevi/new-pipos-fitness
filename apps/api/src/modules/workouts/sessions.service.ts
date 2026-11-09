import { HttpStatus, Injectable } from '@nestjs/common';
import {
  activeBreak,
  adjustedPrescription,
  adjustSession,
  barKgFor,
  daysBetween,
  isScheduledDay,
  loadImplement,
  loadStepKg,
  nextPendingSession,
  nextPrescription,
  plateBreakdown,
  PROGRAMMING,
} from '@pipos/engine-rules';
import type { engineV2, ExerciseRef, TodayExercise, TodaySessionQuery, TodaySessionResponse } from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { Clock } from '../../common/clock';
import { addDays, dateColumn, fromDateColumn, localDate } from '../../common/time';
import { PrismaService } from '../../prisma/prisma.service';
import { CatalogService } from '../catalog/catalog.service';
import { EngineInputService, HISTORY_DAYS } from '../plans/engine-input.service';
import { warmupsFor } from '../plans/plan-mapper';
import { NotesService } from './notes.service';
import { toSetResponse } from './workout-mapper';

/**
 * Semanas dentro del ciclo de descarga (la descarga programada cae cada `deloadEveryWeeks`).
 * `planStart` es el inicio del PLAN (TrainingPlan.createdAt), no de la versión: editar el perfil
 * o regenerar crea versiones nuevas del mismo plan y no debe reiniciar el ciclo.
 *
 * Issue #15: si hubo una descarga real (`lastDeloadOn`, programada o reactiva), el ciclo se ancla
 * a ella: durante sus `deloadDurationDays` sigue la semana de descarga (devuelve
 * `deloadEveryWeeks`) y, después, se cuentan las semanas desde que terminó. Así una descarga
 * reactiva no va seguida de una programada poco después.
 */
export function weeksSinceDeload(planStart: string, today: string, lastDeloadOn: string | null = null): number {
  const every = PROGRAMMING.progression.deloadEveryWeeks.value;
  if (lastDeloadOn !== null && lastDeloadOn >= planStart && lastDeloadOn <= today) {
    const duration = PROGRAMMING.progression.deloadDurationDays.value;
    const days = daysBetween(lastDeloadOn, today);
    if (days < duration) return every;
    return Math.floor((days - duration) / 7) % (every + 1);
  }
  const weeks = Math.max(0, Math.floor(daysBetween(planStart, today) / 7));
  return weeks % (every + 1);
}

/**
 * ¿Fue una sesión de descarga? Sí si al menos la mitad de sus ejercicios tenían prescripción de
 * descarga (issue #15): la programada descarga todos; la reactiva de un solo ejercicio estancado
 * no cuenta como semana de descarga del plan.
 */
export function isDeloadSession(exercises: readonly { prescription: { isDeload: boolean } }[]): boolean {
  if (exercises.length === 0) return false;
  const deloads = exercises.filter((e) => e.prescription.isDeload).length;
  return deloads * 2 >= exercises.length;
}

/** ¿Se registra `today` como nueva última descarga? Solo si no estamos ya dentro de la anterior. */
export function startsNewDeload(lastDeloadOn: string | null, today: string): boolean {
  return lastDeloadOn === null || daysBetween(lastDeloadOn, today) >= PROGRAMMING.progression.deloadDurationDays.value;
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

/** Desglose de discos por lado (solo barras con peso conocido; idea 1, §16.16). */
export function platesFor(implement: engineV2.LoadImplement | null, loadKg: number | null) {
  const bar = barKgFor(implement);
  if (bar === null || loadKg === null) return null;
  return plateBreakdown(loadKg, bar);
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
    private readonly notes: NotesService,
  ) {}

  async today(userId: string, query: TodaySessionQuery = {}): Promise<TodaySessionResponse> {
    const ctx = await this.engineInput.load(userId);
    if (!ctx) throw new ApiError(HttpStatus.CONFLICT, 'PROFILE_REQUIRED', 'Complete your training profile first');
    const tz = ctx.profile.timezone;

    const version = await this.prisma.planVersion.findFirst({
      where: { userId, plan: { status: 'active' } },
      orderBy: { version: 'desc' },
      select: { id: true, plan: { select: { createdAt: true, lastDeloadOn: true } }, sessions: { select: { id: true, order: true, dayIndex: true }, orderBy: { order: 'asc' } } },
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
          include: {
            exercise: { select: { id: true, slug: true, nameEs: true, cuesEs: true, movementPattern: true, loadType: true, equipment: true } },
            override: { select: { exerciseId: true } },
          },
        },
      },
    });

    const catalog = await this.catalog.engineCatalog();
    const swaps = new Map(workout?.substitutions.map((s) => [s.planExerciseId, s.exerciseId]) ?? []);
    // Ejercicio de hoy: cambio puntual del entrenamiento > cambio fijado del plan > el del plan.
    const performedOf = (e: (typeof session.exercises)[number]) => swaps.get(e.id) ?? e.override?.exerciseId ?? e.exerciseId;
    const performedIds = session.exercises.map(performedOf);
    const [refs, notes] = await Promise.all([this.catalog.refs(performedIds), this.notes.byExercise(userId, performedIds)]);
    const history = await this.engineInput.history(userId, tz, {
      exerciseIds: performedIds,
      ...(workout ? { excludeWorkoutId: workout.id } : {}),
    });
    const today = localDate(this.clock.now(), tz);
    const lastDeloadOn = version.plan.lastDeloadOn ? fromDateColumn(version.plan.lastDeloadOn) : null;
    const weeks = weeksSinceDeload(localDate(version.plan.createdAt, tz), today, lastDeloadOn);
    // Pausas planificadas recientes y vigentes (idea 6): no cuentan como ausencia (§16.18).
    const breakRows = await this.prisma.trainingBreak.findMany({
      where: { userId, endsOn: { gte: dateColumn(addDays(today, -HISTORY_DAYS)) } },
      orderBy: { startsOn: 'asc' },
      select: { id: true, startsOn: true, endsOn: true },
    });
    const breaks = breakRows.map((b) => ({ id: b.id, startsOn: fromDateColumn(b.startsOn), endsOn: fromDateColumn(b.endsOn) }));
    const plannedBreaks = breaks.map(({ startsOn, endsOn }) => ({ startsOn, endsOn }));

    const computed = session.exercises.map((slot) => {
      const performedId = performedOf(slot);
      const original: ExerciseRef = { id: slot.exercise.id, slug: slot.exercise.slug, nameEs: slot.exercise.nameEs };
      const performed = refs.get(performedId) ?? original;
      const entry = catalog.byId.get(performedId);
      const movementPattern = entry?.movementPattern ?? slot.exercise.movementPattern;
      const loadType = entry?.loadType ?? slot.exercise.loadType;
      const implement = entry ? entry.loadImplement : loadImplement(slot.exercise);
      const own = history.entries.filter((h) => h.exerciseId === performed.slug);
      const substituted = performedId !== slot.exerciseId;
      const initial = substituted || slot.initialLoadKg === null ? null : Number(slot.initialLoadKg);
      const current = currentLoad(loadType, initial, own);
      const result = nextPrescription({
        prescription: {
          exerciseId: performed.slug,
          movementPattern,
          loadType,
          sets: slot.sets,
          repMin: slot.repMin,
          repMax: slot.repMax,
          targetRir: slot.targetRir,
          loadKg: current,
          implement,
        },
        history: own,
        today,
        weeksSinceDeload: weeks,
        ...(plannedBreaks.length > 0 ? { breaks: plannedBreaks } : {}),
      });
      if (!result.ok) {
        throw new ApiError(HttpStatus.INTERNAL_SERVER_ERROR, 'INTERNAL', 'Could not compute the prescription');
      }
      return { slot, performedId, original, performed, entry, movementPattern, loadType, implement, substituted, current, next: result.next };
    });

    // Ajuste de hoy (idea 4): parámetros de la petición o, si no hay, el guardado al empezar.
    const requested = query.minutes !== undefined || query.mode !== undefined;
    const adjustment = requested
      ? { source: 'query' as const, availableMinutes: query.minutes ?? null, reducedVolume: query.mode === 'reduced' }
      : workout && (workout.adjustedMinutes !== null || workout.reducedVolume)
        ? { source: 'workout' as const, availableMinutes: workout.adjustedMinutes, reducedVolume: workout.reducedVolume }
        : null;
    const active = adjustment && (adjustment.availableMinutes !== null || adjustment.reducedVolume) ? adjustment : null;
    const adjusted = active
      ? adjustSession(
          computed.map((c) => ({
            id: c.slot.id,
            nameEs: c.performed.nameEs,
            role: c.slot.role,
            order: c.slot.order,
            sets: c.next.sets,
            repMin: c.next.repMin,
            repMax: c.next.repMax,
            targetRir: c.next.targetRir,
            restSeconds: c.slot.restSeconds,
            isUnilateral: c.entry?.isUnilateral ?? false,
            warmupSets: Array.isArray(c.slot.warmupSets) ? c.slot.warmupSets.length : 0,
          })),
          { availableMinutes: active.availableMinutes, reducedVolume: active.reducedVolume },
        )
      : null;
    const keptById = new Map(adjusted?.kept.map((k) => [k.id, k]) ?? []);

    const exercises: TodayExercise[] = computed.flatMap((c) => {
      const { slot, performedId, loadType, implement } = c;
      const kept = keptById.get(slot.id);
      if (adjusted && !kept) return [];
      const next = kept && active ? adjustedPrescription(c.next, kept, active.reducedVolume, c.current) : c.next;
      return [
        {
          planExerciseId: slot.id,
          order: slot.order,
          exercise: c.performed,
          substitutedFrom: c.substituted ? c.original : null,
          cuesEs: c.entry?.cuesEs ?? slot.exercise.cuesEs,
          movementPattern: c.movementPattern,
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
          warmupSets: warmupsFor(slot.warmupSets, loadType === 'weighted' ? next.loadKg : null, implement),
          loggedSets: (workout?.setLogs ?? []).filter((s) => s.planExerciseId === slot.id).map(toSetResponse),
          loadImplement: implement,
          loadStepKg: implement ? loadStepKg(implement) : null,
          plates: platesFor(implement, loadType === 'weighted' ? next.loadKg : null),
          pinned: !swaps.has(slot.id) && slot.override !== null && performedId !== slot.exerciseId,
          note: notes.get(performedId) ?? null,
        },
      ];
    });
    const byId = new Map(computed.map((c) => [c.slot.id, c]));

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
      scheduledToday: isScheduledDay(
        today,
        ctx.profile.trainingWeekdays,
        version.sessions.map((s) => s.dayIndex + 1),
        plannedBreaks,
      ),
      activeBreak: activeBreak(today, breaks),
      adjustment:
        active && adjusted
          ? {
              source: active.source,
              availableMinutes: active.availableMinutes,
              reducedVolume: active.reducedVolume,
              estimatedMinutes: adjusted.estimatedMinutes,
              fits: adjusted.fits,
              dropped: adjusted.dropped.map((id) => ({ planExerciseId: id, exercise: byId.get(id)!.performed })),
              rationale: adjusted.rationale,
            }
          : null,
    };
  }
}
