import request from 'supertest';
import { randomUUID } from 'crypto';
import {
  bearer,
  createExercise,
  createPlanSession,
  createTestApp,
  registerUser,
  truncateAll,
  type TestContext,
} from './test/e2e/helpers';

describe('Superficie HTTP (e2e, Postgres real)', () => {
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

  describe('helmet', () => {
    it('añade cabeceras de seguridad y oculta X-Powered-By', async () => {
      const res = await request(server()).get('/health').expect(200);
      expect(res.headers['x-content-type-options']).toBe('nosniff');
      expect(res.headers['x-frame-options']).toBeDefined();
      expect(res.headers['strict-transport-security']).toBeDefined();
      expect(res.headers['x-powered-by']).toBeUndefined();
    });
  });

  describe('CORS (allowlist CORS_ORIGINS)', () => {
    it('refleja un origen permitido', async () => {
      const res = await request(server()).get('/health').set('Origin', 'https://app.pipos.test').expect(200);
      expect(res.headers['access-control-allow-origin']).toBe('https://app.pipos.test');
    });

    it('no devuelve cabeceras CORS a un origen no permitido', async () => {
      const res = await request(server()).get('/health').set('Origin', 'https://evil.example.com').expect(200);
      expect(res.headers['access-control-allow-origin']).toBeUndefined();
    });

    it('preflight de un origen no permitido no autoriza', async () => {
      const res = await request(server())
        .options('/auth/login')
        .set('Origin', 'https://evil.example.com')
        .set('Access-Control-Request-Method', 'POST');
      expect(res.headers['access-control-allow-origin']).toBeUndefined();
    });
  });

  describe('Swagger', () => {
    it('disponible fuera de producción', async () => {
      await request(server()).get('/docs').expect((r) => expect([200, 301]).toContain(r.status));
    });

    it('no se expone en producción', async () => {
      const prod = await createTestApp({ NODE_ENV: 'production', THROTTLE_ENABLED: 'true' });
      try {
        await request(prod.app.getHttpServer()).get('/docs').expect(404);
        await request(prod.app.getHttpServer()).get('/docs-json').expect(404);
      } finally {
        await prod.app.close();
      }
    });
  });

  describe('training-plans', () => {
    it('GET /training-plans/versions/:id: 400 si no es UUID, 404 si es de otro usuario', async () => {
      const alice = await registerUser(ctx.app);
      const bob = await registerUser(ctx.app);
      const exercise = await createExercise(ctx.prisma);
      const plan = await createPlanSession(ctx.prisma, alice.id, exercise.id);

      await request(server()).get('/training-plans/versions/abc').set(bearer(bob.accessToken)).expect(400);
      await request(server())
        .get(`/training-plans/versions/${plan.planVersionId}`)
        .set(bearer(bob.accessToken))
        .expect(404);
      await request(server())
        .get(`/training-plans/versions/${randomUUID()}`)
        .set(bearer(bob.accessToken))
        .expect(404);
      const own = await request(server())
        .get(`/training-plans/versions/${plan.planVersionId}`)
        .set(bearer(alice.accessToken))
        .expect(200);
      expect(own.body.id).toBe(plan.planVersionId);
    });

    it('GET /training-plans/current de Bob no devuelve el plan de Alice', async () => {
      const alice = await registerUser(ctx.app);
      const bob = await registerUser(ctx.app);
      const exercise = await createExercise(ctx.prisma);
      await createPlanSession(ctx.prisma, alice.id, exercise.id);
      await request(server()).get('/training-plans/current').set(bearer(bob.accessToken)).expect(404);
    });
  });

  describe('nutrition-plans/generate: validación del body', () => {
    it('400 con un goal fuera del enum', async () => {
      const u = await registerUser(ctx.app);
      await request(server())
        .post('/nutrition-plans/generate')
        .set(bearer(u.accessToken))
        .send({ goal: 'eat_everything' })
        .expect(400);
    });

    it('400 con campos desconocidos', async () => {
      const u = await registerUser(ctx.app);
      await request(server())
        .post('/nutrition-plans/generate')
        .set(bearer(u.accessToken))
        .send({ goal: 'maintain', userId: randomUUID() })
        .expect(400);
    });

    it('acepta un goal válido (pasa la validación)', async () => {
      const u = await registerUser(ctx.app);
      const res = await request(server())
        .post('/nutrition-plans/generate')
        .set(bearer(u.accessToken))
        .send({ goal: 'maintain' });
      expect(res.status).not.toBe(400);
    });
  });
});
