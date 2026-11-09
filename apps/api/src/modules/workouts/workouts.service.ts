import { HttpStatus, Injectable } from '@nestjs/common';
import { substitutes as engineSubstitutes } from '@pipos/engine-rules';
import type {
  FinishWorkoutRequest,
  PatchSetRequest,
  SetLogResponse,
  StartWorkoutRequest,
  SubstitutesResponse,
  SubstitutionResponse,
  UpsertSet,
  WorkoutResponse,
} from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { Clock } from '../../common/clock';
import { isUniqueViolation, PrismaService, type TransactionClient } from '../../prisma/prisma.service';
import { AnalyticsService } from '../analytics/analytics.service';
import { CatalogService } from '../catalog/catalog.service';
import { EngineInputService } from '../plans/engine-input.service';
import { dateColumn, fromDateColumn, localDate } from '../../common/time';
import { log } from '../../logging/logging';
import { isDeloadSession, SessionsService, startsNewDeload } from './sessions.service';
import { toSetResponse, toWorkoutResponse, workoutInclude } from './workout-mapper';

export interface Upserted<T> {
  value: T;
  /** false = el `clientId` ya existía (reenvío idempotente): 200 en vez de 201. */
  created: boolean;
}

/**
 * Un entrenamiento en curso sin actividad (inicio o última serie) desde hace más de estas horas
 * se abandona automáticamente al empezar otro (issue #13): uno olvidado no bloquea los siguientes
 * con 409 WORKOUT_IN_PROGRESS. 12 h: ninguna sesión real dura tanto y deja margen a quien empieza
 * por la mañana y cierra por la noche. Los abandonados no cuentan en la analítica ni la adherencia.
 */
export const STALE_WORKOUT_HOURS = 12;
const HOUR_MS = 60 * 60 * 1000;

/** ¿Lleva el entrenamiento en curso más de STALE_WORKOUT_HOURS sin actividad? */
export function isStaleWorkout(lastActivity: Date, now: Date): boolean {
  return now.getTime() - lastActivity.getTime() > STALE_WORKOUT_HOURS * HOUR_MS;
}

/** Cuántas alternativas pide la validación de un cambio (las 3 visibles + margen). */
const SUBSTITUTE_VALIDATION_LIMIT = 50;

/**
 * Registro de entrenamientos offline-first (ADR-0007, CUJ-2) y sustituciones (CUJ-4).
 * Toda escritura va en una transacción con bloqueo por usuario y recalcula la analítica
 * en esa misma transacción (ADR-0008).
 */
