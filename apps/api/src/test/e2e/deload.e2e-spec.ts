import request from 'supertest';
import { randomUUID } from 'crypto';
import { PROGRAMMING } from '@pipos/engine-rules';
import { dateColumn, localDate } from '../../common/time';
import { BEGINNER_GYM, bearer, createTestApp, setBody, truncateAll, userWithPlan, type TestContext } from './helpers';

const DAY = 86_400_000;
const TZ = BEGINNER_GYM.timezone;
const EVERY = PROGRAMMING.progression.deloadEveryWeeks.value;

interface TodayBody {
  planSessionId: string;
  exercises: { planExerciseId: string; exercise: { id: string }; prescription: { isDeload: boolean } }[];
}

/** Issue #15: la descarga real (programada o reactiva) ancla el ciclo de descarga programada. */
describe('Ciclo de descarga anclado a la última descarga real (e2e, Postgres real)', () => {
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

  const today = async (t: Record<string, string>): Promise<TodayBody> =>
    (await request(server()).get('/sessions/today').set(t).expect(200)).body;
  const allDeload = (body: TodayBody) => body.exercises.every((e) => e.prescription.isDeload);
  const noneDeload = (body: TodayBody) => body.exercises.every((e) => !e.prescription.isDeload);

  /** Hace la sesión que toca en `at`: una serie por ejercicio y la cierra. */
  async function train(t: Record<string, string>, at: Date): Promise<TodayBody> {
    ctx.clock.set(at);
    const session = await today(t);
    const workout = (
      await request(server())
        .post('/workouts')
        .set(t)
        .send({ clientId: randomUUID(), planSessionId: session.planSessionId, startedAt: at.toISOString() })
        .expect(201)
    ).body;
    for (const ex of session.exercises) {
      await request(server())
        .post(`/workouts/${workout.id}/sets`)
        .set(t)
        .send(setBody(ex, { completedAt: at.toISOString() }))
        .expect(201);
    }
    await request(server()).post(`/workouts/${workout.id}/finish`).set(t).send({ completedAt: at.toISOString() }).expect(200);
    return session;
  }

  /** Usuario con plan e historial reciente de todas las sesiones antes de la semana de descarga. */
  async function setup() {
    const { user } = await userWithPlan(ctx.app);
    const t = bearer(user.accessToken);
    const plan = await ctx.prisma.trainingPlan.findFirstOrThrow({ where: { userId: user.id } });
    const programmed = new Date(plan.createdAt.getTime() + (EVERY * 7 + 1) * DAY);
    const sessions = await ctx.prisma.planSession.count({ where: { userId: user.id } });
    for (let i = sessions; i >= 1; i--) await train(t, new Date(programmed.getTime() - i * DAY));
    return { t, plan, programmed };
  }

  it('cerrar un entreno de descarga programada guarda lastDeloadOn; el resto de la semana sigue en descarga', async () => {
    const { t, plan, programmed } = await setup();
    expect((await ctx.prisma.trainingPlan.findUniqueOrThrow({ where: { id: plan.id } })).lastDeloadOn).toBeNull();
    ctx.clock.set(programmed);
    expect(allDeload(await today(t))).toBe(true);

    await train(t, programmed);
    const after = await ctx.prisma.trainingPlan.findUniqueOrThrow({ where: { id: plan.id } });
    expect(after.lastDeloadOn?.toISOString().slice(0, 10)).toBe(localDate(programmed, TZ));

    // Otro entreno de descarga dos días después no mueve el ancla y sigue en descarga.
    const later = new Date(programmed.getTime() + 2 * DAY);
    ctx.clock.set(later);
    expect(allDeload(await today(t))).toBe(true);
    await train(t, later);
    const again = await ctx.prisma.trainingPlan.findUniqueOrThrow({ where: { id: plan.id } });
    expect(again.lastDeloadOn?.toISOString()).toBe(after.lastDeloadOn?.toISOString());
  });

  it('tras una descarga real reciente no llega la programada poco después', async () => {
    const { t, plan, programmed } = await setup();
    ctx.clock.set(programmed);
    // Sin descarga registrada, en la semana EVERY toca la programada.
    expect(allDeload(await today(t))).toBe(true);

    // Una descarga (p. ej. reactiva) que empezó hace 8 días reinicia el ciclo: hoy no toca.
    const reactive = localDate(new Date(programmed.getTime() - 8 * DAY), TZ);
    await ctx.prisma.trainingPlan.update({ where: { id: plan.id }, data: { lastDeloadOn: dateColumn(reactive) } });
    expect(noneDeload(await today(t))).toBe(true);

    // Si la descarga empezó hace 3 días, la semana de descarga continúa.
    const recent = localDate(new Date(programmed.getTime() - 3 * DAY), TZ);
    await ctx.prisma.trainingPlan.update({ where: { id: plan.id }, data: { lastDeloadOn: dateColumn(recent) } });
    expect(allDeload(await today(t))).toBe(true);
  });
});
