import request from 'supertest';
import { randomUUID } from 'crypto';
import { loadCatalog } from '@pipos/catalog';
import { groupFractions, PROGRAMMING } from '@pipos/engine-rules';
import {
  AccountExportSchema,
  PlanVersionResponseSchema,
  TodaySessionResponseSchema,
  type PlanVersionResponse,
  type TodayExercise,
} from '@pipos/contracts';
import {
  BEGINNER_GYM,
  HOME_INTERMEDIATE,
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

const catalog = new Map(loadCatalog().map((e) => [e.slug, e]));
const DAY = 86_400_000;

/** Registra todas las series prescritas de un ejercicio en el techo del rango con RIR objetivo. */
async function logTopSets(ctx: TestContext, token: string, workoutId: string, ex: TodayExercise, loadKg: number, at: Date) {
  for (let i = 0; i < ex.prescription.sets; i++) {
    await request(ctx.app.getHttpServer())
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

async function finish(ctx: TestContext, token: string, workoutId: string, at: Date) {
  return request(ctx.app.getHttpServer())
    .post(`/workouts/${workoutId}/finish`)
    .set(bearer(token))
    .send({ completedAt: new Date(at.getTime() + 3_600_000).toISOString() })
    .expect(200);
}

/** Hace la sesión de hoy entera (sin series) en la fecha `at`. */
async function doSession(ctx: TestContext, token: string, at: Date) {
  const { today, workout } = await startToday(ctx.app, token, at.toISOString());
  await finish(ctx, token, workout.id, at);
  return today;
}

describe('CUJ-1..8 (e2e, Postgres real)', () => {
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

  it('CUJ-1: registro → consentimiento → perfil con limitación → plan válido y explicado', async () => {
    const u = await registerUser(ctx.app);
    await grantHealthConsent(ctx.app, u.accessToken);
    const profile = { ...HOME_INTERMEDIATE, limitations: ['shoulder' as const], weightKg: 78, heightCm: 178, birthYear: 1990, sex: 'male' as const };
    await putProfile(ctx.app, u.accessToken, profile);
    const started = Date.now();
    const res = await request(server()).post('/plans/generate').set(bearer(u.accessToken)).expect(201);
    expect(Date.now() - started).toBeLessThan(3000);
    const plan: PlanVersionResponse = PlanVersionResponseSchema.parse(res.body);

    expect(plan.version).toBe(1);
    expect(plan.sessions).toHaveLength(profile.daysPerWeek);
    expect(plan.rationale.length).toBeGreaterThan(0);
    expect(plan.split.rationale.length).toBeGreaterThan(0);
    const allowed = new Set<string>([...profile.equipment, 'bodyweight']);
    for (const s of plan.sessions) {
      expect(s.rationale.length).toBeGreaterThan(0);
      expect(s.exercises.map((e) => e.order)).toEqual(s.exercises.map((_, i) => i));
      for (const e of s.exercises) {
        const src = catalog.get(e.slug)!;
        expect(src.equipment.every((eq) => allowed.has(eq))).toBe(true);
        // Limitación de hombro: ningún ejercicio marcado «avoid» para el hombro.
        expect(src.riskTags.some((r) => r.zone === 'shoulder' && r.level === 'avoid')).toBe(false);
        expect(e.rationale.length).toBeGreaterThan(0);
      }
    }
    // La instantánea guarda el perfil usado (con datos de salud, porque hay consentimiento).
    const row = await ctx.prisma.planVersion.findUniqueOrThrow({ where: { id: plan.id } });
    expect(row.inputSnapshot).toMatchObject({ limitations: ['shoulder'], body: { weightKg: 78 } });
    await request(server()).get('/plans/current').set(bearer(u.accessToken)).expect(200);
  });

  it('CUJ-2: entrenar hoy — calentamiento, prescripción, registro idempotente y sesión siguiente', async () => {
    const { user } = await userWithPlan(ctx.app);
    const todayRes = await request(server()).get('/sessions/today').set(bearer(user.accessToken)).expect(200);
    const today = TodaySessionResponseSchema.parse(todayRes.body);
    expect(today.order).toBe(0);
    expect(today.generalWarmupMinutes).toBeGreaterThan(0);
    expect(today.exercises.length).toBeGreaterThan(0);
    for (const e of today.exercises) {
      expect(e.prescription.sets).toBeGreaterThan(0);
      expect(e.prescription.repMin).toBeLessThanOrEqual(e.prescription.repMax);
      expect(e.restSeconds).toBeGreaterThan(0);
    }

    const { workout } = await startToday(ctx.app, user.accessToken);
    const ex = today.exercises[0];
    const body = setBody(ex, { reps: 8, loadKg: 30 });
    const first = await request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(user.accessToken)).send(body).expect(201);
    // Reenvío (sin red, la cola reintenta): 200 y la misma fila.
    const again = await request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(user.accessToken)).send(body).expect(200);
    expect(again.body.id).toBe(first.body.id);
    expect(await ctx.prisma.setLog.count({ where: { userId: user.id } })).toBe(1);

    const during = await request(server()).get('/sessions/today').set(bearer(user.accessToken)).expect(200);
    expect(during.body.workout.id).toBe(workout.id);
    expect(during.body.exercises[0].loggedSets).toHaveLength(1);

    await finish(ctx, user.accessToken, workout.id, new Date());
    const next = await request(server()).get('/sessions/today').set(bearer(user.accessToken)).expect(200);
    expect(next.body.order).toBe(1);
    expect(next.body.workout).toBeNull();
  });

  it('CUJ-3: dos sesiones encadenadas — techo del rango con RIR objetivo → sube la carga y lo explica', async () => {
    const { user } = await userWithPlan(ctx.app);
    const t0 = new Date(Date.now() - 6 * DAY);
    const { today, workout } = await startToday(ctx.app, user.accessToken, t0.toISOString());
    const ex = today.exercises.find((e: TodayExercise) => e.loadType === 'weighted')!;
    expect(ex).toBeDefined();
    await logTopSets(ctx, user.accessToken, workout.id, ex, 40, t0);
    await finish(ctx, user.accessToken, workout.id, t0);
    // Resto del microciclo, hasta volver a la sesión 0.
    await doSession(ctx, user.accessToken, new Date(t0.getTime() + 2 * DAY));
    await doSession(ctx, user.accessToken, new Date(t0.getTime() + 4 * DAY));

    const again = await request(server()).get('/sessions/today').set(bearer(user.accessToken)).expect(200);
    expect(again.body.order).toBe(0);
    const same = again.body.exercises.find((e: TodayExercise) => e.exercise.id === ex.exercise.id);
    expect(same.prescription.action).toBe('increase_load');
    expect(same.prescription.loadKg).toBeGreaterThan(40);
    expect(same.prescription.rationale.join(' ')).toMatch(/subimos/i);
    // El calentamiento se calcula sobre la carga nueva.
    for (const w of same.warmupSets) expect(w.loadKg).toBeLessThanOrEqual(same.prescription.loadKg);
  });

  it('CUJ-4: cambiar un ejercicio — 3 alternativas válidas, el cambio se ve en la sesión y en el historial', async () => {
    const { user } = await userWithPlan(ctx.app);
    const { today, workout } = await startToday(ctx.app, user.accessToken);
    const slot: TodayExercise = today.exercises[0];
    const subs = await request(server()).get(`/exercises/${slot.exercise.id}/substitutes`).set(bearer(user.accessToken)).expect(200);
    expect(subs.body.substitutes.length).toBeGreaterThan(0);
    expect(subs.body.substitutes.length).toBeLessThanOrEqual(3);
    const allowed = new Set<string>([...BEGINNER_GYM.equipment, 'bodyweight']);
    const original = catalog.get(slot.exercise.slug)!;
    for (const s of subs.body.substitutes) {
      expect(s.exerciseId).not.toBe(slot.exercise.id);
      const src = catalog.get(s.slug)!;
      expect(src.equipment.every((eq) => allowed.has(eq))).toBe(true);
      expect(src.substitutionGroup === original.substitutionGroup || src.movementPattern === original.movementPattern).toBe(true);
    }
    const pick = subs.body.substitutes[0];
    const t = Date.now();
    const swap = await request(server())
      .post(`/workouts/${workout.id}/exercises/${slot.planExerciseId}/substitute`)
      .set(bearer(user.accessToken))
      .send({ exerciseId: pick.exerciseId })
      .expect(200);
    expect(Date.now() - t).toBeLessThan(10_000);
    expect(swap.body.substitutedFrom.id).toBe(slot.exercise.id);

    const view = await request(server()).get('/sessions/today').set(bearer(user.accessToken)).expect(200);
    const changed = view.body.exercises.find((e: TodayExercise) => e.planExerciseId === slot.planExerciseId);
    expect(changed.exercise.id).toBe(pick.exerciseId);
    expect(changed.substitutedFrom.id).toBe(slot.exercise.id);

    await request(server())
      .post(`/workouts/${workout.id}/sets`)
      .set(bearer(user.accessToken))
      .send(setBody(changed, { reps: 10, loadKg: 20 }))
      .expect(201);
    const w = await request(server()).get(`/workouts/${workout.id}`).set(bearer(user.accessToken)).expect(200);
    expect(w.body.substitutions).toHaveLength(1);
    expect(w.body.sets[0].exerciseId).toBe(pick.exerciseId);

    // Un ejercicio que no es alternativa válida → 400.
    const bad = loadCatalog().find((e) => e.movementPattern !== original.movementPattern && e.substitutionGroup !== original.substitutionGroup)!;
    const badRow = await ctx.prisma.exercise.findUniqueOrThrow({ where: { slug: bad.slug } });
    await request(server())
      .post(`/workouts/${workout.id}/exercises/${slot.planExerciseId}/substitute`)
      .set(bearer(user.accessToken))
      .send({ exerciseId: badRow.id })
      .expect(400);
  });

  it('CUJ-5: faltar y volver — sigue por la siguiente sesión pendiente y, tras 14+ días, baja la carga', async () => {
    const { user } = await userWithPlan(ctx.app);
    const t0 = new Date(Date.now() - 30 * DAY);
    ctx.clock.set(t0);
    const { today, workout } = await startToday(ctx.app, user.accessToken, t0.toISOString());
    const ex = today.exercises.find((e: TodayExercise) => e.loadType === 'weighted')!;
    await logTopSets(ctx, user.accessToken, workout.id, ex, 50, t0);
    await finish(ctx, user.accessToken, workout.id, t0);

    // 10 días sin entrenar: no se salta ninguna sesión.
    ctx.clock.set(new Date(t0.getTime() + 10 * DAY));
    const afterGap = await request(server()).get('/sessions/today').set(bearer(user.accessToken)).expect(200);
    expect(afterGap.body.order).toBe(1);
    await doSession(ctx, user.accessToken, new Date(t0.getTime() + 10 * DAY));
    await doSession(ctx, user.accessToken, new Date(t0.getTime() + 11 * DAY));

    // Vuelve a la sesión 0 con 20+ días desde la última vez que hizo el ejercicio.
    ctx.clock.set(null);
    const back = await request(server()).get('/sessions/today').set(bearer(user.accessToken)).expect(200);
    expect(back.body.order).toBe(0);
    const same = back.body.exercises.find((e: TodayExercise) => e.exercise.id === ex.exercise.id);
    expect(same.prescription.action).toBe('return_after_break');
    expect(same.prescription.loadKg).toBeLessThan(50);
    expect(same.prescription.rationale.join(' ')).toMatch(/días sin hacer/);
  });

  it('CUJ-6: cambiar perfil → nueva versión; la anterior sigue consultable y el historial intacto', async () => {
    const { user, plan } = await userWithPlan(ctx.app);
    const { today, workout } = await startToday(ctx.app, user.accessToken);
    await request(server())
      .post(`/workouts/${workout.id}/sets`)
      .set(bearer(user.accessToken))
      .send(setBody(today.exercises[0], { reps: 8, loadKg: 30 }))
      .expect(201);
    await finish(ctx, user.accessToken, workout.id, new Date());

    const changed = await putProfile(ctx.app, user.accessToken, { ...BEGINNER_GYM, equipment: ['dumbbell', 'bench'], minutesPerSession: 60 });
    expect(changed.body.planVersion.version).toBe(2);
    // Sin cambios relevantes (solo zona horaria) no se crea versión.
    const same = await putProfile(ctx.app, user.accessToken, { ...BEGINNER_GYM, equipment: ['dumbbell', 'bench'], minutesPerSession: 60, timezone: 'Europe/Lisbon' });
    expect(same.body.planVersion).toBeNull();

    const versions = await request(server()).get('/plans/versions').set(bearer(user.accessToken)).expect(200);
    expect(versions.body.total).toBe(2);
    expect(versions.body.items.map((v: { version: number }) => v.version)).toEqual([2, 1]);
    const old = await request(server()).get(`/plans/versions/${plan.id}`).set(bearer(user.accessToken)).expect(200);
    expect(old.body).toEqual(plan);
    const current = await request(server()).get('/plans/current').set(bearer(user.accessToken)).expect(200);
    expect(current.body.version).toBe(2);
    expect(await ctx.prisma.setLog.count({ where: { userId: user.id } })).toBe(1);
    expect(await ctx.prisma.exerciseE1rm.count({ where: { userId: user.id } })).toBe(1);
  });

  it('CUJ-7: ver progreso — e1RM, volumen semanal frente al objetivo y adherencia (calculados al escribir)', async () => {
    const { user } = await userWithPlan(ctx.app);
    const { today, workout } = await startToday(ctx.app, user.accessToken);
    const ex = today.exercises.find((e: TodayExercise) => e.loadType === 'weighted')!;
    for (let i = 0; i < ex.prescription.sets; i++) {
      await request(server())
        .post(`/workouts/${workout.id}/sets`)
        .set(bearer(user.accessToken))
        .send(setBody(ex, { setIndex: i, reps: 8, loadKg: 40, rir: 2 }))
        .expect(201);
    }
    // Calentamiento: no cuenta para e1RM ni volumen.
    await request(server())
      .post(`/workouts/${workout.id}/sets`)
      .set(bearer(user.accessToken))
      .send({ ...setBody(ex, { setIndex: 9, reps: 5, loadKg: 20 }), isWarmup: true })
      .expect(201);
    await finish(ctx, user.accessToken, workout.id, new Date());

    const e1rm = await request(server()).get('/progress/e1rm').set(bearer(user.accessToken)).expect(200);
    const series = e1rm.body.series.find((s: { exerciseId: string }) => s.exerciseId === ex.exercise.id);
    expect(series.points).toHaveLength(1);
    // Epley con RIR: 40 × (1 + (8 + 2) / 30).
    expect(series.latestE1rmKg).toBeCloseTo(40 * (1 + 10 / 30), 1);

    const volume = await request(server()).get('/progress/volume?weeks=2').set(bearer(user.accessToken)).expect(200);
    expect(volume.body.weeks).toHaveLength(2);
    const week = volume.body.weeks[1];
    const primary = catalog.get(ex.exercise.slug)!.muscles.find((m) => m.role === 'primary')!;
    const mv = week.muscles.find((m: { muscle: string }) => m.muscle === primary.muscle);
    expect(mv.effectiveSets).toBeCloseTo(ex.prescription.sets, 5);
    expect(week.groups.some((g: { targetMin: number | null }) => g.targetMin !== null)).toBe(true);
    // Volumen por grupo contado como el motor: máxima fracción por ejercicio y grupo (§16.1).
    for (const [group, fraction] of groupFractions(catalog.get(ex.exercise.slug)!.muscles, PROGRAMMING)) {
      const gv = week.groups.find((g: { group: string }) => g.group === group);
      expect(gv.effectiveSets, group).toBeCloseTo(fraction * ex.prescription.sets, 5);
    }

    const adherence = await request(server()).get('/progress/adherence?weeks=1').set(bearer(user.accessToken)).expect(200);
    expect(adherence.body.weeks[0]).toMatchObject({ plannedSessions: 3, completedSessions: 1, completedSets: ex.prescription.sets });
  });

  it('CUJ-8: exportar todo y borrar la cuenta — 0 filas del usuario y tokens inválidos', async () => {
    const u = await registerUser(ctx.app);
    await grantHealthConsent(ctx.app, u.accessToken);
    await putProfile(ctx.app, u.accessToken, { ...BEGINNER_GYM, weightKg: 70, limitations: ['knee'] });
    await request(server()).post('/plans/generate').set(bearer(u.accessToken)).expect(201);
    const { today, workout } = await startToday(ctx.app, u.accessToken);
    await request(server())
      .post(`/workouts/${workout.id}/sets`)
      .set(bearer(u.accessToken))
      .send(setBody(today.exercises[0], { reps: 8, loadKg: 30 }))
      .expect(201);

    const exp = await request(server()).get('/me/export').set(bearer(u.accessToken)).expect(200);
    const data = AccountExportSchema.parse(exp.body);
    expect(data.user.email).toBe(u.email);
    expect(data.profile?.weightKg).toBe(70);
    expect(data.consentEvents).toHaveLength(1);
    expect(data.plans[0].versions).toHaveLength(1);
    expect(data.workouts[0].sets).toHaveLength(1);
    expect(data.analytics.weeklyAdherence.length).toBeGreaterThan(0);
    expect(JSON.stringify(exp.body)).not.toMatch(/passwordHash|tokenHash|\$2b\$/);

    await request(server()).delete('/me').set(bearer(u.accessToken)).send({ password: 'wrong-password' }).expect(403);
    await request(server()).delete('/me').set(bearer(u.accessToken)).send({ password: u.password }).expect(204);

    const tables = await ctx.prisma.$queryRaw<{ table_name: string }[]>`
      SELECT table_name FROM information_schema.columns
      WHERE table_schema = 'public' AND column_name = 'userId'`;
    expect(tables.length).toBeGreaterThan(10);
    for (const { table_name } of tables) {
      const rows = await ctx.prisma.$queryRawUnsafe<{ n: bigint }[]>(
        `SELECT count(*)::bigint AS n FROM "${table_name}" WHERE "userId" = $1::uuid`,
        u.id,
      );
      expect({ table_name, n: Number(rows[0].n) }).toEqual({ table_name, n: 0 });
    }
    expect(await ctx.prisma.user.count({ where: { id: u.id } })).toBe(0);
    await request(server()).get('/me').set(bearer(u.accessToken)).expect(401);
    await request(server()).post('/auth/refresh').send({ refreshToken: u.refreshToken }).expect(401);
    // El catálogo no se ve afectado.
    expect(await ctx.prisma.exercise.count()).toBe(loadCatalog().length);
  });

  it('sin perfil ni plan: códigos claros', async () => {
    const u = await registerUser(ctx.app);
    expect((await request(server()).get('/me/profile').set(bearer(u.accessToken)).expect(404)).body.code).toBe('PROFILE_REQUIRED');
    expect((await request(server()).post('/plans/generate').set(bearer(u.accessToken)).expect(409)).body.code).toBe('PROFILE_REQUIRED');
    await putProfile(ctx.app, u.accessToken);
    expect((await request(server()).get('/plans/current').set(bearer(u.accessToken)).expect(404)).body.code).toBe('PLAN_REQUIRED');
    expect((await request(server()).get('/sessions/today').set(bearer(u.accessToken)).expect(404)).body.code).toBe('PLAN_REQUIRED');
    const startBad = await request(server())
      .post('/workouts')
      .set(bearer(u.accessToken))
      .send({ clientId: randomUUID(), planSessionId: randomUUID(), startedAt: new Date().toISOString() })
      .expect(404);
    expect(startBad.body.code).toBe('NOT_FOUND');
  });
});
