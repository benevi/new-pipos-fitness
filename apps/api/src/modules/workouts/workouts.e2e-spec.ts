import request from 'supertest';
import { randomUUID } from 'crypto';
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

describe('Workouts (e2e, Postgres real)', () => {
  let ctx: TestContext;
  let alice: RegisteredUser;
  let bob: RegisteredUser;
  let exerciseId: string;
  const server = () => ctx.app.getHttpServer();

  beforeAll(async () => {
    ctx = await createTestApp();
  });

  beforeEach(async () => {
    await truncateAll(ctx.prisma);
    alice = await registerUser(ctx.app, 'alice@example.com');
    bob = await registerUser(ctx.app, 'bob@example.com');
    exerciseId = (await createExercise(ctx.prisma, { slug: 'bench-press' })).id;
  });

  afterAll(async () => {
    await ctx.app.close();
  });

  async function startWorkout(user: RegisteredUser, body: Record<string, unknown> = {}) {
    const res = await request(server()).post('/workouts/start').set(bearer(user.accessToken)).send(body).expect(201);
    return res.body as { id: string; planSessionId: string | null; planVersionId: string | null };
  }

  async function addExercise(user: RegisteredUser, workoutId: string) {
    const res = await request(server())
      .post(`/workouts/${workoutId}/exercises`)
      .set(bearer(user.accessToken))
      .send({ exerciseId })
      .expect(201);
    return res.body.exercises[0].id as string;
  }

  describe('flujo completo del propietario', () => {
    it('start → añadir ejercicio → registrar series → finalizar → historial', async () => {
      const workout = await startWorkout(alice);
      expect(workout).toMatchObject({ planSessionId: null, planVersionId: null });

      const workoutExerciseId = await addExercise(alice, workout.id);

      const withSet = await request(server())
        .post(`/workouts/${workout.id}/exercises/${workoutExerciseId}/sets`)
        .set(bearer(alice.accessToken))
        .send({ weightKg: 80, reps: 10, rir: 2 })
        .expect(201);
      expect(withSet.body.exercises[0].sets).toEqual([
        expect.objectContaining({ setIndex: 0, weightKg: 80, reps: 10, rir: 2, completed: true }),
      ]);

      const finished = await request(server())
        .post(`/workouts/${workout.id}/finish`)
        .set(bearer(alice.accessToken))
        .send({ durationMinutes: 45, notes: 'Good session' })
        .expect(201);
      expect(finished.body.completedAt).toEqual(expect.any(String));
      expect(finished.body.notes).toBe('Good session');

      const history = await request(server()).get('/workouts/history').set(bearer(alice.accessToken)).expect(200);
      expect(history.body.map((w: { id: string }) => w.id)).toEqual([workout.id]);

      const detail = await request(server()).get(`/workouts/${workout.id}`).set(bearer(alice.accessToken)).expect(200);
      expect(detail.body.id).toBe(workout.id);
    });

    it('start con planSessionId propio devuelve planVersionId', async () => {
      const plan = await createPlanSession(ctx.prisma, alice.id, exerciseId);
      const workout = await startWorkout(alice, { planSessionId: plan.planSessionId });
      expect(workout.planSessionId).toBe(plan.planSessionId);
      expect(workout.planVersionId).toBe(plan.planVersionId);
    });

    it('409 al registrar series en un entrenamiento ya finalizado', async () => {
      const workout = await startWorkout(alice);
      const weId = await addExercise(alice, workout.id);
      await request(server()).post(`/workouts/${workout.id}/finish`).set(bearer(alice.accessToken)).send({}).expect(201);
      await request(server())
        .post(`/workouts/${workout.id}/exercises/${weId}/sets`)
        .set(bearer(alice.accessToken))
        .send({ reps: 5 })
        .expect(409);
    });

    it('404 si workoutExerciseId no pertenece a esa sesión', async () => {
      const w1 = await startWorkout(alice);
      const w2 = await startWorkout(alice);
      const weOfW2 = await addExercise(alice, w2.id);
      await request(server())
        .post(`/workouts/${w1.id}/exercises/${weOfW2}/sets`)
        .set(bearer(alice.accessToken))
        .send({ reps: 5 })
        .expect(404);
    });

    it('404 si el ejercicio de catálogo no existe', async () => {
      const workout = await startWorkout(alice);
      await request(server())
        .post(`/workouts/${workout.id}/exercises`)
        .set(bearer(alice.accessToken))
        .send({ exerciseId: randomUUID() })
        .expect(404);
    });
  });

  describe('ownership: Bob no puede tocar recursos de Alice (404, nunca 403)', () => {
    it('no puede iniciar un entrenamiento sobre la planSession de Alice', async () => {
      const plan = await createPlanSession(ctx.prisma, alice.id, exerciseId);
      const res = await request(server())
        .post('/workouts/start')
        .set(bearer(bob.accessToken))
        .send({ planSessionId: plan.planSessionId })
        .expect(404);
      expect(res.body.message).toBe('Training session not found');
      expect(await ctx.prisma.workoutSession.count({ where: { userId: bob.id } })).toBe(0);
    });

    it('no puede registrar series en la sesión de Alice', async () => {
      const workout = await startWorkout(alice);
      const weId = await addExercise(alice, workout.id);
      await request(server())
        .post(`/workouts/${workout.id}/exercises/${weId}/sets`)
        .set(bearer(bob.accessToken))
        .send({ weightKg: 100, reps: 1 })
        .expect(404);
      expect(await ctx.prisma.workoutSet.count()).toBe(0);
    });

    it('no puede leer, añadir ejercicios ni finalizar la sesión de Alice', async () => {
      const workout = await startWorkout(alice);
      await request(server()).get(`/workouts/${workout.id}`).set(bearer(bob.accessToken)).expect(404);
      await request(server())
        .post(`/workouts/${workout.id}/exercises`)
        .set(bearer(bob.accessToken))
        .send({ exerciseId })
        .expect(404);
      await request(server()).post(`/workouts/${workout.id}/finish`).set(bearer(bob.accessToken)).send({}).expect(404);
      const stored = await ctx.prisma.workoutSession.findUniqueOrThrow({ where: { id: workout.id } });
      expect(stored.completedAt).toBeNull();
    });

    it('el historial de Bob no incluye entrenamientos de Alice', async () => {
      await startWorkout(alice);
      const history = await request(server()).get('/workouts/history').set(bearer(bob.accessToken)).expect(200);
      expect(history.body).toEqual([]);
    });

    it('la respuesta para un recurso ajeno es idéntica a la de uno inexistente', async () => {
      const workout = await startWorkout(alice);
      const foreign = await request(server()).get(`/workouts/${workout.id}`).set(bearer(bob.accessToken));
      const missing = await request(server()).get(`/workouts/${randomUUID()}`).set(bearer(bob.accessToken));
      expect(foreign.status).toBe(404);
      expect(foreign.body).toEqual(missing.body);
    });
  });

  describe('validación', () => {
    it('400 si :id no es UUID', async () => {
      await request(server()).get('/workouts/not-a-uuid').set(bearer(alice.accessToken)).expect(400);
      await request(server())
        .post(`/workouts/${randomUUID()}/exercises/nope/sets`)
        .set(bearer(alice.accessToken))
        .send({})
        .expect(400);
    });

    it('400 si notes supera 1000 caracteres', async () => {
      const workout = await startWorkout(alice);
      await request(server())
        .post(`/workouts/${workout.id}/finish`)
        .set(bearer(alice.accessToken))
        .send({ notes: 'n'.repeat(1001) })
        .expect(400);
    });

    it('401 sin token', async () => {
      await request(server()).post('/workouts/start').send({}).expect(401);
    });
  });
});
