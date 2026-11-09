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
import { toSetResponse, toWorkoutResponse, workoutInclude } from './workout-mapper';

export interface Upserted<T> {
  value: T;
  /** false = el `clientId` ya existía (reenvío idempotente): 200 en vez de 201. */
  created: boolean;
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
  ) {}

  async start(userId: string, input: StartWorkoutRequest): Promise<Upserted<WorkoutResponse>> {
    const existing = await this.prisma.workoutSession.findUnique({
      where: { userId_clientId: { userId, clientId: input.clientId } },
      include: workoutInclude,
    });
    if (existing) return this.replayStart(existing, input);

    const planSession = await this.prisma.planSession.findFirst({
      where: { id: input.planSessionId, userId },
      select: { id: true },
    });
    if (!planSession) throw ApiError.notFound('Plan session not found');

    const inProgress = await this.prisma.workoutSession.findFirst({
      where: { userId, status: 'in_progress' },
      select: { id: true },
    });
    if (inProgress) throw this.inProgressError(inProgress.id);

    try {
      // La FK compuesta (planSessionId, userId) impide en BD apuntar a la sesión de otro usuario.
      const created = await this.prisma.workoutSession.create({
        data: { userId, clientId: input.clientId, planSessionId: input.planSessionId, startedAt: new Date(input.startedAt) },
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
    });
    return this.get(userId, workoutId);
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
      select: { id: true, exercise: { select: { id: true, slug: true, nameEs: true } } },
    });
    if (!slot) throw ApiError.notFound('Plan exercise not found in this workout');

    if (exerciseId === slot.exercise.id) {
      // Volver al ejercicio original deshace el cambio.
      await this.prisma.workoutSubstitution.deleteMany({ where: { workoutSessionId: workoutId, planExerciseId } });
      return { workoutId, planExerciseId, exercise: slot.exercise, substitutedFrom: slot.exercise };
    }
    const allowed = await this.substitutesFor(userId, slot.exercise.id, SUBSTITUTE_VALIDATION_LIMIT);
    const target = allowed.substitutes.find((s) => s.exerciseId === exerciseId);
    if (!target) {
      throw ApiError.validation(
        [{ path: 'body.exerciseId', message: 'Not a valid substitute for your profile' }],
        'Exercise is not a valid substitute',
      );
    }
    await this.prisma.workoutSubstitution.upsert({
      where: { workoutSessionId_planExerciseId: { workoutSessionId: workoutId, planExerciseId } },
      create: { userId, workoutSessionId: workoutId, planExerciseId, exerciseId },
      update: { exerciseId },
    });
    return {
      workoutId,
      planExerciseId,
      exercise: { id: target.exerciseId, slug: target.slug, nameEs: target.nameEs },
      substitutedFrom: slot.exercise,
    };
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
   * La serie de un hueco del plan solo puede ser del ejercicio del hueco o del de su sustitución
   * registrada en este entrenamiento (CUJ-4). Se admite el original aunque haya sustitución:
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
      select: { exerciseId: true, substitutions: { where: { workoutSessionId: workoutId }, select: { exerciseId: true } } },
    });
    if (!slot) {
      throw ApiError.validation([{ path: 'body.planExerciseId', message: 'Plan exercise does not belong to this workout' }]);
    }
    const allowed = new Set([slot.exerciseId, ...slot.substitutions.map((s) => s.exerciseId)]);
    if (!allowed.has(exerciseId)) {
      throw ApiError.validation([
        { path: 'body.exerciseId', message: 'Exercise is neither the planned one nor its recorded substitution' },
      ]);
    }
  }
}
