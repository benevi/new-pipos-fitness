import request from 'supertest';
import { createHash, randomUUID } from 'crypto';
import { isLoadStepMultiple } from '@pipos/engine-rules';
import {
  AccountExportSchema,
  BodyMeasurementListResponseSchema,
  BodyProgressResponseSchema,
  HEALTH_CONSENT_POLICIES,
  HEALTH_CONSENT_POLICY,
  HealthConsentStatusSchema,
  ExerciseNoteResponseSchema,
  PlanExerciseOverrideResponseSchema,
  PlanVersionResponseSchema,
  ProfileResponseSchema,
  TodaySessionResponseSchema,
  TrainingBreakListResponseSchema,
  TrainingBreakResponseSchema,
  type TodayExercise,
} from '@pipos/contracts';
import type { WriteEvent } from '../../prisma/prisma.service';
import {
  BEGINNER_GYM,
  bearer,
  createTestApp,
  grantHealthConsent,
  putProfile,
  registerUser,
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

  describe('Idea 6: días de entreno y pausas planificadas', () => {
    it('PATCH /me/profile/schedule: valida contra daysPerWeek, no crea versión y today dice si toca', async () => {
      const { user } = await userWithPlan(ctx.app); // 3 días por semana
      const t = bearer(user.accessToken);
      const versions = await ctx.prisma.planVersion.count({ where: { userId: user.id } });
      await request(server()).patch('/me/profile/schedule').set(t).send({ trainingWeekdays: [1, 2, 3, 4] }).expect(422);
      await request(server()).patch('/me/profile/schedule').set(t).send({ trainingWeekdays: [1, 1] }).expect(400);
      await request(server()).patch('/me/profile/schedule').set(t).send({ trainingWeekdays: [0] }).expect(400);
      const res = await request(server()).patch('/me/profile/schedule').set(t).send({ trainingWeekdays: [5, 1, 3] }).expect(200);
      expect(ProfileResponseSchema.parse(res.body).trainingWeekdays).toEqual([1, 3, 5]);
      expect(await ctx.prisma.planVersion.count({ where: { userId: user.id } })).toBe(versions);

      ctx.clock.set('2026-11-09T10:00:00.000Z'); // lunes
      const monday = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
      expect(monday.scheduledToday).toBe(true);
      expect(monday.activeBreak).toBeNull();
      ctx.clock.set('2026-11-10T10:00:00.000Z'); // martes
      const tuesday = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
      expect(tuesday.scheduledToday).toBe(false);

      // Bajar daysPerWeek por debajo de los días elegidos los vacía; si caben, se conservan.
      await request(server()).put('/me/profile').set(t).send({ ...BEGINNER_GYM, daysPerWeek: 2 }).expect(200);
      expect((await request(server()).get('/me/profile').set(t).expect(200)).body.trainingWeekdays).toEqual([]);
      await request(server()).patch('/me/profile/schedule').set(t).send({ trainingWeekdays: [2, 4] }).expect(200);
      await request(server()).put('/me/profile').set(t).send({ ...BEGINNER_GYM, daysPerWeek: 4 }).expect(200);
      expect((await request(server()).get('/me/profile').set(t).expect(200)).body.trainingWeekdays).toEqual([2, 4]);
    });

    it('pausas: validación, idempotencia, solapes, adherencia sin 0 % falso y today en pausa', async () => {
      const { user } = await userWithPlan(ctx.app); // 3 días
      const t = bearer(user.accessToken);
      await request(server()).patch('/me/profile/schedule').set(t).send({ trainingWeekdays: [1, 3, 5] }).expect(200);
      // Entrena el lunes 2026-11-09.
      ctx.clock.set('2026-11-09T10:00:00.000Z');
      const { workout } = await startToday(ctx.app, user.accessToken, '2026-11-09T10:00:00.000Z');
      await finishAt(user.accessToken, workout.id, new Date('2026-11-09T10:00:00.000Z'));
      ctx.clock.set('2026-11-11T10:00:00.000Z');
      const week = async () =>
        (await request(server()).get('/progress/adherence?weeks=1').set(t).expect(200)).body.weeks[0] as {
          plannedSessions: number;
          completedSessions: number;
          breakDays: number;
        };
      expect(await week()).toMatchObject({ plannedSessions: 3, completedSessions: 1, breakDays: 0 });

      // Validación.
      const bad = (startsOn: string, endsOn: string) =>
        request(server()).post('/me/breaks').set(t).send({ clientId: randomUUID(), startsOn, endsOn });
      await bad('2026-11-15', '2026-11-10').expect(400);
      await bad('2026-11-10', '2027-01-09').expect(400); // 61 días
      await bad('2026-11-31', '2026-12-01').expect(400);

      // Pausa de martes a domingo: queda el lunes (elegido) → 1 prevista, 1 hecha.
      const body = { clientId: randomUUID(), startsOn: '2026-11-10', endsOn: '2026-11-15' };
      const created = TrainingBreakResponseSchema.parse((await request(server()).post('/me/breaks').set(t).send(body).expect(201)).body);
      expect(created).toMatchObject({ startsOn: '2026-11-10', endsOn: '2026-11-15' });
      await request(server()).post('/me/breaks').set(t).send(body).expect(200); // reenvío
      await request(server()).post('/me/breaks').set(t).send({ ...body, endsOn: '2026-11-16' }).expect(409); // clientId reutilizado
      await request(server()).post('/me/breaks').set(t).send({ clientId: randomUUID(), startsOn: '2026-11-15', endsOn: '2026-11-20' }).expect(409); // solape
      expect(await week()).toMatchObject({ plannedSessions: 1, completedSessions: 1, breakDays: 6 });
      const row = await ctx.prisma.weeklyAdherence.findFirstOrThrow({ where: { userId: user.id } });
      expect(row.plannedSessions).toBe(1); // recalculado al escribir (ADR-0008)

      const today = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
      expect(today.activeBreak).toEqual({ id: created.id, startsOn: '2026-11-10', endsOn: '2026-11-15' });
      expect(today.scheduledToday).toBe(false);
      const list = TrainingBreakListResponseSchema.parse((await request(server()).get('/me/breaks?from=2026-11-01').set(t).expect(200)).body);
      expect(list.items.map((b) => b.id)).toEqual([created.id]);
      expect((await request(server()).get('/me/breaks?from=2026-12-01').set(t).expect(200)).body.items).toEqual([]);

      // Otro usuario no ve ni borra la pausa.
      const other = await userWithPlan(ctx.app);
      expect((await request(server()).get('/me/breaks').set(bearer(other.user.accessToken)).expect(200)).body.items).toEqual([]);
      await request(server()).delete(`/me/breaks/${created.id}`).set(bearer(other.user.accessToken)).expect(200);
      expect(await ctx.prisma.trainingBreak.count({ where: { id: created.id } })).toBe(1);

      // Borrar la pausa restaura lo previsto.
      await request(server()).delete(`/me/breaks/${created.id}`).set(t).expect(200);
      await request(server()).delete(`/me/breaks/${created.id}`).set(t).expect(200);
      expect(await week()).toMatchObject({ plannedSessions: 3, completedSessions: 1, breakDays: 0 });
    });

    it('la pausa planificada no cuenta como ausencia: no baja la carga al volver', async () => {
      const { user } = await userWithPlan(ctx.app);
      const t = bearer(user.accessToken);
      const plan = PlanVersionResponseSchema.parse((await request(server()).get('/plans/current').set(t).expect(200)).body);
      const day0 = new Date('2026-08-03T10:00:00.000Z');
      ctx.clock.set(day0);
      const { today, workout } = await startToday(ctx.app, user.accessToken, day0.toISOString());
      const ex = today.exercises.find((e: TodayExercise) => e.loadType === 'weighted') as TodayExercise;
      await logTop(user.accessToken, workout.id, ex, 40, day0);
      await finishAt(user.accessToken, workout.id, day0);
      for (let d = 1; d < plan.sessions.length; d++) {
        const at = new Date(day0.getTime() + d * DAY);
        ctx.clock.set(at);
        const w = await startToday(ctx.app, user.accessToken, at.toISOString());
        await finishAt(user.accessToken, w.workout.id, at);
      }
      // 21 días después de la sesión.
      ctx.clock.set(new Date(day0.getTime() + 21 * DAY));
      const away = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
      expect(away.exercises.find((e) => e.planExerciseId === ex.planExerciseId)!.prescription.action).toBe('return_after_break');
      // Con 15 de esos días en pausa planificada, la ausencia real es de 6 días.
      await request(server()).post('/me/breaks').set(t).send({ clientId: randomUUID(), startsOn: '2026-08-05', endsOn: '2026-08-19' }).expect(201);
      const back = TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);
      const p = back.exercises.find((e) => e.planExerciseId === ex.planExerciseId)!.prescription;
      expect(p.action).not.toBe('return_after_break');
      expect(p.loadKg).toBeGreaterThanOrEqual(40);
    });
  });

  describe('Idea 7: medidas corporales (dato de salud)', () => {
    const FULL = { ...BEGINNER_GYM, goal: 'fat_loss' as const, birthYear: 1990, sex: 'male' as const, activityLevel: 'active' as const };

    async function oldConsent(userId: string) {
      // Consentimiento concedido con la versión anterior del texto (solo peso, altura y limitaciones).
      const old = HEALTH_CONSENT_POLICIES[0];
      await ctx.prisma.consentEvent.create({
        data: {
          userId,
          purpose: 'health_data_processing',
          action: 'granted',
          policyVersion: old.version,
          textHash: createHash('sha256').update(old.textEs).digest('hex'),
          locale: 'es',
        },
      });
    }

    it('sin consentimiento → 409 y 0 filas; versión anterior: peso sí, perímetros no; la versión actual lo cubre todo', async () => {
      const u = await registerUser(ctx.app);
      const t = bearer(u.accessToken);
      await putProfile(ctx.app, u.accessToken, FULL);
      const put = (body: Record<string, unknown>) => request(server()).put('/me/measurements').set(t).send(body);

      const none = await put({ measuredOn: '2026-11-01', weightKg: 80 }).expect(409);
      expect(none.body.code).toBe('HEALTH_CONSENT_REQUIRED');
      expect(await ctx.prisma.bodyMeasurement.count({ where: { userId: u.id } })).toBe(0);

      await oldConsent(u.id);
      const status = HealthConsentStatusSchema.parse((await request(server()).get('/me/consents/health').set(t).expect(200)).body);
      expect(status).toMatchObject({ granted: true, version: 'health-2026-11', currentVersion: HEALTH_CONSENT_POLICY.version });
      expect(status.scopes).toEqual(['weight', 'height', 'limitations']);
      await put({ measuredOn: '2026-11-01', weightKg: 80 }).expect(200);
      for (const field of ['waistCm', 'neckCm', 'hipCm', 'chestCm', 'armCm', 'thighCm']) {
        const res = await put({ measuredOn: '2026-11-02', [field]: 60 }).expect(409);
        expect(res.body.issues[0].path).toBe(`body.${field}`);
      }
      expect(await ctx.prisma.bodyMeasurement.count({ where: { userId: u.id } })).toBe(1);
      // Las estimaciones derivadas también requieren la versión actual.
      const body = BodyProgressResponseSchema.parse((await request(server()).get('/progress/body').set(t).expect(200)).body);
      expect(body.bmi.status).toBe('consent_required');
      expect(body.bodyFat.status).toBe('consent_required');

      await grantHealthConsent(ctx.app, u.accessToken); // nueva versión: registra el evento
      expect(await ctx.prisma.consentEvent.count({ where: { userId: u.id, action: 'granted' } })).toBe(2);
      await put({ measuredOn: '2026-11-02', waistCm: 85, neckCm: 38, hipCm: 98, chestCm: 100, armCm: 35, thighCm: 58 }).expect(200);

      // Validación: vacía, fuera de rango, fecha futura (en la zona del usuario) → 400.
      await put({ measuredOn: '2026-11-03' }).expect(400);
      await put({ measuredOn: '2026-11-03', waistCm: 10 }).expect(400);
      await put({ measuredOn: '2026-11-03', armCm: 81 }).expect(400);
      ctx.clock.set('2026-11-09T23:30:00.000Z'); // ya es 10 de noviembre en Madrid
      await put({ measuredOn: '2026-11-10', weightKg: 79 }).expect(200);
      await put({ measuredOn: '2026-11-11', weightKg: 79 }).expect(400);
    });

    it('registro, tendencia, IMC, % de grasa, perfil y objetivos nutricionales; GET sin escrituras', async () => {
      const u = await registerUser(ctx.app);
      const t = bearer(u.accessToken);
      await grantHealthConsent(ctx.app, u.accessToken);
      await putProfile(ctx.app, u.accessToken, { ...FULL, weightKg: 82, heightCm: 180 });
      const before = (await request(server()).get('/me/nutrition-targets').set(t).expect(200)).body;

      ctx.clock.set('2026-11-30T10:00:00.000Z');
      // 4 semanas bajando ~0,7 %/semana, 2 registros por semana.
      for (let i = 0; i <= 28; i += 3) {
        const date = new Date(Date.UTC(2026, 10, 2) + i * DAY).toISOString().slice(0, 10);
        const weightKg = Math.round(82 * (1 - (0.007 * i) / 7) * 10) / 10;
        await request(server()).put('/me/measurements').set(t).send({ measuredOn: date, weightKg, waistCm: 90 - i * 0.1, neckCm: 38 }).expect(200);
      }
      // Reenvío del mismo día: sustituye, no duplica.
      await request(server()).put('/me/measurements').set(t).send({ measuredOn: '2026-11-29', weightKg: 79.9, waistCm: 87.2, neckCm: 38, armCm: 36 }).expect(200);
      expect(await ctx.prisma.bodyMeasurement.count({ where: { userId: u.id } })).toBe(10);
      // Un peso antiguo no cambia el del perfil; el más reciente sí.
      await request(server()).put('/me/measurements').set(t).send({ measuredOn: '2026-10-01', weightKg: 90, waistCm: 92 }).expect(200);
      const profile = (await request(server()).get('/me/profile').set(t).expect(200)).body;
      expect(profile.weightKg).toBe(79.9);
      const after = (await request(server()).get('/me/nutrition-targets').set(t).expect(200)).body;
      expect(after).not.toEqual(before);

      const list = BodyMeasurementListResponseSchema.parse(
        (await request(server()).get('/me/measurements?from=2026-11-01&to=2026-11-30').set(t).expect(200)).body,
      );
      expect(list.items).toHaveLength(10);
      await request(server()).get('/me/measurements?from=2026-11-30&to=2026-11-01').set(t).expect(400);

      const writes: WriteEvent[] = [];
      const stop = ctx.prisma.onWrite((e) => writes.push(e));
      let body;
      try {
        body = BodyProgressResponseSchema.parse((await request(server()).get('/progress/body').set(t).expect(200)).body);
      } finally {
        stop();
      }
      expect(writes).toEqual([]);
      expect(body.weight.latest).toEqual({ date: '2026-11-29', value: 79.9 });
      expect(body.weight.trend.status).toBe('on_track');
      expect(body.weight.trend.weeklyRatePct!).toBeLessThan(0);
      expect(body.bmi).toMatchObject({ status: 'ok', measuredOn: '2026-11-29' });
      expect(body.bmi.result).toMatchObject({ value: 24.7, category: 'normal' });
      expect(body.bmi.result!.caveats.join(' ')).toMatch(/no distingue músculo de grasa/);
      expect(body.bodyFat.status).toBe('ok');
      expect(body.bodyFat.result!.method).toBe('navy_hodgdon_beckett_1984');
      expect(body.bodyFat.series.length).toBeGreaterThan(1);
      const waist = body.circumferences.find((c) => c.field === 'waistCm')!;
      expect(waist.latest).toEqual({ date: '2026-11-29', value: 87.2 });
      expect(waist.change4w).toBe(-4.8);
      expect(body.circumferences.find((c) => c.field === 'armCm')).toMatchObject({ latest: { value: 36 }, change4w: null });
      expect(body.disclaimer).toMatch(/no un diagnóstico/);

      // Sexo «other»: el % de grasa no aplica.
      await putProfile(ctx.app, u.accessToken, { ...FULL, sex: 'other', weightKg: 79.9, heightCm: 180 });
      const other = BodyProgressResponseSchema.parse((await request(server()).get('/progress/body').set(t).expect(200)).body);
      expect(other.bodyFat.status).toBe('not_applicable');

      // Borrar un día es idempotente.
      await request(server()).delete('/me/measurements/2026-10-01').set(t).expect(200);
      await request(server()).delete('/me/measurements/2026-10-01').set(t).expect(200);
      await request(server()).delete('/me/measurements/2026-13-01').set(t).expect(400);
      expect(await ctx.prisma.bodyMeasurement.count({ where: { userId: u.id } })).toBe(10);
    });

    it('retirar el consentimiento borra el registro de medidas; export y DELETE /me', async () => {
      const u = await registerUser(ctx.app);
      const t = bearer(u.accessToken);
      await grantHealthConsent(ctx.app, u.accessToken);
      await putProfile(ctx.app, u.accessToken, FULL);
      const all = { weightKg: 80, waistCm: 85, neckCm: 38, hipCm: 98, chestCm: 100, armCm: 35, thighCm: 58 };
      await request(server()).put('/me/measurements').set(t).send({ measuredOn: '2026-11-01', ...all }).expect(200);
      const exp = AccountExportSchema.parse((await request(server()).get('/me/export').set(t).expect(200)).body);
      expect(exp.bodyMeasurements).toEqual([expect.objectContaining({ measuredOn: '2026-11-01', ...all })]);

      await request(server()).delete('/me/consents/health').set(t).expect(200);
      expect(await ctx.prisma.bodyMeasurement.count({ where: { userId: u.id } })).toBe(0);
      expect((await request(server()).get('/me/profile').set(t).expect(200)).body.weightKg).toBeNull();
      await request(server()).put('/me/measurements').set(t).send({ measuredOn: '2026-11-02', weightKg: 80 }).expect(409);

      await grantHealthConsent(ctx.app, u.accessToken);
      await request(server()).put('/me/measurements').set(t).send({ measuredOn: '2026-11-02', ...all }).expect(200);
      await request(server()).delete('/me').set(t).send({ password: u.password }).expect(204);
      expect(await ctx.prisma.bodyMeasurement.count({ where: { userId: u.id } })).toBe(0);
    });
  });

  it('DELETE /me borra todo lo nuevo (notas, cambios fijados, pausas, medidas): 0 filas con userId', async () => {
    const { user } = await userWithPlan(ctx.app);
    const t = bearer(user.accessToken);
    await grantHealthConsent(ctx.app, user.accessToken);
    const plan = PlanVersionResponseSchema.parse((await request(server()).get('/plans/current').set(t).expect(200)).body);
    const first = plan.sessions[0].exercises[0];
    await request(server()).put(`/exercises/${first.exerciseId}/note`).set(t).send({ text: 'Agarre ancho', clientUpdatedAt: new Date().toISOString() }).expect(200);
    for (const e of plan.sessions.flatMap((s) => s.exercises)) {
      const subs = await request(server()).get(`/exercises/${e.exerciseId}/substitutes`).set(t).expect(200);
      if (subs.body.substitutes.length === 0) continue;
      await request(server()).put(`/plans/current/exercises/${e.id}/override`).set(t).send({ exerciseId: subs.body.substitutes[0].exerciseId }).expect(200);
      break;
    }
    await request(server()).post('/me/breaks').set(t).send({ clientId: randomUUID(), startsOn: '2026-08-01', endsOn: '2026-08-10' }).expect(201);
    await request(server()).put('/me/measurements').set(t).send({ measuredOn: '2026-11-01', weightKg: 70, waistCm: 80 }).expect(200);
    const exp = AccountExportSchema.parse((await request(server()).get('/me/export').set(t).expect(200)).body);
    expect(exp.exerciseNotes).toHaveLength(1);
    expect(exp.trainingBreaks).toHaveLength(1);
    expect(exp.bodyMeasurements).toHaveLength(1);
    expect(exp.plans[0].versions[0].sessions.flatMap((s) => s.exercises).some((e) => e.pinned !== null)).toBe(true);

    await request(server()).delete('/me').set(t).send({ password: user.password }).expect(204);
    const tables = await ctx.prisma.$queryRaw<{ table_name: string }[]>`
      SELECT table_name FROM information_schema.columns WHERE table_schema = 'public' AND column_name = 'userId'`;
    for (const name of ['UserExerciseNote', 'PlanExerciseOverride', 'TrainingBreak', 'BodyMeasurement']) {
      expect(tables.map((x) => x.table_name)).toContain(name);
    }
    for (const { table_name } of tables) {
      const rows = await ctx.prisma.$queryRawUnsafe<{ n: bigint }[]>(
        `SELECT count(*)::bigint AS n FROM "${table_name}" WHERE "userId" = $1::uuid`,
        user.id,
      );
      expect({ table_name, n: Number(rows[0].n) }).toEqual({ table_name, n: 0 });
    }
  });
});
