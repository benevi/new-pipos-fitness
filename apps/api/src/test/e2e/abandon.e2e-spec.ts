import request from 'supertest';
import { randomUUID } from 'crypto';
import { STALE_WORKOUT_HOURS } from '../../modules/workouts/workouts.service';
import { bearer, createTestApp, setBody, startToday, truncateAll, userWithPlan, type TestContext } from './helpers';

const HOUR = 3_600_000;

/** Issue #13: abandonar entrenamientos (manual e idempotente, y automático tras 12 h). */
describe('Entrenamientos abandonados (e2e, Postgres real)', () => {
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
    ctx.clock.set(null);
  });

  it('POST /workouts/:id/abandon: idempotente, sin series nuevas y fuera de la analítica y la adherencia', async () => {
    const { user } = await userWithPlan(ctx.app);
    const t = bearer(user.accessToken);
    const { today, workout } = await startToday(ctx.app, user.accessToken);
    await request(server()).post(`/workouts/${workout.id}/sets`).set(t).send(setBody(today.exercises[0])).expect(201);
    const before = (await request(server()).get('/progress/adherence?weeks=1').set(t).expect(200)).body.weeks[0];
    expect(before.completedSets).toBe(1);
    expect(await ctx.prisma.weeklyMuscleVolume.count({ where: { userId: user.id } })).toBeGreaterThan(0);

    const first = await request(server()).post(`/workouts/${workout.id}/abandon`).set(t).expect(200);
    expect(first.body.status).toBe('abandoned');
    const again = await request(server()).post(`/workouts/${workout.id}/abandon`).set(t).expect(200);
    expect(again.body).toEqual(first.body);

    // No admite series nuevas ni cierre.
    const late = await request(server()).post(`/workouts/${workout.id}/sets`).set(t).send(setBody(today.exercises[0], { setIndex: 1 }));
    expect(late.status).toBe(409);
    expect(late.body.code).toBe('WORKOUT_FINISHED');
    await request(server()).post(`/workouts/${workout.id}/finish`).set(t).send({ completedAt: new Date().toISOString() }).expect(409);

    // Fuera de la adherencia y la analítica (las series se conservan en el entrenamiento).
    const after = (await request(server()).get('/progress/adherence?weeks=1').set(t).expect(200)).body.weeks[0];
    expect(after).toMatchObject({ completedSessions: 0, completedSets: 0 });
    expect(await ctx.prisma.exerciseE1rm.count({ where: { userId: user.id } })).toBe(0);
    expect(await ctx.prisma.weeklyMuscleVolume.count({ where: { userId: user.id } })).toBe(0);
    expect((await request(server()).get(`/workouts/${workout.id}`).set(t).expect(200)).body.sets).toHaveLength(1);

    // La sesión de hoy ya no lo muestra en curso y propone la misma sesión (no se completó).
    const next = await request(server()).get('/sessions/today').set(t).expect(200);
    expect(next.body.workout).toBeNull();
    expect(next.body.planSessionId).toBe(today.planSessionId);
  });

  it('abandonar uno terminado → 409; uno ajeno → 404', async () => {
    const { user } = await userWithPlan(ctx.app);
    const { user: other } = await userWithPlan(ctx.app);
    const { workout } = await startToday(ctx.app, user.accessToken);
    await request(server()).post(`/workouts/${workout.id}/abandon`).set(bearer(other.accessToken)).expect(404);
    await request(server())
      .post(`/workouts/${workout.id}/finish`)
      .set(bearer(user.accessToken))
      .send({ completedAt: new Date().toISOString() })
      .expect(200);
    const res = await request(server()).post(`/workouts/${workout.id}/abandon`).set(bearer(user.accessToken)).expect(409);
    expect(res.body.code).toBe('WORKOUT_FINISHED');
  });

  it(`empezar otro abandona solo el que lleva más de ${STALE_WORKOUT_HOURS} h sin actividad`, async () => {
    const { user } = await userWithPlan(ctx.app);
    const t = bearer(user.accessToken);
    const now = new Date('2026-11-10T20:00:00.000Z');
    ctx.clock.set(now);
    const { today, workout } = await startToday(ctx.app, user.accessToken, new Date(now.getTime() - 14 * HOUR).toISOString());
    // Una serie hace 2 h lo mantiene vivo.
    await request(server())
      .post(`/workouts/${workout.id}/sets`)
      .set(t)
      .send(setBody(today.exercises[0], { completedAt: new Date(now.getTime() - 2 * HOUR).toISOString() }))
      .expect(201);
    const start = () =>
      request(server())
        .post('/workouts')
        .set(t)
        .send({ clientId: randomUUID(), planSessionId: today.planSessionId, startedAt: now.toISOString() });
    const blocked = await start().expect(409);
    expect(blocked.body.code).toBe('WORKOUT_IN_PROGRESS');

    // 13 h después de esa serie: el nuevo inicio lo abandona y empieza otro.
    ctx.clock.set(new Date(now.getTime() + 11 * HOUR + 60_000));
    const fresh = await start().expect(201);
    expect(fresh.body.status).toBe('in_progress');
    const old = await request(server()).get(`/workouts/${workout.id}`).set(t).expect(200);
    expect(old.body.status).toBe('abandoned');
    const adherence = await ctx.prisma.weeklyAdherence.findMany({ where: { userId: user.id } });
    expect(adherence.every((w) => w.completedSets === 0)).toBe(true);
  });
});
