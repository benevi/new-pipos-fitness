import request from 'supertest';
import { vi } from 'vitest';
import { CatalogService } from '../../modules/catalog/catalog.service';
import { HEALTH_CONSENT_POLICY } from '@pipos/contracts';
import {
  BEGINNER_GYM,
  bearer,
  createTestApp,
  grantHealthConsent,
  putProfile,
  registerUser,
  truncateAll,
  setBody,
  startToday,
  type TestContext,
} from './helpers';

describe('Perfil, consentimiento de salud y nutrición (e2e, Postgres real)', () => {
  let ctx: TestContext;
  const server = () => ctx.app.getHttpServer();

  beforeAll(async () => {
    ctx = await createTestApp();
  });
  beforeEach(async () => {
    await truncateAll(ctx.prisma);
  });
  afterAll(async () => {
    await ctx.app.close();
  });

  it('sin consentimiento, los datos de salud se rechazan con 409 HEALTH_CONSENT_REQUIRED y no se guarda nada', async () => {
    const u = await registerUser(ctx.app);
    const res = await request(server())
      .put('/me/profile')
      .set(bearer(u.accessToken))
      .send({ ...BEGINNER_GYM, limitations: ['knee'], weightKg: 80 })
      .expect(409);
    expect(res.body.code).toBe('HEALTH_CONSENT_REQUIRED');
    expect(res.body.issues.map((i: { path: string }) => i.path).sort()).toEqual(['body.limitations', 'body.weightKg']);
    expect(await ctx.prisma.trainingProfile.count()).toBe(0);
    // Sin datos de salud el perfil es plenamente usable.
    const ok = await putProfile(ctx.app, u.accessToken, { ...BEGINNER_GYM, birthYear: 1995, sex: 'female' });
    expect(ok.body.profile.healthConsent.granted).toBe(false);
  });

  it('minimización: ni ConsentEvent ni RefreshToken guardan IP ni user-agent', async () => {
    const cols = await ctx.prisma.$queryRaw<{ table_name: string; column_name: string }[]>`
      SELECT table_name, column_name FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name IN ('ConsentEvent', 'RefreshToken')`;
    const names = cols.map((c) => `${c.table_name}.${c.column_name}`);
    expect(names).toContain('ConsentEvent.textHash');
    expect(names.filter((n) => /\.(ip|userAgent|createdByIp)$/.test(n))).toEqual([]);
  });

  it('consentimiento: versión equivocada → 422; concedido es idempotente y queda registrado con el hash del texto', async () => {
    const u = await registerUser(ctx.app);
    const bad = await request(server()).post('/me/consents/health').set(bearer(u.accessToken)).send({ version: 'v0' }).expect(422);
    expect(bad.body.code).toBe('HEALTH_CONSENT_VERSION_MISMATCH');
    await grantHealthConsent(ctx.app, u.accessToken);
    await grantHealthConsent(ctx.app, u.accessToken);
    const status = await request(server()).get('/me/consents/health').set(bearer(u.accessToken)).expect(200);
    expect(status.body).toMatchObject({ granted: true, version: HEALTH_CONSENT_POLICY.version });
    const events = await ctx.prisma.consentEvent.findMany({ where: { userId: u.id } });
    expect(events).toHaveLength(1);
    expect(events[0].textHash).toMatch(/^[0-9a-f]{64}$/);
  });

  it('retirar el consentimiento borra los datos de salud, redacta instantáneas y regenera el plan sin ellos', async () => {
    const u = await registerUser(ctx.app);
    await grantHealthConsent(ctx.app, u.accessToken);
    await putProfile(ctx.app, u.accessToken, { ...BEGINNER_GYM, limitations: ['knee'], weightKg: 82.5, heightCm: 180 });
    const v1 = await request(server()).post('/plans/generate').set(bearer(u.accessToken)).expect(201);

    const res = await request(server()).delete('/me/consents/health').set(bearer(u.accessToken)).expect(200);
    expect(res.body.healthConsent.granted).toBe(false);
    expect(res.body.planVersion.version).toBe(2);

    const profile = await request(server()).get('/me/profile').set(bearer(u.accessToken)).expect(200);
    expect(profile.body).toMatchObject({ limitations: [], weightKg: null, heightCm: null });
    const old = await ctx.prisma.planVersion.findUniqueOrThrow({ where: { id: v1.body.id } });
    const snapshot = old.inputSnapshot as Record<string, unknown>;
    expect(snapshot.redacted).toBe(true);
    expect(snapshot.limitations).toBeUndefined();
    expect(JSON.stringify(snapshot)).not.toContain('82.5');
    const v2 = await ctx.prisma.planVersion.findUniqueOrThrow({ where: { id: res.body.planVersion.id } });
    expect((v2.inputSnapshot as Record<string, unknown>).limitations).toEqual([]);
    // Historial append-only: concedido + retirado.
    expect(await ctx.prisma.consentEvent.count({ where: { userId: u.id } })).toBe(2);
  });

  it('retirar el consentimiento borra la zona limitada de las explicaciones guardadas (versión antigua y export)', async () => {
    const ZONE_TEXT = /rodilla|limitaci/i;
    const u = await registerUser(ctx.app);
    await grantHealthConsent(ctx.app, u.accessToken);
    // Limitación de rodilla + un patrón que solo admite variantes de riesgo para la rodilla.
    await putProfile(ctx.app, u.accessToken, { ...BEGINNER_GYM, limitations: ['knee'] });
    const v1 = await request(server()).post('/plans/generate').set(bearer(u.accessToken)).expect(201);
    // Antes de retirar: la explicación del plan sí menciona la rodilla (control positivo).
    expect(JSON.stringify(v1.body)).toMatch(ZONE_TEXT);

    await request(server()).delete('/me/consents/health').set(bearer(u.accessToken)).expect(200);

    const old = await request(server()).get(`/plans/versions/${v1.body.id}`).set(bearer(u.accessToken)).expect(200);
    expect(JSON.stringify(old.body)).not.toMatch(ZONE_TEXT);
    expect(old.body.rationale.length).toBeGreaterThan(0); // el resto de la explicación se conserva
    const exported = await request(server()).get('/me/export').set(bearer(u.accessToken)).expect(200);
    expect(JSON.stringify(exported.body.plans)).not.toMatch(ZONE_TEXT);
    // Ni rastro en BD (incluidas las explicaciones de cada ejercicio).
    const rows = await ctx.prisma.planVersion.findMany({ where: { userId: u.id }, include: { sessions: { include: { exercises: true } } } });
    expect(JSON.stringify(rows)).not.toMatch(ZONE_TEXT);
  });

  it('carrera: si el consentimiento se retira mientras se guarda el perfil, no se guardan datos de salud', async () => {
    const u = await registerUser(ctx.app);
    await grantHealthConsent(ctx.app, u.accessToken);
    await putProfile(ctx.app, u.accessToken, BEGINNER_GYM);
    const catalog = ctx.app.get(CatalogService);
    const original = catalog.engineCatalog.bind(catalog);
    // La retirada llega justo después de la comprobación optimista y antes de la transacción.
    const spy = vi.spyOn(catalog, 'engineCatalog').mockImplementationOnce(async () => {
      await request(server()).delete('/me/consents/health').set(bearer(u.accessToken)).expect(200);
      return original();
    });
    try {
      const res = await request(server())
        .put('/me/profile')
        .set(bearer(u.accessToken))
        .send({ ...BEGINNER_GYM, limitations: ['knee'], weightKg: 80 })
        .expect(409);
      expect(res.body.code).toBe('HEALTH_CONSENT_REQUIRED');
    } finally {
      spy.mockRestore();
    }
    const row = await ctx.prisma.trainingProfile.findUniqueOrThrow({ where: { userId: u.id } });
    expect(row.limitations).toEqual([]);
    expect(row.weightKg).toBeNull();
  });

  it('cambiar la zona horaria reconstruye la analítica semanal en la misma operación', async () => {
    const u = await registerUser(ctx.app);
    await putProfile(ctx.app, u.accessToken, BEGINNER_GYM); // Europe/Madrid
    await request(server()).post('/plans/generate').set(bearer(u.accessToken)).expect(201);
    // Lunes 02:00 UTC: lunes en Madrid (semana del 9), domingo en Nueva York (semana del 2).
    const startedAt = '2026-11-09T02:00:00.000Z';
    const { today, workout } = await startToday(ctx.app, u.accessToken, startedAt);
    await request(server())
      .post(`/workouts/${workout.id}/sets`)
      .set(bearer(u.accessToken))
      .send(setBody(today.exercises[0], { completedAt: '2026-11-09T02:05:00.000Z' }))
      .expect(201);
    const weeks = async () =>
      [...new Set((await ctx.prisma.weeklyMuscleVolume.findMany({ where: { userId: u.id } })).map((r) => r.weekStart.toISOString().slice(0, 10)))];
    expect(await weeks()).toEqual(['2026-11-09']);

    await putProfile(ctx.app, u.accessToken, { ...BEGINNER_GYM, timezone: 'America/New_York' });
    expect(await weeks()).toEqual(['2026-11-02']);
    const adherence = await ctx.prisma.weeklyAdherence.findMany({ where: { userId: u.id } });
    expect(adherence.map((r) => r.weekStart.toISOString().slice(0, 10))).toEqual(['2026-11-02']);
  });

  it('PUT /me/profile: valida con issues por campo y rechaza ejercicios desconocidos con 422', async () => {
    const u = await registerUser(ctx.app);
    const invalid = await request(server()).put('/me/profile').set(bearer(u.accessToken))
      .send({ ...BEGINNER_GYM, daysPerWeek: 9, timezone: 'Mars/Olympus' }).expect(400);
    expect(invalid.body.issues.map((i: { path: string }) => i.path).sort()).toEqual(['body.daysPerWeek', 'body.timezone']);
    const unknown = await request(server()).put('/me/profile').set(bearer(u.accessToken))
      .send({ ...BEGINNER_GYM, bannedExerciseSlugs: ['no-existe'] }).expect(422);
    expect(unknown.body.code).toBe('UNKNOWN_EXERCISE');
    const ok = await putProfile(ctx.app, u.accessToken, { ...BEGINNER_GYM, bannedExerciseSlugs: ['sentadilla-trasera-barra'] });
    expect(ok.body.profile.bannedExerciseSlugs).toEqual(['sentadilla-trasera-barra']);
    const plan = await request(server()).post('/plans/generate').set(bearer(u.accessToken)).expect(201);
    const slugs = plan.body.sessions.flatMap((s: { exercises: { slug: string }[] }) => s.exercises.map((e) => e.slug));
    expect(slugs).not.toContain('sentadilla-trasera-barra');
  });

  it('GET /me/nutrition-targets: 422 con los campos que faltan; 200 con el perfil completo', async () => {
    const u = await registerUser(ctx.app);
    await putProfile(ctx.app, u.accessToken, BEGINNER_GYM);
    const missing = await request(server()).get('/me/nutrition-targets').set(bearer(u.accessToken)).expect(422);
    expect(missing.body.code).toBe('NUTRITION_INPUT_INCOMPLETE');
    expect(missing.body.issues.map((i: { path: string }) => i.path).sort()).toEqual(['activityLevel', 'birthYear', 'healthConsent', 'sex']);

    await grantHealthConsent(ctx.app, u.accessToken);
    await putProfile(ctx.app, u.accessToken, {
      ...BEGINNER_GYM,
      goal: 'fat_loss',
      birthYear: 1994,
      sex: 'female',
      activityLevel: 'active',
      weightKg: 65,
      heightCm: 168,
    });
    const ok = await request(server()).get('/me/nutrition-targets').set(bearer(u.accessToken)).expect(200);
    expect(ok.body.nutritionGoal).toBe('fat_loss');
    expect(ok.body.kcal).toBeGreaterThan(1000);
    expect(ok.body.proteinG).toBeGreaterThan(0);
    expect(ok.body.adjustmentKcal).toBeLessThan(0);
  });
});
