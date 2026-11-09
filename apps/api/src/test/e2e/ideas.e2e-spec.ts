import request from 'supertest';
import { randomUUID } from 'crypto';
import { isLoadStepMultiple } from '@pipos/engine-rules';
import {
  AccountExportSchema,
  ExerciseNoteResponseSchema,
  PlanExerciseOverrideResponseSchema,
  PlanVersionResponseSchema,
  TodaySessionResponseSchema,
  type TodayExercise,
} from '@pipos/contracts';
import type { WriteEvent } from '../../prisma/prisma.service';
import {
  BEGINNER_GYM,
  bearer,
  createTestApp,
  setBody,
  startToday,
  truncateAll,
  userWithPlan,
  type TestContext,
} from './helpers';

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

  describe('Idea 3: cambio de ejercicio permanente', () => {
    it('fijar, today y series lo aceptan, se hereda al regenerar, se descarta si falta material, volver al original', async () => {
      const { user } = await userWithPlan(ctx.app);
      const t = bearer(user.accessToken);
      const today = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
      // Un hueco con alternativas cuyo material no sea solo el del original.
      let slot: TodayExercise | undefined;
      let alt: { exerciseId: string; slug: string } | undefined;
      for (const e of today.exercises) {
        const subs = await request(server()).get(`/exercises/${e.exercise.id}/substitutes`).set(t).expect(200);
        if (subs.body.substitutes.length > 0) {
          slot = e;
          alt = subs.body.substitutes[0];
          break;
        }
      }
      expect(slot && alt).toBeTruthy();
      const url = `/plans/current/exercises/${slot!.planExerciseId}/override`;
      const versionsBefore = await ctx.prisma.planVersion.count({ where: { userId: user.id } });

      // Un ejercicio que no es alternativa → 400; hueco inexistente → 404.
      const unrelated = today.exercises.find((e) => e.movementPattern !== slot!.movementPattern)!;
      await request(server()).put(url).set(t).send({ exerciseId: unrelated.exercise.id }).expect(400);
      await request(server()).put('/plans/current/exercises/00000000-0000-4000-8000-000000000000/override').set(t).send({ exerciseId: alt!.exerciseId }).expect(404);

      const pinned = PlanExerciseOverrideResponseSchema.parse((await request(server()).put(url).set(t).send({ exerciseId: alt!.exerciseId }).expect(200)).body);
      expect(pinned.pinned?.id).toBe(alt!.exerciseId);
      expect(pinned.original.id).toBe(slot!.exercise.id);
      expect(pinned.planExerciseIds).toContain(slot!.planExerciseId);
      // Fijar no crea una versión nueva del plan.
      expect(await ctx.prisma.planVersion.count({ where: { userId: user.id } })).toBe(versionsBefore);

      // Otro usuario no puede tocar el hueco.
      const other = await userWithPlan(ctx.app);
      await request(server()).put(url).set(bearer(other.user.accessToken)).send({ exerciseId: alt!.exerciseId }).expect(404);

      const during = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
      const ex = during.exercises.find((e) => e.planExerciseId === slot!.planExerciseId)!;
      expect(ex.pinned).toBe(true);
      expect(ex.exercise.id).toBe(alt!.exerciseId);
      expect(ex.substitutedFrom?.id).toBe(slot!.exercise.id);
      const plan = PlanVersionResponseSchema.parse((await request(server()).get('/plans/current').set(t).expect(200)).body);
      const planSlot = plan.sessions.flatMap((s) => s.exercises).find((e) => e.id === slot!.planExerciseId)!;
      expect(planSlot.pinned?.id).toBe(alt!.exerciseId);

      // Regenerar el plan (sin historial nuevo: mismo plan) conserva el cambio en los huecos del
      // mismo ejercicio original.
      const regen = PlanVersionResponseSchema.parse((await request(server()).post('/plans/generate').set(t).expect(201)).body);
      const regenSlots = regen.sessions.flatMap((s) => s.exercises).filter((e) => e.exerciseId === slot!.exercise.id);
      expect(regenSlots.length).toBeGreaterThan(0);
      for (const s of regenSlots) expect(s.pinned?.id).toBe(alt!.exerciseId);
      // El hueco de la versión antigua ya no es de la versión vigente → 404.
      await request(server()).delete(url).set(t).expect(404);

      // La serie del ejercicio fijado se acepta; la de otro ejercicio no.
      const { today: todayNow, workout } = await startToday(ctx.app, user.accessToken);
      const exNow = (todayNow.exercises as TodayExercise[]).find((e) => e.pinned)!;
      expect(exNow.exercise.id).toBe(alt!.exerciseId);
      await request(server()).post(`/workouts/${workout.id}/sets`).set(t).send(setBody(exNow)).expect(201);
      await request(server())
        .post(`/workouts/${workout.id}/sets`)
        .set(t)
        .send(setBody({ planExerciseId: exNow.planExerciseId, exercise: { id: unrelated.exercise.id } }, { setIndex: 1 }))
        .expect(400);
      // Hoy se puede volver puntualmente al original con un cambio fijado.
      const back = await request(server())
        .post(`/workouts/${workout.id}/exercises/${exNow.planExerciseId}/substitute`)
        .set(t)
        .send({ exerciseId: slot!.exercise.id })
        .expect(200);
      expect(back.body.exercise.id).toBe(slot!.exercise.id);
      const swapped = (await request(server()).get('/sessions/today').set(t).expect(200)).body as { exercises: TodayExercise[] };
      const swappedEx = swapped.exercises.find((e) => e.planExerciseId === exNow.planExerciseId)!;
      expect(swappedEx.exercise.id).toBe(slot!.exercise.id);
      expect(swappedEx.pinned).toBe(false);
      await finishAt(user.accessToken, workout.id, new Date());

      // Quitar el material del ejercicio fijado: la versión nueva lo descarta con un aviso.
      const altEquipment = (await ctx.prisma.exercise.findUniqueOrThrow({ where: { id: alt!.exerciseId } })).equipment;
      const origEquipment = (await ctx.prisma.exercise.findUniqueOrThrow({ where: { id: slot!.exercise.id } })).equipment;
      const removable = altEquipment.filter((e) => !origEquipment.includes(e) && e !== 'bodyweight');
      if (removable.length > 0) {
        const profile = await request(server()).get('/me/profile').set(t).expect(200);
        const upd = await request(server())
          .put('/me/profile')
          .set(t)
          .send({
            goal: profile.body.goal,
            level: profile.body.level,
            daysPerWeek: profile.body.daysPerWeek,
            minutesPerSession: profile.body.minutesPerSession,
            equipment: profile.body.equipment.filter((e: string) => !(removable as string[]).includes(e)),
            timezone: profile.body.timezone,
          })
          .expect(200);
        expect(upd.body.planVersion).not.toBeNull();
        const cur = PlanVersionResponseSchema.parse((await request(server()).get('/plans/current').set(t).expect(200)).body);
        expect(cur.sessions.flatMap((s) => s.exercises).every((e) => e.pinned === null)).toBe(true);
        const stillThere = cur.sessions.flatMap((s) => s.exercises).some((e) => e.exerciseId === slot!.exercise.id);
        if (stillThere) expect(cur.warnings.some((w) => w.code === 'PINNED_SUBSTITUTION_DROPPED')).toBe(true);
      } else {
        // Volver al original en la versión vigente.
        const slotNow = regenSlots[0];
        const un = PlanExerciseOverrideResponseSchema.parse(
          (await request(server()).delete(`/plans/current/exercises/${slotNow.id}/override`).set(t).expect(200)).body,
        );
        expect(un.pinned).toBeNull();
        expect(await ctx.prisma.planExerciseOverride.count({ where: { userId: user.id, planExerciseId: { in: un.planExerciseIds } } })).toBe(0);
      }
    });

    it('volver al original con DELETE es idempotente y la versión vigente queda sin cambios fijados', async () => {
      const { user } = await userWithPlan(ctx.app);
      const t = bearer(user.accessToken);
      const plan = PlanVersionResponseSchema.parse((await request(server()).get('/plans/current').set(t).expect(200)).body);
      for (const e of plan.sessions.flatMap((s) => s.exercises)) {
        const subs = await request(server()).get(`/exercises/${e.exerciseId}/substitutes`).set(t).expect(200);
        if (subs.body.substitutes.length === 0) continue;
        const url = `/plans/current/exercises/${e.id}/override`;
        await request(server()).put(url).set(t).send({ exerciseId: subs.body.substitutes[0].exerciseId }).expect(200);
        expect(await ctx.prisma.planExerciseOverride.count({ where: { userId: user.id } })).toBeGreaterThan(0);
        await request(server()).delete(url).set(t).expect(200);
        await request(server()).delete(url).set(t).expect(200);
        // Fijar el propio original equivale a volver.
        await request(server()).put(url).set(t).send({ exerciseId: e.exerciseId }).expect(200);
        expect(await ctx.prisma.planExerciseOverride.count({ where: { userId: user.id } })).toBe(0);
        return;
      }
      throw new Error('ningún ejercicio con alternativas');
    });
  });

  describe('Idea 4: ajuste de hoy (poco tiempo o volumen reducido)', () => {
    it('?minutes recorta ejercicios enteros sin escribir ni crear versión; mode=reduced baja series y sube RIR', async () => {
      const { user } = await userWithPlan(ctx.app, { ...BEGINNER_GYM, minutesPerSession: 60 });
      const t = bearer(user.accessToken);
      const full = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
      expect(full.adjustment).toBeNull();
      const versions = await ctx.prisma.planVersion.count({ where: { userId: user.id } });

      const writes: WriteEvent[] = [];
      const stop = ctx.prisma.onWrite((e) => writes.push(e));
      let short;
      let reduced;
      try {
        short = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today?minutes=20').set(t).expect(200)).body);
        reduced = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today?mode=reduced').set(t).expect(200)).body);
      } finally {
        stop();
      }
      expect(writes).toEqual([]);
      expect(await ctx.prisma.planVersion.count({ where: { userId: user.id } })).toBe(versions);

      expect(short.adjustment).toMatchObject({ source: 'query', availableMinutes: 20, reducedVolume: false });
      expect(short.exercises.length + short.adjustment!.dropped.length).toBe(full.exercises.length);
      expect(short.adjustment!.dropped.length).toBeGreaterThan(0);
      // Nunca se quita el principal ni aumenta el volumen.
      for (const e of full.exercises.filter((x) => x.role === 'main')) {
        expect(short.exercises.some((x) => x.planExerciseId === e.planExerciseId)).toBe(true);
      }
      const fullSets = new Map(full.exercises.map((e) => [e.planExerciseId, e.prescription.sets]));
      for (const e of short.exercises) expect(e.prescription.sets).toBeLessThanOrEqual(fullSets.get(e.planExerciseId)!);
      if (short.adjustment!.fits) expect(short.adjustment!.estimatedMinutes).toBeLessThanOrEqual(20);
      expect(short.adjustment!.rationale.length).toBeGreaterThan(0);

      expect(reduced.exercises).toHaveLength(full.exercises.length);
      for (const e of reduced.exercises) {
        const f = full.exercises.find((x) => x.planExerciseId === e.planExerciseId)!;
        expect(e.prescription.sets).toBeLessThanOrEqual(f.prescription.sets);
        expect(e.prescription.targetRir).toBe(Math.min(5, f.prescription.targetRir + 1));
      }

      // Parámetros fuera de rango → 400.
      await request(server()).get('/sessions/today?minutes=10').set(t).expect(400);
      await request(server()).get('/sessions/today?mode=turbo').set(t).expect(400);

      // Empezar con el ajuste: queda guardado y today lo aplica sin parámetros; reenvío idempotente.
      const clientId = randomUUID();
      const body = { clientId, planSessionId: full.planSessionId, startedAt: new Date().toISOString(), adjustment: { availableMinutes: 20 } };
      const started = await request(server()).post('/workouts').set(t).send(body).expect(201);
      expect(started.body.adjustment).toEqual({ availableMinutes: 20, reducedVolume: false });
      await request(server()).post('/workouts').set(t).send(body).expect(200);
      const during = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
      expect(during.adjustment).toMatchObject({ source: 'workout', availableMinutes: 20 });
      expect(during.exercises.map((e) => e.planExerciseId)).toEqual(short.exercises.map((e) => e.planExerciseId));
      // Un ajuste fuera de rango al empezar → 400.
      await request(server())
        .post('/workouts')
        .set(t)
        .send({ ...body, clientId: randomUUID(), adjustment: { availableMinutes: 5 } })
        .expect(400);
    });

    it('dos sesiones flojas con volumen reducido no bajan la carga (no cuentan para la progresión)', async () => {
      const { user } = await userWithPlan(ctx.app);
      const t = bearer(user.accessToken);
      const start = new Date(Date.now() - 10 * DAY);
      const plan = PlanVersionResponseSchema.parse((await request(server()).get('/plans/current').set(t).expect(200)).body);
      let firstWeighted: string | null = null;
      // Dos vueltas al microciclo, siempre en modo reducido y por debajo del rango.
      for (let i = 0; i < plan.sessions.length * 2; i++) {
        const at = new Date(start.getTime() + i * DAY);
        ctx.clock.set(at);
        const today = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today?mode=reduced').set(t).expect(200)).body);
        const w = await request(server())
          .post('/workouts')
          .set(t)
          .send({ clientId: randomUUID(), planSessionId: today.planSessionId, startedAt: at.toISOString(), adjustment: { reducedVolume: true } })
          .expect(201);
        if (today.order === 0) {
          const ex = today.exercises.find((e) => e.loadType === 'weighted')!;
          firstWeighted ??= ex.planExerciseId;
          const target = today.exercises.find((e) => e.planExerciseId === firstWeighted)!;
          for (let s = 0; s < target.prescription.sets; s++) {
            await request(server())
              .post(`/workouts/${w.body.id}/sets`)
              .set(t)
              .send(setBody(target, { setIndex: s, reps: target.prescription.repMin - 2, loadKg: 40, rir: 0, completedAt: new Date(at.getTime() + (s + 1) * 60_000).toISOString() }))
              .expect(201);
          }
        }
        await finishAt(user.accessToken, w.body.id, at);
      }
      ctx.clock.set(new Date(start.getTime() + plan.sessions.length * 2 * DAY));
      const now = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
      expect(now.order).toBe(0);
      const ex = now.exercises.find((e) => e.planExerciseId === firstWeighted)!;
      expect(ex.prescription.action).not.toBe('decrease_load');
      expect(ex.prescription.action).not.toBe('deload');
      expect(ex.prescription.loadKg).toBe(40);
    });
  });
});
