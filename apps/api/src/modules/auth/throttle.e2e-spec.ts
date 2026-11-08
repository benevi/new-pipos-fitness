import request from 'supertest';
import { THROTTLE_LIMITS } from '../../config/throttle';
import { createTestApp, registerUser, truncateAll, bearer, type TestContext } from '../../test/e2e/helpers';

/** Única suite con rate limiting activo (el resto lo desactiva vía THROTTLE_ENABLED=false). */
describe('Rate limiting (e2e, Postgres real)', () => {
  let ctx: TestContext;
  const server = () => ctx.app.getHttpServer();

  beforeEach(async () => {
    ctx = await createTestApp({ THROTTLE_ENABLED: 'true' });
    await truncateAll(ctx.prisma);
  });

  afterEach(async () => {
    await ctx.app.close();
  });

  it(`POST /auth/login devuelve 429 tras ${THROTTLE_LIMITS.AUTH_CREDENTIALS.limit} intentos por minuto`, async () => {
    const { limit } = THROTTLE_LIMITS.AUTH_CREDENTIALS;
    for (let i = 0; i < limit; i++) {
      await request(server())
        .post('/auth/login')
        .send({ email: 'brute@example.com', password: `guess-${i}` })
        .expect(401);
    }
    const blocked = await request(server())
      .post('/auth/login')
      .send({ email: 'brute@example.com', password: 'guess-final' })
      .expect(429);
    expect(blocked.headers['retry-after']).toBeDefined();
  });

  it(`POST /auth/refresh devuelve 429 tras ${THROTTLE_LIMITS.AUTH_REFRESH.limit} intentos por minuto`, async () => {
    const { limit } = THROTTLE_LIMITS.AUTH_REFRESH;
    for (let i = 0; i < limit; i++) {
      await request(server()).post('/auth/refresh').send({ refreshToken: `bad-${i}` }).expect(401);
    }
    await request(server()).post('/auth/refresh').send({ refreshToken: 'bad-final' }).expect(429);
  });

  it(`POST /training-plans/generate devuelve 429 tras ${THROTTLE_LIMITS.PLAN_GENERATION.limit} peticiones por minuto`, async () => {
    const u = await registerUser(ctx.app);
    const { limit } = THROTTLE_LIMITS.PLAN_GENERATION;
    for (let i = 0; i < limit; i++) {
      const res = await request(server()).post('/training-plans/generate').set(bearer(u.accessToken));
      expect(res.status).not.toBe(429);
    }
    await request(server()).post('/training-plans/generate').set(bearer(u.accessToken)).expect(429);
  });

  it('los límites son por ruta: agotar login no bloquea GET /health', async () => {
    const { limit } = THROTTLE_LIMITS.AUTH_CREDENTIALS;
    for (let i = 0; i <= limit; i++) {
      await request(server()).post('/auth/login').send({ email: 'x@example.com', password: 'nopenope' });
    }
    await request(server()).get('/health').expect(200);
  });
});
