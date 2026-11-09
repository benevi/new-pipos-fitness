import request from 'supertest';
import {
  areExerciseMusclesOrdered,
  PlanVersionResponseSchema,
  sortExerciseMuscles,
  SubstitutesResponseSchema,
  TodaySessionResponseSchema,
  type ExerciseMuscleRef,
  type TodayExercise,
} from '@pipos/contracts';
import { bearer, createTestApp, startToday, truncateAll, userWithPlan, type TestContext } from './helpers';

/**
 * Músculos visibles en cada ejercicio (ADR-0014, Fase 1), e2e contra Postgres real:
 * `GET /sessions/today`, `GET /plans/current` y `GET /plans/versions/:id` devuelven los músculos
 * del catálogo del ejercicio realmente hecho (sustituto o fijado incluidos), ordenados.
 */
describe('Músculos del ejercicio en Hoy y en Plan (e2e, Postgres real)', () => {
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

  /** Músculos tal y como están en la tabla del catálogo, en el orden de presentación. */
  async function catalogMuscles(exerciseId: string): Promise<ExerciseMuscleRef[]> {
    const rows = await ctx.prisma.exerciseMuscle.findMany({ where: { exerciseId }, select: { muscle: true, role: true } });
    return sortExerciseMuscles(rows);
  }

  /** Un hueco de hoy con una alternativa cuyos músculos difieren de los del original. */
  async function slotWithDifferentSubstitute(token: string, exercises: TodayExercise[]) {
    for (const e of exercises) {
      const subs = SubstitutesResponseSchema.parse(
        (await request(server()).get(`/exercises/${e.exercise.id}/substitutes`).set(bearer(token)).expect(200)).body,
      );
      for (const s of subs.substitutes) {
        const muscles = await catalogMuscles(s.exerciseId);
        // Cada alternativa trae sus músculos principales (hoja de cambio de ejercicio).
        expect(s.primaryMuscles).toEqual(muscles.filter((m) => m.role === 'primary').map((m) => m.muscle));
        expect(s.primaryMuscles.length).toBeGreaterThan(0);
        if (JSON.stringify(muscles) !== JSON.stringify(e.muscles)) return { slot: e, substituteId: s.exerciseId, muscles };
      }
    }
    throw new Error('No slot has a substitute with different muscles');
  }

  it('today, plans/current y plans/versions/:id devuelven los músculos del catálogo, principales primero', async () => {
    const { user, plan } = await userWithPlan(ctx.app);
    const t = bearer(user.accessToken);

    const today = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
    expect(today.exercises.length).toBeGreaterThan(0);
    for (const e of today.exercises) {
      expect(e.muscles.length).toBeGreaterThan(0);
      expect(e.muscles[0].role).toBe('primary');
      expect(areExerciseMusclesOrdered(e.muscles)).toBe(true);
      expect(e.muscles).toEqual(await catalogMuscles(e.exercise.id));
    }

    const current = PlanVersionResponseSchema.parse((await request(server()).get('/plans/current').set(t).expect(200)).body);
    const byVersion = PlanVersionResponseSchema.parse(
      (await request(server()).get(`/plans/versions/${plan.id}`).set(t).expect(200)).body,
    );
    // El cuerpo de la generación (201) también los lleva.
    expect(PlanVersionResponseSchema.parse(plan)).toEqual(current);
    expect(byVersion).toEqual(current);
    for (const e of current.sessions.flatMap((s) => s.exercises)) {
      expect(areExerciseMusclesOrdered(e.muscles)).toBe(true);
      expect(e.muscles).toEqual(await catalogMuscles(e.exerciseId));
    }
  });

  it('con un cambio puntual en el entrenamiento, today devuelve los músculos del sustituto', async () => {
    const { user } = await userWithPlan(ctx.app);
    const t = bearer(user.accessToken);
    const { today, workout } = await startToday(ctx.app, user.accessToken);
    const { slot, substituteId, muscles } = await slotWithDifferentSubstitute(user.accessToken, today.exercises);

    await request(server())
      .post(`/workouts/${workout.id}/exercises/${slot.planExerciseId}/substitute`)
      .set(t)
      .send({ exerciseId: substituteId })
      .expect(200);
    const after = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
    const ex = after.exercises.find((e) => e.planExerciseId === slot.planExerciseId)!;
    expect(ex.exercise.id).toBe(substituteId);
    expect(ex.substitutedFrom?.id).toBe(slot.exercise.id);
    expect(ex.muscles).toEqual(muscles);
    expect(ex.muscles).not.toEqual(slot.muscles);
  });

  it('con un cambio fijado, today y plans/current devuelven los músculos del ejercicio fijado', async () => {
    const { user } = await userWithPlan(ctx.app);
    const t = bearer(user.accessToken);
    const today = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
    const { slot, substituteId, muscles } = await slotWithDifferentSubstitute(user.accessToken, today.exercises);

    await request(server())
      .put(`/plans/current/exercises/${slot.planExerciseId}/override`)
      .set(t)
      .send({ exerciseId: substituteId })
      .expect(200);

    const after = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
    const ex = after.exercises.find((e) => e.planExerciseId === slot.planExerciseId)!;
    expect(ex.pinned).toBe(true);
    expect(ex.muscles).toEqual(muscles);

    const current = PlanVersionResponseSchema.parse((await request(server()).get('/plans/current').set(t).expect(200)).body);
    const planSlot = current.sessions.flatMap((s) => s.exercises).find((e) => e.id === slot.planExerciseId)!;
    expect(planSlot.pinned?.id).toBe(substituteId);
    expect(planSlot.exerciseId).toBe(slot.exercise.id);
    expect(planSlot.muscles).toEqual(muscles);
  });
});