@Injectable()
export class WorkoutsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly analytics: AnalyticsService,
    private readonly catalog: CatalogService,
    private readonly engineInput: EngineInputService,
    private readonly clock: Clock,
    private readonly sessions: SessionsService,
  ) {}

  async start(userId: string, input: StartWorkoutRequest): Promise<Upserted<WorkoutResponse>> {
    const existing = await this.prisma.workoutSession.findUnique({
      where: { userId_clientId: { userId, clientId: input.clientId } },
      include: workoutInclude,
    });
    if (existing) return this.replayStart(existing, input);

    const planSession = await this.prisma.planSession.findFirst({
      where: { id: input.planSessionId, userId },
      select: { id: true, planVersionId: true },
    });
    if (!planSession) throw ApiError.notFound('Plan session not found');
    // Un entrenamiento NUEVO solo sobre la versión vigente: el de una versión antigua no avanzaría
    // el microciclo vigente (issue #10). Los ya empezados (reenvío por clientId, arriba) y sus
    // series se siguen aceptando: la cola offline puede entregarlos tras un cambio de plan.
    if (planSession.planVersionId !== (await this.currentVersionId(userId))) {
      throw new ApiError(
        HttpStatus.CONFLICT,
        'PLAN_SESSION_OUTDATED',
        'This plan session belongs to an older plan version; refresh GET /sessions/today',
      );
    }

    const inProgress = await this.prisma.workoutSession.findFirst({
      where: { userId, status: 'in_progress' },
      select: {
        id: true,
        userId: true,
        startedAt: true,
        setLogs: { orderBy: { completedAt: 'desc' }, take: 1, select: { completedAt: true } },
      },
    });
    if (inProgress) {
      const lastSet = inProgress.setLogs[0]?.completedAt;
      const lastActivity = lastSet && lastSet > inProgress.startedAt ? lastSet : inProgress.startedAt;
      if (!isStaleWorkout(lastActivity, this.clock.now())) throw this.inProgressError(inProgress.id);
      await this.prisma.$transaction(async (tx) => {
        await this.analytics.lockUser(tx, userId);
        await this.markAbandoned(tx, inProgress);
      });
    }

    try {
      // La FK compuesta (planSessionId, userId) impide en BD apuntar a la sesión de otro usuario.
      const created = await this.prisma.workoutSession.create({
        data: {
          userId,
          clientId: input.clientId,
          planSessionId: input.planSessionId,
          startedAt: new Date(input.startedAt),
          adjustedMinutes: input.adjustment?.availableMinutes ?? null,
          reducedVolume: input.adjustment?.reducedVolume ?? false,
        },
        include: workoutInclude,
      });
      return { value: toWorkoutResponse(created), created: true };
    } catch (error) {
      if (!isUniqueViolation(error)) throw error;
      const raced = await this.prisma.workoutSession.findUnique({
        where: { userId_clientId: { userId, clientId: input.clientId } },
        include: workoutInclude,
      });
      if (raced) return this.replayStart(raced, input);
      const other = await this.prisma.workoutSession.findFirst({ where: { userId, status: 'in_progress' } });
      throw this.inProgressError(other?.id);
    }
  }

  async get(userId: string, id: string): Promise<WorkoutResponse> {
    const row = await this.prisma.workoutSession.findFirst({ where: { id, userId }, include: workoutInclude });
    if (!row) throw ApiError.notFound('Workout not found');
    return toWorkoutResponse(row);
  }

  /** POST idempotente por (userId, clientId): reenviar devuelve la fila existente, nunca duplica. */
  async upsertSet(userId: string, workoutId: string, input: UpsertSet): Promise<Upserted<SetLogResponse>> {
    return this.prisma.$transaction(async (tx) => {
      await this.analytics.lockUser(tx, userId);
      const workout = await this.ownedWorkout(tx, userId, workoutId);
      const existing = await tx.setLog.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (existing) {
        if (existing.workoutSessionId !== workoutId) {
          throw new ApiError(HttpStatus.CONFLICT, 'CLIENT_ID_CONFLICT', 'clientId already used by another workout');
        }
        return { value: toSetResponse(existing), created: false };
      }
      this.assertInProgress(workout.status);
      await this.assertExerciseUsable(tx, workout.id, workout.planSessionId, input.planExerciseId, input.exerciseId);

      const inserted = await tx.setLog.createMany({
        data: [
          {
            userId,
            clientId: input.clientId,
            workoutSessionId: workoutId,
            planExerciseId: input.planExerciseId,
            exerciseId: input.exerciseId,
            setIndex: input.setIndex,
            reps: input.reps,
            loadKg: input.loadKg,
            rir: input.rir,
            isWarmup: input.isWarmup,
            completedAt: new Date(input.completedAt),
            clientUpdatedAt: new Date(input.clientUpdatedAt ?? input.completedAt),
          },
        ],
        skipDuplicates: true, // ON CONFLICT DO NOTHING: segunda línea de defensa ante carreras
      });
      const row = await tx.setLog.findUniqueOrThrow({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (inserted.count === 1) await this.analytics.onSetChanged(tx, workout, input.exerciseId);
      return { value: toSetResponse(row), created: inserted.count === 1 };
    });
  }

  /** Edición con «última escritura gana» por `clientUpdatedAt` (ADR-0007). */
  async patchSet(userId: string, workoutId: string, clientId: string, patch: PatchSetRequest): Promise<SetLogResponse> {
    return this.prisma.$transaction(async (tx) => {
      await this.analytics.lockUser(tx, userId);
      const workout = await this.ownedWorkout(tx, userId, workoutId);
      const set = await this.ownedSet(tx, userId, workoutId, clientId);
      const incoming = new Date(patch.clientUpdatedAt);
      if (set.deletedAt || incoming <= set.clientUpdatedAt) return toSetResponse(set);
      const updated = await tx.setLog.update({
        where: { id: set.id },
        data: {
          ...(patch.reps !== undefined ? { reps: patch.reps } : {}),
          ...(patch.loadKg !== undefined ? { loadKg: patch.loadKg } : {}),
          ...(patch.rir !== undefined ? { rir: patch.rir } : {}),
          ...(patch.isWarmup !== undefined ? { isWarmup: patch.isWarmup } : {}),
          clientUpdatedAt: incoming,
        },
      });
      await this.analytics.onSetChanged(tx, workout, set.exerciseId);
      return toSetResponse(updated);
    });
  }

  /** Borrado lógico: la cola offline puede reenviar después una serie ya borrada. */
  async deleteSet(userId: string, workoutId: string, clientId: string): Promise<SetLogResponse> {
    return this.prisma.$transaction(async (tx) => {
      await this.analytics.lockUser(tx, userId);
      const workout = await this.ownedWorkout(tx, userId, workoutId);
      const set = await this.ownedSet(tx, userId, workoutId, clientId);
      if (set.deletedAt) return toSetResponse(set);
      const updated = await tx.setLog.update({ where: { id: set.id }, data: { deletedAt: this.clock.now() } });
      await this.analytics.onSetChanged(tx, workout, set.exerciseId);
      return toSetResponse(updated);
    });
  }

  async finish(userId: string, workoutId: string, input: FinishWorkoutRequest): Promise<WorkoutResponse> {
    const deload = await this.wasDeload(userId, workoutId);
    await this.prisma.$transaction(async (tx) => {
      await this.analytics.lockUser(tx, userId);
      const workout = await this.ownedWorkout(tx, userId, workoutId);
      this.assertInProgress(workout.status);
      const completedAt = new Date(input.completedAt);
      if (completedAt < workout.startedAt) {
        throw ApiError.validation([{ path: 'body.completedAt', message: 'completedAt is before startedAt' }]);
      }
      await tx.workoutSession.update({ where: { id: workoutId }, data: { status: 'completed', completedAt } });
      await this.analytics.onWorkoutFinished(tx, workout);
      if (deload) await this.recordDeload(tx, userId, workout);
    });
    return this.get(userId, workoutId);
  }

  /**
   * ¿La prescripción de este entrenamiento (el que está en curso) era de descarga? Se calcula con
   * la misma sesión de hoy que ve el usuario. Si no se puede calcular, no se registra nada (el
   * cierre nunca falla por esto).
   */
  private async wasDeload(userId: string, workoutId: string): Promise<boolean> {
    try {
      const today = await this.sessions.today(userId);
      return today.workout?.id === workoutId && isDeloadSession(today.exercises);
    } catch (error) {
      // Un ApiError (sin perfil, sin plan…) es un caso de dominio: simplemente no hay descarga.
      if (!(error instanceof ApiError)) {
        log('warn', 'Could not compute the deload state of a finished workout', { name: (error as Error)?.name });
      }
      return false;
    }
  }

  /** Issue #15: guarda la última descarga real en el plan para anclar el ciclo de descarga. */
  private async recordDeload(
    tx: TransactionClient,
    userId: string,
    workout: { startedAt: Date; planSessionId: string },
  ): Promise<void> {
    const session = await tx.planSession.findFirst({
      where: { id: workout.planSessionId, userId },
      select: { planVersion: { select: { plan: { select: { id: true, lastDeloadOn: true } } } } },
    });
    const plan = session?.planVersion.plan;
    if (!plan) return;
    const profile = await tx.trainingProfile.findUnique({ where: { userId }, select: { timezone: true } });
    const day = localDate(workout.startedAt, profile?.timezone ?? 'UTC');
    const last = plan.lastDeloadOn ? fromDateColumn(plan.lastDeloadOn) : null;
    if (startsNewDeload(last, day)) {
      await tx.trainingPlan.update({ where: { id: plan.id }, data: { lastDeloadOn: dateColumn(day) } });
    }
  }

  /**
   * Abandonar un entrenamiento en curso (issue #13). Idempotente: abandonar uno ya abandonado
   * devuelve el mismo estado; uno terminado → 409 WORKOUT_FINISHED. Sus series se conservan
   * pero dejan de contar en e1RM, volumen y adherencia; no se admiten series nuevas.
   */
  async abandon(userId: string, workoutId: string): Promise<WorkoutResponse> {
    await this.prisma.$transaction(async (tx) => {
      await this.analytics.lockUser(tx, userId);
      const workout = await this.ownedWorkout(tx, userId, workoutId);
      if (workout.status === 'abandoned') return;
      this.assertInProgress(workout.status);
      await this.markAbandoned(tx, workout);
    });
    return this.get(userId, workoutId);
  }

  /** Pasa a `abandoned` si sigue en curso (condición en el UPDATE: no pisa un cierre simultáneo). */
  private async markAbandoned(
    tx: TransactionClient,
    workout: { id: string; userId: string; startedAt: Date },
  ): Promise<void> {
    const updated = await tx.workoutSession.updateMany({
      where: { id: workout.id, userId: workout.userId, status: 'in_progress' },
      data: { status: 'abandoned' },
    });
    if (updated.count === 1) await this.analytics.onWorkoutAbandoned(tx, workout);
  }

  /** CUJ-4: 3 alternativas del motor que respetan patrón, músculos, material y limitaciones. */
  async substitutesFor(userId: string, exerciseId: string, limit = 3): Promise<SubstitutesResponse> {
    const catalog = await this.catalog.engineCatalog();
    const original = catalog.byId.get(exerciseId);
    if (!original) throw ApiError.notFound('Exercise not found');
    const ctx = await this.engineInput.load(userId);
    if (!ctx) throw new ApiError(HttpStatus.CONFLICT, 'PROFILE_REQUIRED', 'Complete your training profile first');
    const result = engineSubstitutes(original.slug, ctx.engineProfile, catalog.exercises, limit);
    if (!result.ok) throw new ApiError(HttpStatus.UNPROCESSABLE_ENTITY, 'UNKNOWN_EXERCISE', result.error.message);
    return {
      exercise: { id: original.id, slug: original.slug, nameEs: original.nameEs },
      substitutes: result.substitutes.flatMap((s) => {
        const entry = catalog.bySlug.get(s.exerciseId);
        return entry ? [{ exerciseId: entry.id, slug: entry.slug, nameEs: entry.nameEs, score: s.score, rationale: s.rationale }] : [];
      }),
    };
  }

  /** Registra el cambio de ejercicio de un hueco del plan en este entrenamiento. */
  async substitute(
    userId: string,
    workoutId: string,
    planExerciseId: string,
    exerciseId: string,
  ): Promise<SubstitutionResponse> {
    const workout = await this.ownedWorkout(this.prisma, userId, workoutId);
    this.assertInProgress(workout.status);
    const slot = await this.prisma.planExercise.findFirst({
      where: { id: planExerciseId, planSessionId: workout.planSessionId },
      select: {
        id: true,
        exercise: { select: { id: true, slug: true, nameEs: true } },
        override: { select: { exercise: { select: { id: true, slug: true, nameEs: true } } } },
      },
    });
    if (!slot) throw ApiError.notFound('Plan exercise not found in this workout');

    // Lo que toca por defecto en este hueco: el cambio fijado del plan (idea 3) o el original.
    const byDefault = slot.override?.exercise ?? slot.exercise;
    if (exerciseId === byDefault.id) {
      // Volver al ejercicio por defecto deshace el cambio puntual.
      await this.prisma.workoutSubstitution.deleteMany({ where: { workoutSessionId: workoutId, planExerciseId } });
      return { workoutId, planExerciseId, exercise: byDefault, substitutedFrom: slot.exercise };
    }
    let target: { id: string; slug: string; nameEs: string };
    if (exerciseId === slot.exercise.id) {
      // Con un cambio fijado, hoy se puede volver al ejercicio original del plan.
      target = slot.exercise;
    } else {
      const allowed = await this.substitutesFor(userId, slot.exercise.id, SUBSTITUTE_VALIDATION_LIMIT);
      const found = allowed.substitutes.find((s) => s.exerciseId === exerciseId);
      if (!found) {
        throw ApiError.validation(
          [{ path: 'body.exerciseId', message: 'Not a valid substitute for your profile' }],
          'Exercise is not a valid substitute',
        );
      }
      target = { id: found.exerciseId, slug: found.slug, nameEs: found.nameEs };
    }
    await this.prisma.workoutSubstitution.upsert({
      where: { workoutSessionId_planExerciseId: { workoutSessionId: workoutId, planExerciseId } },
      create: { userId, workoutSessionId: workoutId, planExerciseId, exerciseId },
      update: { exerciseId },
    });
    return { workoutId, planExerciseId, exercise: target, substitutedFrom: slot.exercise };
  }

  /** Versión vigente = la de mayor número del plan activo (como PlansService.currentVersionId). */
  private async currentVersionId(userId: string): Promise<string | null> {
    const row = await this.prisma.planVersion.findFirst({
      where: { userId, plan: { status: 'active' } },
      orderBy: { version: 'desc' },
      select: { id: true },
    });
    return row?.id ?? null;
  }

  private replayStart(existing: Parameters<typeof toWorkoutResponse>[0], input: StartWorkoutRequest): Upserted<WorkoutResponse> {
    if (existing.planSessionId !== input.planSessionId) {
      throw new ApiError(HttpStatus.CONFLICT, 'CLIENT_ID_CONFLICT', 'clientId already used for another plan session');
    }
    return { value: toWorkoutResponse(existing), created: false };
  }

  private inProgressError(id?: string): ApiError {
    return new ApiError(
      HttpStatus.CONFLICT,
      'WORKOUT_IN_PROGRESS',
      `Another workout is in progress${id ? ` (${id})` : ''}; finish it first`,
    );
  }

  private assertInProgress(status: string): void {
    if (status !== 'in_progress') {
      throw new ApiError(HttpStatus.CONFLICT, 'WORKOUT_FINISHED', 'Workout is already finished');
    }
  }

  /** Propiedad en servicio (404 si no es suyo); en BD la refuerzan las FK compuestas. */
  private async ownedWorkout(db: TransactionClient | PrismaService, userId: string, workoutId: string) {
    const workout = await db.workoutSession.findFirst({
      where: { id: workoutId, userId },
      select: { id: true, userId: true, status: true, startedAt: true, planSessionId: true },
    });
    if (!workout) throw ApiError.notFound('Workout not found');
    return workout;
  }

  private async ownedSet(tx: TransactionClient, userId: string, workoutId: string, clientId: string) {
    const set = await tx.setLog.findUnique({ where: { userId_clientId: { userId, clientId } } });
    if (!set || set.workoutSessionId !== workoutId) throw ApiError.notFound('Set not found');
    return set;
  }

  /**
   * La serie de un hueco del plan solo puede ser del ejercicio del hueco, del de su sustitución
   * registrada en este entrenamiento (CUJ-4) o del cambio fijado del plan (idea 3). Se admite el original aunque haya sustitución:
   * la cola offline puede entregar tarde series hechas antes del cambio.
   */
  private async assertExerciseUsable(
    tx: TransactionClient,
    workoutId: string,
    planSessionId: string,
    planExerciseId: string | null,
    exerciseId: string,
  ): Promise<void> {
    const exercise = await tx.exercise.findUnique({ where: { id: exerciseId }, select: { id: true } });
    if (!exercise) throw ApiError.validation([{ path: 'body.exerciseId', message: 'Unknown exercise' }]);
    if (planExerciseId === null) return;
    const slot = await tx.planExercise.findFirst({
      where: { id: planExerciseId, planSessionId },
      select: {
        exerciseId: true,
        substitutions: { where: { workoutSessionId: workoutId }, select: { exerciseId: true } },
        override: { select: { exerciseId: true } },
      },
    });
    if (!slot) {
      throw ApiError.validation([{ path: 'body.planExerciseId', message: 'Plan exercise does not belong to this workout' }]);
    }
    // También el cambio fijado del plan (idea 3).
    const allowed = new Set([
      slot.exerciseId,
      ...slot.substitutions.map((s) => s.exerciseId),
      ...(slot.override ? [slot.override.exerciseId] : []),
    ]);
    if (!allowed.has(exerciseId)) {
      throw ApiError.validation([
        { path: 'body.exerciseId', message: 'Exercise is neither the planned one nor its recorded substitution' },
      ]);
    }
  }
}
