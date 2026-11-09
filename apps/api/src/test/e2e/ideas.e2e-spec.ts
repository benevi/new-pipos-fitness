import request from 'supertest';
import { isLoadStepMultiple } from '@pipos/engine-rules';
import {
  AccountExportSchema,
  ExerciseNoteResponseSchema,
  PlanVersionResponseSchema,
  TodaySessionResponseSchema,
  type TodayExercise,
} from '@pipos/contracts';
import { bearer, createTestApp, setBody, startToday, truncateAll, userWithPlan, type TestContext } from './helpers';

const DAY = 86_400_000;

/**
 * Ideas recuperadas (ADR-0013, docs/IDEAS_EL_PLAN.md), e2e contra Postgres real.
 */
describe('Ideas recuperadas (e2e, Postgres real)', () => {
  let ctx: TestContext;
  const server = () => ctx.app.getHttpServer();

  beforeAll(async () => {
    ctx = await createTestApp();
  });
  beforeEach(async () => {
    ctx.clock.set(null);
    await truncateAll(ctx.prisma);
  });
  afterAll(async () => {
    await ctx.app.close();
  });

  async function finishAt(token: string, workoutId: string, at: Date) {
    await request(server())
      .post(`/workouts/${workoutId}/finish`)
      .set(bearer(token))
      .send({ completedAt: new Date(at.getTime() + 3_600_000).toISOString() })
      .expect(200);
  }

  async function logTop(token: string, workoutId: string, ex: TodayExercise, loadKg: number, at: Date) {
    for (let i = 0; i < ex.prescription.sets; i++) {
      await request(server())
        .post(`/workouts/${workoutId}/sets`)
        .set(bearer(token))
        .send(
          setBody(ex, {
            setIndex: i,
            reps: ex.prescription.repMax,
            loadKg,
            rir: ex.prescription.targetRir,
            completedAt: new Date(at.getTime() + (i + 1) * 60_000).toISOString(),
          }),
        )
        .expect(201);
    }
  }

  describe('Idea 1: carga real según el material y discos', () => {
    it('today expone material, paso y discos; la subida propone un peso que existe', async () => {
      const { user, plan } = await userWithPlan(ctx.app);
      const parsedPlan = PlanVersionResponseSchema.parse(plan);
      for (const s of parsedPlan.sessions) {
        for (const e of s.exercises) expect(e.loadImplement === null).toBe(e.loadType !== 'weighted');
      }

      const start = new Date(Date.now() - 6 * DAY);
      ctx.clock.set(start);
      const { today, workout } = await startToday(ctx.app, user.accessToken, start.toISOString());
      const parsed = TodaySessionResponseSchema.parse(today);
      const weighted = parsed.exercises.filter((e) => e.loadType === 'weighted');
      expect(weighted.length).toBeGreaterThan(0);
      for (const e of parsed.exercises) {
        if (e.loadType === 'weighted') {
          expect(e.loadImplement).not.toBeNull();
          expect(e.loadStepKg).toBeGreaterThan(0);
        } else {
          expect(e.loadImplement).toBeNull();
          expect(e.loadStepKg).toBeNull();
          expect(e.plates).toBeNull();
        }
      }
      // 40 kg es múltiplo de todos los pasos (2; 2,5; 4; 5).
      for (const e of weighted) await logTop(user.accessToken, workout.id, e, 40, start);
      await finishAt(user.accessToken, workout.id, start);
      // Las otras sesiones del microciclo, sin series, para volver a la primera.
      for (let d = 1; d < parsedPlan.sessions.length; d++) {
        const at = new Date(start.getTime() + d * DAY);
        ctx.clock.set(at);
        const next = await startToday(ctx.app, user.accessToken, at.toISOString());
        await finishAt(user.accessToken, next.workout.id, at);
      }
      ctx.clock.set(new Date(start.getTime() + 4 * DAY));
      const again = TodaySessionResponseSchema.parse(
        (await request(server()).get('/sessions/today').set(bearer(user.accessToken)).expect(200)).body,
      );
      expect(again.order).toBe(0);
      const raised = again.exercises.filter((e) => e.prescription.action === 'increase_load');
      expect(raised.length).toBeGreaterThan(0);
      for (const e of raised) {
        expect(e.prescription.loadKg).toBeGreaterThan(40);
        expect(isLoadStepMultiple(e.prescription.loadKg!, e.loadImplement)).toBe(true);
        expect(e.prescription.loadKg! - 40).toBeGreaterThanOrEqual(e.loadStepKg!);
        if (e.loadImplement === 'barbell') {
          expect(e.plates).not.toBeNull();
          const p = e.plates!;
          expect(p.barKg + 2 * p.perSide.reduce((a, b) => a + b, 0) + p.remainderKg).toBeCloseTo(e.prescription.loadKg!, 6);
        }
      }
    });
  });

  describe('Idea 2: nota fija por ejercicio', () => {
    it('crear, no pisar con un reloj antiguo, verla en today, export, borrar y borrar la cuenta', async () => {
      const { user } = await userWithPlan(ctx.app);
      const t = bearer(user.accessToken);
      const today = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
      const ex = today.exercises[0];
      expect(ex.note).toBeNull();
      const url = `/exercises/${ex.exercise.id}/note`;

      const created = await request(server())
        .put(url)
        .set(t)
        .send({ text: '  Asiento en el 4, agarre ancho  ', clientUpdatedAt: '2026-11-09T10:00:00.000Z' })
        .expect(200);
      expect(ExerciseNoteResponseSchema.parse(created.body)).toMatchObject({ text: 'Asiento en el 4, agarre ancho', slug: ex.exercise.slug });
      // Edición offline más antigua: no pisa, devuelve la vigente.
      const stale = await request(server())
        .put(url)
        .set(t)
        .send({ text: 'antigua', clientUpdatedAt: '2026-11-09T09:00:00.000Z' })
        .expect(200);
      expect(stale.body.text).toBe('Asiento en el 4, agarre ancho');
      await request(server()).put(url).set(t).send({ text: 'Asiento en el 5', clientUpdatedAt: '2026-11-09T11:00:00.000Z' }).expect(200);
      // Validación: vacía o > 280 → 400.
      await request(server()).put(url).set(t).send({ text: '   ', clientUpdatedAt: '2026-11-09T12:00:00.000Z' }).expect(400);
      await request(server()).put(url).set(t).send({ text: 'x'.repeat(281), clientUpdatedAt: '2026-11-09T12:00:00.000Z' }).expect(400);
      await request(server()).put('/exercises/00000000-0000-4000-8000-000000000000/note').set(t).send({ text: 'a', clientUpdatedAt: '2026-11-09T12:00:00.000Z' }).expect(404);

      const again = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
      expect(again.exercises[0].note).toBe('Asiento en el 5');
      const list = await request(server()).get('/me/exercise-notes').set(t).expect(200);
      expect(list.body.items).toHaveLength(1);
      const exp = AccountExportSchema.parse((await request(server()).get('/me/export').set(t).expect(200)).body);
      expect(exp.exerciseNotes.map((n) => n.text)).toEqual(['Asiento en el 5']);

      // Otro usuario no ve la nota.
      const other = await userWithPlan(ctx.app);
      const otherList = await request(server()).get('/me/exercise-notes').set(bearer(other.user.accessToken)).expect(200);
      expect(otherList.body.items).toEqual([]);

      await request(server()).delete(url).set(t).expect(200);
      await request(server()).delete(url).set(t).expect(200); // idempotente
      expect(await ctx.prisma.userExerciseNote.count({ where: { userId: user.id } })).toBe(0);

      await request(server()).put(url).set(t).send({ text: 'otra', clientUpdatedAt: '2026-11-10T11:00:00.000Z' }).expect(200);
      await request(server()).delete('/me').set(t).send({ password: user.password }).expect(204);
      expect(await ctx.prisma.userExerciseNote.count({ where: { userId: user.id } })).toBe(0);
    });
  });
});
