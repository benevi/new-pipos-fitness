import request from 'supertest';
import { randomUUID } from 'crypto';
import { loadCatalog } from '@pipos/catalog';
import { FEATURE_MODULES } from '../../app.module';
import { setLogSink } from '../../logging/logging';
import { collectRoutes } from '../../openapi/openapi';
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
  type TestContext,
} from './helpers';

describe('Observabilidad, GET sin escrituras y catálogo (e2e, Postgres real)', () => {
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

  it('ningún GET ejecuta escrituras (ADR-0008), recorriendo TODAS las rutas GET', async () => {
    const u = await registerUser(ctx.app);
    await grantHealthConsent(ctx.app, u.accessToken);
    await putProfile(ctx.app, u.accessToken, {
      ...BEGINNER_GYM, birthYear: 1990, sex: 'male', activityLevel: 'active', weightKg: 80, heightCm: 180,
    });
    const plan = await request(server()).post('/plans/generate').set(bearer(u.accessToken)).expect(201);
    const { today, workout } = await startToday(ctx.app, u.accessToken);
    await request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(u.accessToken)).send(setBody(today.exercises[0])).expect(201);
    // Datos de ADR-0013 para que sus GET lean filas reales.
    await request(server())
      .put(`/exercises/${today.exercises[0].exercise.id}/note`)
      .set(bearer(u.accessToken))
      .send({ text: 'Asiento en el 4', clientUpdatedAt: new Date().toISOString() })
      .expect(200);
    await request(server()).patch('/me/profile/schedule').set(bearer(u.accessToken)).send({ trainingWeekdays: [1, 3, 5] }).expect(200);
    await request(server())
      .post('/me/breaks')
      .set(bearer(u.accessToken))
      .send({ clientId: randomUUID(), startsOn: '2026-08-01', endsOn: '2026-08-15' })
      .expect(201);
    await request(server())
      .put('/me/measurements')
      .set(bearer(u.accessToken))
      .send({ measuredOn: '2026-08-01', weightKg: 80, waistCm: 85, neckCm: 38 })
      .expect(200);

    const ids: Record<string, string> = {
      '/exercises/:id': today.exercises[0].exercise.id,
      '/exercises/:id/substitutes': today.exercises[0].exercise.id,
      '/plans/versions/:id': plan.body.id,
      '/workouts/:id': workout.id,
    };
    const writes: WriteEvent[] = [];
    const stop = ctx.prisma.onWrite((e) => writes.push(e));
    try {
      const gets = collectRoutes(FEATURE_MODULES).filter((r) => r.method === 'get');
      expect(gets.length).toBeGreaterThanOrEqual(15);
      for (const route of gets) {
        const url = route.path.includes(':') ? route.path.replace(':id', ids[route.path]) : route.path;
        const res = await request(server()).get(url).set(bearer(u.accessToken));
        expect({ url, status: res.status }).toEqual({ url, status: 200 });
      }
      expect(writes).toEqual([]);
      // Control: una escritura sí se observa.
      await request(server()).post(`/workouts/${workout.id}/sets`).set(bearer(u.accessToken)).send(setBody(today.exercises[0], { setIndex: 1 })).expect(201);
      expect(writes.length).toBeGreaterThan(0);
    } finally {
      stop();
    }
  });

  it('logs JSON con requestId y sin PII ni datos de salud', async () => {
    const lines: string[] = [];
    const restore = setLogSink((l) => lines.push(l));
    const prevLevel = process.env.LOG_LEVEL;
    process.env.LOG_LEVEL = 'debug';
    try {
      const email = 'pii-check@example.com';
      const u = await registerUser(ctx.app, email, 'secret-password-123');
      await grantHealthConsent(ctx.app, u.accessToken);
      await request(server())
        .put('/me/profile?weight=93.7')
        .set(bearer(u.accessToken))
        .set('X-Request-Id', 'test-request-0001')
        .send({ ...BEGINNER_GYM, weightKg: 93.7, heightCm: 187.3, limitations: ['lumbar'], birthYear: 1977 })
        .expect(200);
      await request(server()).post('/auth/login').send({ email, password: 'wrong-password' }).expect(401);
      await request(server()).get('/me/export').set(bearer(u.accessToken)).expect(200);
      await request(server()).delete('/me').set(bearer(u.accessToken)).send({ password: 'secret-password-123' }).expect(204);
    } finally {
      restore();
      process.env.LOG_LEVEL = prevLevel;
    }
    expect(lines.length).toBeGreaterThan(5);
    const parsed = lines.map((l) => JSON.parse(l) as Record<string, unknown>);
    for (const p of parsed) {
      expect(p).toMatchObject({ level: expect.any(String), message: expect.any(String), timestamp: expect.any(String) });
    }
    const traced = parsed.find((p) => p.requestId === 'test-request-0001');
    expect(traced).toMatchObject({ message: 'request', method: 'PUT', path: '/me/profile', statusCode: 200 });
    const all = lines.join('\n');
    for (const secret of ['pii-check', '93.7', '187.3', 'lumbar', '1977', 'secret-password', 'Bearer ', 'weight=']) {
      expect(all).not.toContain(secret);
    }
    expect(parsed.some((p) => p.message === 'account deleted' && typeof p.subject === 'string')).toBe(true);
  });

  it('health: liveness, readiness con la BD y cabecera X-Request-Id', async () => {
    const live = await request(server()).get('/health').expect(200);
    expect(live.body).toEqual({ status: 'ok' });
    expect(live.headers['x-request-id']).toMatch(/^[0-9a-f-]{36}$/);
    const ready = await request(server()).get('/health/ready').set('X-Request-Id', 'bad id with spaces').expect(200);
    expect(ready.body).toEqual({ status: 'ok', checks: { database: 'ok' } });
    expect(ready.headers['x-request-id']).not.toBe('bad id with spaces');
  });

  it('errores con formato estable { statusCode, code, message, requestId }', async () => {
    const res = await request(server()).get('/me').expect(401);
    expect(res.body).toMatchObject({ statusCode: 401, code: 'UNAUTHORIZED', requestId: expect.any(String) });
    const nf = await request(server()).get('/nope').expect(404);
    expect(nf.body.code).toBe('NOT_FOUND');
  });

  it('catálogo: paginado, filtros y detalle; solo ejercicios activos', async () => {
    const total = loadCatalog().length;
    const page = await request(server()).get('/exercises?page=2&pageSize=10').expect(200);
    expect(page.body).toMatchObject({ page: 2, pageSize: 10, total });
    expect(page.body.items).toHaveLength(10);
    const home = await request(server()).get('/exercises?equipment=dumbbell&pageSize=100').expect(200);
    for (const e of home.body.items) expect(e.equipment.every((q: string) => q === 'dumbbell' || q === 'bodyweight')).toBe(true);
    const squats = await request(server()).get('/exercises?movementPattern=squat&level=beginner&pageSize=100').expect(200);
    for (const e of squats.body.items) expect(e).toMatchObject({ movementPattern: 'squat', minLevel: 'beginner' });
    const q = await request(server()).get('/exercises?q=sentadilla').expect(200);
    expect(q.body.total).toBeGreaterThan(0);
    const detail = await request(server()).get(`/exercises/${page.body.items[0].id}`).expect(200);
    expect(detail.body.muscles.length).toBeGreaterThan(0);
    expect(detail.body.cuesEs.length).toBeGreaterThanOrEqual(2);
    await request(server()).get('/exercises?pageSize=500').expect(400);

    // Borrado lógico: desaparece del catálogo público.
    await ctx.prisma.exercise.update({ where: { id: detail.body.id }, data: { deletedAt: new Date() } });
    try {
      await request(server()).get(`/exercises/${detail.body.id}`).expect(404);
      expect((await request(server()).get('/exercises').expect(200)).body.total).toBe(total - 1);
    } finally {
      await ctx.prisma.exercise.update({ where: { id: detail.body.id }, data: { deletedAt: null } });
    }
  });
});
