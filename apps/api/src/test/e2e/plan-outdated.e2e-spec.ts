import request from 'supertest';
import { randomUUID } from 'crypto';
import { bearer, createTestApp, generatePlan, setBody, startToday, truncateAll, userWithPlan, type TestContext } from './helpers';

/** Issue #10: entrenamientos nuevos sobre una versión antigua del plan → 409 PLAN_SESSION_OUTDATED. */
describe('Entrenos sobre versiones antiguas del plan (e2e, Postgres real)', () => {
  let ctx: TestContext;
  const server = () => ctx.app.getHttpServer();

  beforeAll(async () => {
    ctx = await createTestApp();
  });
  afterAll(async () => {
    await ctx.app.close();
  });
  beforeEach(async () => {
    await truncateAll(ctx.prisma);
  });

  it('rechaza empezar con una sesión de la versión anterior y acepta la vigente', async () => {
    const { user } = await userWithPlan(ctx.app);
    const old = await request(server()).get('/sessions/today').set(bearer(user.accessToken)).expect(200);
    await generatePlan(ctx.app, user.accessToken); // versión 2

    const rejected = await request(server())
      .post('/workouts')
      .set(bearer(user.accessToken))
      .send({ clientId: randomUUID(), planSessionId: old.body.planSessionId, startedAt: new Date().toISOString() })
      .expect(409);
    expect(rejected.body.code).toBe('PLAN_SESSION_OUTDATED');
    expect(await ctx.prisma.workoutSession.count()).toBe(0);

    // Lo que debe hacer el cliente: refrescar /sessions/today y empezar con la sesión vigente.
    const fresh = await request(server()).get('/sessions/today').set(bearer(user.accessToken)).expect(200);
    expect(fresh.body.planVersionId).not.toBe(old.body.planVersionId);
    await request(server())
      .post('/workouts')
      .set(bearer(user.accessToken))
      .send({ clientId: randomUUID(), planSessionId: fresh.body.planSessionId, startedAt: new Date().toISOString() })
      .expect(201);
  });

  it('un entrenamiento ya empezado en la versión anterior sigue aceptando reenvíos, series y cierre', async () => {
    const { user } = await userWithPlan(ctx.app);
    const startedAt = new Date().toISOString();
    const { today, workout } = await startToday(ctx.app, user.accessToken, startedAt);
    await generatePlan(ctx.app, user.accessToken); // cambio de plan desde otro dispositivo

    // La cola offline reenvía el inicio: idempotente (200), no 409.
    await request(server())
      .post('/workouts')
      .set(bearer(user.accessToken))
      .send({ clientId: workout.clientId, planSessionId: today.planSessionId, startedAt })
      .expect(200);
    // Y sus series siguen entrando (el entreno tiene series de la versión anterior).
    await request(server())
      .post(`/workouts/${workout.id}/sets`)
      .set(bearer(user.accessToken))
      .send(setBody(today.exercises[0]))
      .expect(201);
    await request(server())
      .post(`/workouts/${workout.id}/finish`)
      .set(bearer(user.accessToken))
      .send({ completedAt: new Date().toISOString() })
      .expect(200);
  });
});
