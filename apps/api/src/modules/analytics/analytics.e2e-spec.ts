import request from 'supertest';
import {
  bearer,
  createExercise,
  createPlanSession,
  createTestApp,
  registerUser,
  truncateAll,
  type RegisteredUser,
  type TestContext,
} from '../../test/e2e/helpers';
import type { PrismaService } from '../../prisma/prisma.service';

/** Inserta un entrenamiento completado hace 3 días con las series indicadas (true = completada). */
async function createCompletedWorkout(
  prisma: PrismaService,
  userId: string,
  exerciseId: string,
  setsCompleted: boolean[],
  plan?: { planSessionId: string; planVersionId: string },
) {
  const startedAt = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000);
  return prisma.workoutSession.create({
    data: {
      userId,
      planSessionId: plan?.planSessionId ?? null,
      planVersionId: plan?.planVersionId ?? null,
      startedAt,
      completedAt: new Date(startedAt.getTime() + 45 * 60 * 1000),
      durationMinutes: 45,
      exercises: {
        create: [
          {
            exerciseId,
            order: 0,
            sets: {
              create: setsCompleted.map((completed, setIndex) => ({
                setIndex,
                weightKg: 80,
                reps: 10 - setIndex,
                rir: 2,
                completed,
              })),
            },
          },
        ],
      },
    },
  });
}

describe('Analytics (e2e, Postgres real)', () => {
  let ctx: TestContext;
  let user: RegisteredUser;
  let exerciseId: string;
  const server = () => ctx.app.getHttpServer();
  const progress = () =>
    request(server()).get('/analytics/progress').set(bearer(user.accessToken)).expect(200);

  beforeAll(async () => {
    ctx = await createTestApp();
  });

  beforeEach(async () => {
    await truncateAll(ctx.prisma);
    user = await registerUser(ctx.app, 'analytics@example.com');
    exerciseId = (await createExercise(ctx.prisma, { slug: 'bench-press' })).id;
  });

  afterAll(async () => {
    await ctx.app.close();
  });

  describe('GET /analytics/progress', () => {
    it('200 con la forma esperada', async () => {
      const res = await progress();
      expect(res.body).toEqual({ exercises: [], adherenceScore: null, fatigueDetected: false });
    });

    it('401 sin token', async () => {
      await request(server()).get('/analytics/progress').expect(401);
    });

    it('adherencia null si no hay entrenamientos en la ventana', async () => {
      expect((await progress()).body.adherenceScore).toBeNull();
    });

    it('adherencia: un entrenamiento enlazado a una TrainingSession (planificado a nivel de sesión)', async () => {
      const plan = await createPlanSession(ctx.prisma, user.id, exerciseId, 3);
      await createCompletedWorkout(ctx.prisma, user.id, exerciseId, [true, true], plan);
      const res = await progress();
      expect(res.body.adherenceScore).toBeCloseTo(2 / 3);
      expect(res.body.exercises).toEqual([
        expect.objectContaining({ exerciseId, estimated1RM: expect.any(Number) }),
      ]);
    });

    it('adherencia: varios entrenamientos con distintas TrainingSessions (sin sobrecontar)', async () => {
      const exercise2 = (await createExercise(ctx.prisma, { slug: 'row', movementPattern: 'pull' })).id;
      const plan1 = await createPlanSession(ctx.prisma, user.id, exerciseId, 3);
      const plan2 = await createPlanSession(ctx.prisma, user.id, exercise2, 4);
      await createCompletedWorkout(ctx.prisma, user.id, exerciseId, [true, true], plan1);
      await createCompletedWorkout(ctx.prisma, user.id, exercise2, [true, true, true], plan2);
      expect((await progress()).body.adherenceScore).toBeCloseTo(5 / 7);
    });

    it('adherencia: un entrenamiento sin planSessionId se ignora', async () => {
      await createCompletedWorkout(ctx.prisma, user.id, exerciseId, [true]);
      expect((await progress()).body.adherenceScore).toBeNull();
    });

    it('adherencia: sólo cuentan las series completadas', async () => {
      const plan = await createPlanSession(ctx.prisma, user.id, exerciseId, 3);
      await createCompletedWorkout(ctx.prisma, user.id, exerciseId, [true, false], plan);
      expect((await progress()).body.adherenceScore).toBeCloseTo(1 / 3);
    });

    it('adherencia: mezcla de series completadas e incompletas en [0,1]', async () => {
      const plan = await createPlanSession(ctx.prisma, user.id, exerciseId, 3);
      await createCompletedWorkout(ctx.prisma, user.id, exerciseId, [true, true, false], plan);
      const score = (await progress()).body.adherenceScore;
      expect(score).toBeCloseTo(2 / 3);
      expect(score).toBeGreaterThanOrEqual(0);
      expect(score).toBeLessThanOrEqual(1);
    });

    it('ownership: una planSession de otro usuario enlazada (dato heredado) no computa', async () => {
      const other = await registerUser(ctx.app, 'other@example.com');
      const foreignPlan = await createPlanSession(ctx.prisma, other.id, exerciseId, 3);
      await createCompletedWorkout(ctx.prisma, user.id, exerciseId, [true, true], foreignPlan);
      expect((await progress()).body.adherenceScore).toBeNull();
    });

    it('no mezcla datos de otros usuarios', async () => {
      const other = await registerUser(ctx.app, 'other@example.com');
      await createCompletedWorkout(ctx.prisma, other.id, exerciseId, [true, true]);
      expect((await progress()).body.exercises).toEqual([]);
    });
  });

  describe('GET /analytics/volume', () => {
    it('200 con volumen por ejercicio y por músculo', async () => {
      await createCompletedWorkout(ctx.prisma, user.id, exerciseId, [true, true]);
      const res = await request(server()).get('/analytics/volume').set(bearer(user.accessToken)).expect(200);
      expect(res.body.byExercise).toEqual([{ exerciseId, volume: expect.any(Number) }]);
      expect(res.body.byMuscle).toEqual([{ muscleId: 'muscle-chest', volume: expect.any(Number) }]);
    });

    it('200 vacío sin entrenamientos', async () => {
      const res = await request(server()).get('/analytics/volume').set(bearer(user.accessToken)).expect(200);
      expect(res.body.byExercise).toEqual([]);
      expect(res.body.byMuscle).toEqual([]);
    });
  });
});
