import request from 'supertest';
import { randomUUID } from 'crypto';
import { Prisma } from '@prisma/client';
import {
  bearer,
  createTestApp,
  registerUser,
  setBody,
  startToday,
  truncateAll,
  userWithPlan,
  type TestContext,
} from './helpers';

describe('Concurrencia, idempotencia y propiedad (e2e, Postgres real)', () => {
  let ctx: TestContext;
  const server = () => ctx.app.getHttpServer();

  beforeAll(async () => {
    ctx = await createTestApp();
  });
  beforeEach(async () => {
    await truncateAll(ctx.prisma);
  });
  afterAll(async () => {
    await ctx.app.close();
  });

  describe('concurrencia', () => {
    it('dos generaciones de plan simultáneas → versiones 1 y 2, sin error', async () => {
      const { user } = await userWithPlan(ctx.app);
      await ctx.prisma.planVersion.deleteMany({ where: { userId: user.id } });
      const [a, b] = await Promise.all([
        request(server()).post('/plans/generate').set(bearer(user.accessToken)),
        request(server()).post('/plans/generate').set(bearer(user.accessToken)),
      ]);
      expect([a.status, b.status]).toEqual([201, 201]);
      expect([a.body.version, b.body.version].sort()).toEqual([1, 2]);
      expect(await ctx.prisma.trainingPlan.count({ where: { userId: user.id } })).toBe(1);
    });

    it('primer plan generado dos veces a la vez (sin plan previo) → un plan activo, versiones 1 y 2', async () => {
      const u = await registerUser(ctx.app);
      await request(server()).put('/me/profile').set(bearer(u.accessToken)).send({
        goal: 'strength', level: 'beginner', daysPerWeek: 2, minutesPerSession: 45, equipment: ['dumbbell', 'bench'], timezone: 'UTC',
      }).expect(200);
      const results = await Promise.all([1, 2].map(() => request(server()).post('/plans/generate').set(bearer(u.accessToken))));
      expect(results.map((r) => r.status)).toEqual([201, 201]);
      expect(results.map((r) => r.body.version).sort()).toEqual([1, 2]);
      expect(await ctx.prisma.trainingPlan.count({ where: { userId: u.id, status: 'active' } })).toBe(1);
    });

    it('la misma serie enviada dos veces a la vez → una sola fila, la misma respuesta', async () => {
      const { user } = await userWithPlan(ctx.app);
      const { today, workout } = await startToday(ctx.app, user.accessToken);
      const body = setBody(today.exercises[0]);
      const results = await Promise.all(
        Array.from({ length: 4 }, () => request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(user.accessToken)).send(body)),
      );
      expect(results.map((r) => r.status).sort()).toEqual([200, 200, 200, 201]);
      expect(new Set(results.map((r) => r.body.id)).size).toBe(1);
      expect(await ctx.prisma.setLog.count({ where: { userId: user.id } })).toBe(1);
      // La analítica se calculó una sola vez y es coherente.
      const week = await ctx.prisma.weeklyAdherence.findFirstOrThrow({ where: { userId: user.id } });
      expect(week.completedSets).toBe(1);
    });

    it('series distintas en paralelo → todas cuentan en el volumen semanal', async () => {
      const { user } = await userWithPlan(ctx.app);
      const { today, workout } = await startToday(ctx.app, user.accessToken);
      const ex = today.exercises[0];
      await Promise.all(
        Array.from({ length: 5 }, (_, i) =>
          request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(user.accessToken)).send(setBody(ex, { setIndex: i })).expect(201),
        ),
      );
      const week = await ctx.prisma.weeklyAdherence.findFirstOrThrow({ where: { userId: user.id } });
      expect(week.completedSets).toBe(5);
    });

    it('empezar el mismo entrenamiento dos veces a la vez (mismo clientId) → uno solo', async () => {
      const { user } = await userWithPlan(ctx.app);
      const today = await request(server()).get('/sessions/today').set(bearer(user.accessToken)).expect(200);
      const body = { clientId: randomUUID(), planSessionId: today.body.planSessionId, startedAt: new Date().toISOString() };
      const results = await Promise.all([1, 2, 3].map(() => request(server()).post('/workouts').set(bearer(user.accessToken)).send(body)));
      expect(results.map((r) => r.status).sort()).toEqual([200, 200, 201]);
      expect(await ctx.prisma.workoutSession.count({ where: { userId: user.id } })).toBe(1);
    });
  });

  describe('registro de series', () => {
    it('PATCH con «última escritura gana» y DELETE lógico idempotente; recalcula la analítica', async () => {
      const { user } = await userWithPlan(ctx.app);
      const { today, workout } = await startToday(ctx.app, user.accessToken);
      const t = Date.now();
      const body = setBody(today.exercises[0], { reps: 8, loadKg: 40, completedAt: new Date(t).toISOString() });
      await request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(user.accessToken)).send(body).expect(201);
      const url = `/workouts/${workout.id}/sets/${body.clientId}`;

      const newer = await request(server()).patch(url).set(bearer(user.accessToken))
        .send({ reps: 6, clientUpdatedAt: new Date(t + 2000).toISOString() }).expect(200);
      expect(newer.body.reps).toBe(6);
      // Una edición más antigua (llega tarde desde otra cola) no pisa la nueva.
      const stale = await request(server()).patch(url).set(bearer(user.accessToken))
        .send({ reps: 12, clientUpdatedAt: new Date(t + 1000).toISOString() }).expect(200);
      expect(stale.body.reps).toBe(6);

      const del = await request(server()).delete(url).set(bearer(user.accessToken)).expect(200);
      expect(del.body.deletedAt).not.toBeNull();
      await request(server()).delete(url).set(bearer(user.accessToken)).expect(200);
      expect(await ctx.prisma.setLog.count({ where: { userId: user.id } })).toBe(1);
      expect(await ctx.prisma.exerciseE1rm.count({ where: { userId: user.id } })).toBe(0);
      const week = await ctx.prisma.weeklyAdherence.findFirstOrThrow({ where: { userId: user.id } });
      expect(week.completedSets).toBe(0);
      // Reenviar la serie borrada no la resucita ni duplica.
      const replay = await request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(user.accessToken)).send(body).expect(200);
      expect(replay.body.deletedAt).not.toBeNull();
    });

    it('finish: 200 la primera vez, 409 WORKOUT_FINISHED después; no admite series nuevas', async () => {
      const { user } = await userWithPlan(ctx.app);
      const { today, workout } = await startToday(ctx.app, user.accessToken);
      const completedAt = new Date(Date.now() + 1000).toISOString();
      await request(server()).post(`/workouts/${workout.id}/finish`).set(bearer(user.accessToken)).send({ completedAt }).expect(200);
      const again = await request(server()).post(`/workouts/${workout.id}/finish`).set(bearer(user.accessToken)).send({ completedAt }).expect(409);
      expect(again.body.code).toBe('WORKOUT_FINISHED');
      const late = await request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(user.accessToken)).send(setBody(today.exercises[0])).expect(409);
      expect(late.body.code).toBe('WORKOUT_FINISHED');
    });

    it('un solo entrenamiento en curso; clientId reutilizado en otro entrenamiento → 409', async () => {
      const { user } = await userWithPlan(ctx.app);
      const { today, workout } = await startToday(ctx.app, user.accessToken);
      const other = await request(server()).post('/workouts').set(bearer(user.accessToken))
        .send({ clientId: randomUUID(), planSessionId: today.planSessionId, startedAt: new Date().toISOString() }).expect(409);
      expect(other.body.code).toBe('WORKOUT_IN_PROGRESS');

      const body = setBody(today.exercises[0]);
      await request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(user.accessToken)).send(body).expect(201);
      await request(server()).post(`/workouts/${workout.id}/finish`).set(bearer(user.accessToken)).send({ completedAt: new Date(Date.now() + 1000).toISOString() }).expect(200);
      const next = await startToday(ctx.app, user.accessToken);
      const reused = await request(server()).post(`/workouts/${next.workout.id}/sets`).set(bearer(user.accessToken))
        .send({ ...setBody(next.today.exercises[0]), clientId: body.clientId }).expect(409);
      expect(reused.body.code).toBe('CLIENT_ID_CONFLICT');
    });

    it('validación: planExerciseId de otra sesión, ejercicio inexistente o cuerpo inválido → 400', async () => {
      const { user, plan } = await userWithPlan(ctx.app);
      const { today, workout } = await startToday(ctx.app, user.accessToken);
      const otherSlot = plan.sessions[1].exercises[0];
      const wrongSlot = await request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(user.accessToken))
        .send({ ...setBody(today.exercises[0]), planExerciseId: otherSlot.id }).expect(400);
      expect(wrongSlot.body.issues[0].path).toBe('body.planExerciseId');
      await request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(user.accessToken))
        .send({ ...setBody(today.exercises[0]), exerciseId: randomUUID() }).expect(400);
      const invalid = await request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(user.accessToken))
        .send({ ...setBody(today.exercises[0]), reps: -1, extra: true }).expect(400);
      expect(invalid.body.code).toBe('VALIDATION_FAILED');
      await request(server()).get('/workouts/not-a-uuid').set(bearer(user.accessToken)).expect(400);
    });
  });

  describe('propiedad: cada recurso anidado de otro usuario → 404', () => {
    it('planes, sesiones, entrenamientos, series y sustituciones', async () => {
      const a = await userWithPlan(ctx.app);
      const b = await userWithPlan(ctx.app);
      const { today, workout } = await startToday(ctx.app, a.user.accessToken);
      const slot = today.exercises[0];
      const body = setBody(slot);
      await request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(a.user.accessToken)).send(body).expect(201);
      const tb = bearer(b.user.accessToken);

      await request(server()).get(`/plans/versions/${a.plan.id}`).set(tb).expect(404);
      await request(server()).post('/workouts').set(tb)
        .send({ clientId: randomUUID(), planSessionId: today.planSessionId, startedAt: new Date().toISOString() }).expect(404);
      await request(server()).get(`/workouts/${workout.id}`).set(tb).expect(404);
      await request(server()).post(`/workouts/${workout.id}/sets`).set(tb).send(setBody(slot)).expect(404);
      await request(server()).patch(`/workouts/${workout.id}/sets/${body.clientId}`).set(tb)
        .send({ reps: 1, clientUpdatedAt: new Date(Date.now() + 5000).toISOString() }).expect(404);
      await request(server()).delete(`/workouts/${workout.id}/sets/${body.clientId}`).set(tb).expect(404);
      await request(server()).post(`/workouts/${workout.id}/finish`).set(tb).send({ completedAt: new Date().toISOString() }).expect(404);
      await request(server()).post(`/workouts/${workout.id}/exercises/${slot.planExerciseId}/substitute`).set(tb)
        .send({ exerciseId: slot.exercise.id }).expect(404);

      // B con su propio entrenamiento tampoco puede tocar la serie de A por clientId ni usar huecos de A.
      const bw = await startToday(ctx.app, b.user.accessToken);
      await request(server()).patch(`/workouts/${bw.workout.id}/sets/${body.clientId}`).set(tb)
        .send({ reps: 1, clientUpdatedAt: new Date(Date.now() + 5000).toISOString() }).expect(404);
      await request(server()).post(`/workouts/${bw.workout.id}/exercises/${slot.planExerciseId}/substitute`).set(tb)
        .send({ exerciseId: slot.exercise.id }).expect(404);
      await request(server()).post(`/workouts/${bw.workout.id}/sets`).set(tb)
        .send({ ...setBody(bw.today.exercises[0]), planExerciseId: slot.planExerciseId }).expect(400);
      // El mismo clientId en otro usuario es independiente (ámbito por usuario).
      await request(server()).post(`/workouts/${bw.workout.id}/sets`).set(tb)
        .send({ ...setBody(bw.today.exercises[0]), clientId: body.clientId }).expect(201);

      const set = await ctx.prisma.setLog.findFirstOrThrow({ where: { userId: a.user.id } });
      expect(set.reps).toBe(10);
      expect(set.deletedAt).toBeNull();
    });

    it('la BD impone la propiedad: FK compuesta impide un entrenamiento sobre la sesión de otro usuario', async () => {
      const a = await userWithPlan(ctx.app);
      const b = await registerUser(ctx.app);
      const err = await ctx.prisma.workoutSession
        .create({
          data: { userId: b.id, clientId: randomUUID(), planSessionId: a.plan.sessions[0].id, startedAt: new Date() },
        })
        .catch((e: unknown) => e);
      expect(err).toBeInstanceOf(Prisma.PrismaClientKnownRequestError);
      expect((err as Prisma.PrismaClientKnownRequestError).code).toBe('P2003');
    });
  });
});
