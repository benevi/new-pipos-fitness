import request from 'supertest';
import { AccountExportSchema } from '@pipos/contracts';
import { AUDIT_RETENTION_DAYS, AuditService } from '../../modules/audit/audit.service';
import { BEGINNER_GYM, bearer, createTestApp, grantHealthConsent, putProfile, registerUser, truncateAll, type TestContext } from './helpers';

const DAY = 86_400_000;

/** Issue #17: registro de auditoría append-only, sin datos personales ni de salud. */
describe('Registro de auditoría (e2e, Postgres real)', () => {
  let ctx: TestContext;
  const server = () => ctx.app.getHttpServer();
  const events = (userId: string | null) =>
    ctx.prisma.auditEvent.findMany({ where: { userId }, orderBy: { createdAt: 'asc' } }).then((rows) => rows.map((r) => r.type));

  beforeAll(async () => {
    // Sin ventana de gracia: reutilizar un refresh token rotado revoca en el acto.
    ctx = await createTestApp({ REFRESH_REUSE_GRACE_SECONDS: '0' });
  });
  afterAll(async () => {
    await ctx.app.close();
  });
  beforeEach(async () => {
    await truncateAll(ctx.prisma);
  });

  it('logins (sin identificar emails desconocidos) y reutilización de refresh token', async () => {
    const u = await registerUser(ctx.app);
    await request(server()).post('/auth/login').send({ email: 'nadie@example.com', password: 'password123' }).expect(401);
    await request(server()).post('/auth/login').send({ email: u.email, password: 'wrong-password' }).expect(401);
    await request(server()).post('/auth/login').send({ email: u.email, password: u.password }).expect(200);

    const anonymous = await ctx.prisma.auditEvent.findMany({ where: { userId: null } });
    expect(anonymous.map((e) => e.type)).toEqual(['login_failed']);
    // La fila solo tiene tipo, usuario, referencia y fecha: nada del email intentado.
    expect(Object.keys(anonymous[0]).sort()).toEqual(['createdAt', 'id', 'subjectRef', 'type', 'userId']);
    expect(JSON.stringify(await ctx.prisma.auditEvent.findMany())).not.toContain('nadie@example.com');
    expect(await events(u.id)).toEqual(['login_failed', 'login_succeeded']);

    await request(server()).post('/auth/refresh').send({ refreshToken: u.refreshToken }).expect(200);
    const reused = await request(server()).post('/auth/refresh').send({ refreshToken: u.refreshToken }).expect(401);
    expect(reused.body.code).toBe('AUTH_REFRESH_REUSED');
    expect((await events(u.id)).at(-1)).toBe('refresh_reuse_detected');
  });

  it('consentimiento y cambios de datos de salud (solo el tipo), en la exportación', async () => {
    const u = await registerUser(ctx.app);
    const t = bearer(u.accessToken);
    await putProfile(ctx.app, u.accessToken); // sin datos de salud: nada que auditar
    await grantHealthConsent(ctx.app, u.accessToken);
    await putProfile(ctx.app, u.accessToken, { ...BEGINNER_GYM, limitations: ['knee'], weightKg: 81.5 });
    await putProfile(ctx.app, u.accessToken, { ...BEGINNER_GYM, limitations: ['knee'], weightKg: 81.5 }); // igual: nada
    await request(server()).put('/me/measurements').set(t).send({ measuredOn: '2026-11-01', waistCm: 87.3 }).expect(200);
    const del = await request(server()).delete('/me/measurements/2026-11-01').set(t);
    expect(del.status).toBeLessThan(300);
    await request(server()).delete('/me/measurements/2026-11-01').set(t); // ya no existía: nada
    await request(server()).delete('/me/consents/health').set(t).expect(200);

    expect(await events(u.id)).toEqual([
      'health_consent_granted',
      'health_profile_changed',
      'body_measurement_saved',
      'body_measurement_deleted',
      'health_consent_withdrawn',
    ]);
    // Ningún valor de salud en el registro.
    const raw = JSON.stringify(await ctx.prisma.auditEvent.findMany());
    for (const value of ['knee', '81.5', '87.3']) expect(raw).not.toContain(value);

    const exported = AccountExportSchema.parse((await request(server()).get('/me/export').set(t).expect(200)).body);
    expect(exported.auditEvents.map((e) => e.type)).toEqual(await events(u.id));
    expect(Object.keys(exported.auditEvents[0]).sort()).toEqual(['occurredAt', 'type']);
  });

  it('append-only: la base de datos rechaza modificar un evento', async () => {
    const u = await registerUser(ctx.app);
    await request(server()).post('/auth/login').send({ email: u.email, password: u.password }).expect(200);
    const [row] = await ctx.prisma.auditEvent.findMany({ where: { userId: u.id } });
    await expect(ctx.prisma.auditEvent.update({ where: { id: row.id }, data: { type: 'login_failed' } })).rejects.toThrow(/append-only/);
  });

  it('borrar la cuenta borra sus eventos y deja solo account_deleted sin userId', async () => {
    const u = await registerUser(ctx.app);
    const other = await registerUser(ctx.app);
    await request(server()).post('/auth/login').send({ email: u.email, password: u.password }).expect(200);
    await request(server()).post('/auth/login').send({ email: other.email, password: other.password }).expect(200);
    await request(server()).delete('/me').set(bearer(u.accessToken)).send({ password: u.password }).expect(204);

    expect(await ctx.prisma.auditEvent.count({ where: { userId: u.id } })).toBe(0);
    const deleted = await ctx.prisma.auditEvent.findMany({ where: { type: 'account_deleted' } });
    expect(deleted).toHaveLength(1);
    expect(deleted[0].userId).toBeNull();
    expect(deleted[0].subjectRef).toEqual(expect.any(String));
    expect(deleted[0].subjectRef).not.toBe(u.id);
    expect(JSON.stringify(await ctx.prisma.auditEvent.findMany())).not.toContain(u.id);
    // Los del otro usuario siguen.
    expect(await events(other.id)).toEqual(['login_succeeded']);
  });

  it(`retención: la limpieza borra solo lo anterior a ${AUDIT_RETENTION_DAYS} días`, async () => {
    const u = await registerUser(ctx.app);
    const now = new Date();
    await ctx.prisma.auditEvent.createMany({
      data: [
        { type: 'login_succeeded', userId: u.id, createdAt: new Date(now.getTime() - (AUDIT_RETENTION_DAYS + 1) * DAY) },
        { type: 'login_failed', userId: null, createdAt: new Date(now.getTime() - (AUDIT_RETENTION_DAYS + 30) * DAY) },
        { type: 'login_succeeded', userId: u.id, createdAt: new Date(now.getTime() - (AUDIT_RETENTION_DAYS - 1) * DAY) },
      ],
    });
    expect(await ctx.app.get(AuditService).cleanup(now)).toBe(2);
    expect(await ctx.prisma.auditEvent.count()).toBe(1);
  });
});
