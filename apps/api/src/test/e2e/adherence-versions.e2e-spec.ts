import request from 'supertest';
import { randomUUID } from 'crypto';
import { weekStartOf } from '../../common/time';
import { AnalyticsService } from '../../modules/analytics/analytics.service';
import { BEGINNER_GYM, bearer, createTestApp, putProfile, setBody, truncateAll, userWithPlan, type TestContext } from './helpers';

const DAY = 86_400_000;
const TZ = BEGINNER_GYM.timezone;

/** Issue #14: la adherencia de semanas pasadas usa la versión del plan vigente en esa semana. */
describe('Adherencia con varias versiones del plan (e2e, Postgres real)', () => {
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

  it('tras pasar de 3 a 5 días, las semanas anteriores siguen con lo previsto entonces (también al reconstruir)', async () => {
    const now = Date.now();
    const { user } = await userWithPlan(ctx.app, BEGINNER_GYM);
    const t = bearer(user.accessToken);
    // El plan de 3 días existe desde hace 3 semanas.
    await ctx.prisma.planVersion.updateMany({ where: { userId: user.id }, data: { createdAt: new Date(now - 21 * DAY) } });
    const v1Sessions = await ctx.prisma.planSession.count({ where: { userId: user.id } });
    expect(v1Sessions).toBe(3);

    // Hace dos semanas: un entrenamiento terminado (calcula la adherencia de esa semana con v1).
    const pastStart = new Date(now - 14 * DAY);
    const today = (await request(server()).get('/sessions/today').set(t).expect(200)).body;
    const workout = (
      await request(server())
        .post('/workouts')
        .set(t)
        .send({ clientId: randomUUID(), planSessionId: today.planSessionId, startedAt: pastStart.toISOString() })
        .expect(201)
    ).body;
    await request(server())
      .post(`/workouts/${workout.id}/sets`)
      .set(t)
      .send(setBody(today.exercises[0], { completedAt: pastStart.toISOString() }))
      .expect(201);
    await request(server())
      .post(`/workouts/${workout.id}/finish`)
      .set(t)
      .send({ completedAt: new Date(pastStart.getTime() + 3_600_000).toISOString() })
      .expect(200);

    // Ahora pasa a 5 días: versión nueva con 5 sesiones.
    await putProfile(ctx.app, user.accessToken, { ...BEGINNER_GYM, daysPerWeek: 5 });
    const current = await request(server()).get('/plans/current').set(t).expect(200);
    const v2Sessions = current.body.sessions.length;
    expect(v2Sessions).toBe(5);

    const pastWeek = weekStartOf(pastStart, TZ);
    const thisWeek = weekStartOf(new Date(now), TZ);
    const check = async () => {
      const weeks: { weekStart: string; plannedSessions: number }[] = (
        await request(server()).get('/progress/adherence?weeks=4').set(t).expect(200)
      ).body.weeks;
      const byWeek = new Map(weeks.map((w) => [w.weekStart, w.plannedSessions]));
      // Semana con actividad (fila calculada) y semana sin actividad posterior: versión de 3 días.
      expect(byWeek.get(pastWeek)).toBe(3);
      for (const w of weeks) {
        if (w.weekStart > pastWeek && w.weekStart < thisWeek) expect(w.plannedSessions).toBe(3);
      }
      // La semana actual ya es de la versión de 5 días.
      expect(byWeek.get(thisWeek)).toBe(5);
    };
    await check();

    // Recalcular esa semana (p. ej. editar una serie del entrenamiento antiguo) no la pasa a 5.
    const setClientId = (await request(server()).get(`/workouts/${workout.id}`).set(t).expect(200)).body.sets[0].clientId;
    await request(server())
      .patch(`/workouts/${workout.id}/sets/${setClientId}`)
      .set(t)
      .send({ reps: 9, clientUpdatedAt: new Date().toISOString() })
      .expect(200);
    await check();

    // analytics:rebuild reconstruye con la misma regla.
    const analytics = ctx.app.get(AnalyticsService);
    await ctx.prisma.$transaction(async (tx) => {
      await analytics.lockUser(tx, user.id);
      await analytics.rebuildUser(tx, user.id);
    });
    const row = await ctx.prisma.weeklyAdherence.findFirst({ where: { userId: user.id } });
    expect(row?.plannedSessions).toBe(3);
    const v1 = await ctx.prisma.planVersion.findFirst({ where: { userId: user.id, version: 1 }, select: { id: true } });
    expect(row?.planVersionId).toBe(v1?.id);
    await check();
  });
});
