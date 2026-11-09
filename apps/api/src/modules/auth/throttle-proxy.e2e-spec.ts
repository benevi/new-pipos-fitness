import request from 'supertest';
import { THROTTLE_LIMITS } from '../../config/throttle';
import { PostgresThrottlerStorage } from '../../config/postgres-throttler.storage';
import { createTestApp, truncateAll, type TestContext } from '../../test/e2e/helpers';

const { limit } = THROTTLE_LIMITS.AUTH_CREDENTIALS;

async function exhaustLogin(ctx: TestContext, forwardedFor: string): Promise<void> {
  for (let i = 0; i < limit; i++) {
    await request(ctx.app.getHttpServer())
      .post('/auth/login')
      .set('X-Forwarded-For', forwardedFor)
      .send({ email: 'brute@example.com', password: `guess-${i}` })
      .expect(401);
  }
}

function login(ctx: TestContext, forwardedFor: string) {
  return request(ctx.app.getHttpServer())
    .post('/auth/login')
    .set('X-Forwarded-For', forwardedFor)
    .send({ email: 'brute@example.com', password: 'guess-final' });
}

/** Issue #9: `trust proxy` (TRUST_PROXY_HOPS) y almacén compartido en Postgres (THROTTLE_STORE). */
describe('Rate limiting detrás de un proxy y entre réplicas (e2e, Postgres real)', () => {
  const apps: TestContext[] = [];
  const open = async (env: Record<string, string>) => {
    const ctx = await createTestApp({ THROTTLE_ENABLED: 'true', ...env });
    apps.push(ctx);
    return ctx;
  };

  afterEach(async () => {
    for (const ctx of apps.splice(0)) await ctx.app.close();
  });

  describe.each(['memory', 'postgres'])('almacén %s', (store) => {
    it('con TRUST_PROXY_HOPS=1 limita por cliente (X-Forwarded-For): otro cliente no queda bloqueado', async () => {
      const ctx = await open({ THROTTLE_STORE: store, TRUST_PROXY_HOPS: '1' });
      await truncateAll(ctx.prisma);
      await exhaustLogin(ctx, '203.0.113.10');
      await login(ctx, '203.0.113.10').expect(429);
      await login(ctx, '198.51.100.20').expect(401);
      // El salto de más a la izquierda lo pone el cliente: solo cuenta el último (el del proxy).
      await login(ctx, '198.51.100.99, 203.0.113.10').expect(429);
    });

    it('con TRUST_PROXY_HOPS=0 ignora X-Forwarded-For: cambiar la cabecera no esquiva el límite', async () => {
      const ctx = await open({ THROTTLE_STORE: store, TRUST_PROXY_HOPS: '0' });
      await truncateAll(ctx.prisma);
      await exhaustLogin(ctx, '203.0.113.10');
      await login(ctx, '198.51.100.20').expect(429);
    });
  });

  it('THROTTLE_STORE=postgres comparte los contadores entre réplicas', async () => {
    const a = await open({ THROTTLE_STORE: 'postgres', TRUST_PROXY_HOPS: '1' });
    const b = await open({ THROTTLE_STORE: 'postgres', TRUST_PROXY_HOPS: '1' });
    await truncateAll(a.prisma);
    // Golpes repartidos entre las dos réplicas: el límite es la suma.
    for (let i = 0; i < limit; i++) {
      await request((i % 2 === 0 ? a : b).app.getHttpServer())
        .post('/auth/login')
        .set('X-Forwarded-For', '203.0.113.10')
        .send({ email: 'brute@example.com', password: `guess-${i}` })
        .expect(401);
    }
    const blocked = await login(b, '203.0.113.10').expect(429);
    expect(Number(blocked.headers['retry-after'])).toBeGreaterThan(0);
    await login(a, '203.0.113.10').expect(429);
    // La fila no guarda la IP en claro (la clave es un hash del throttler).
    const rows = await a.prisma.throttlerRecord.findMany();
    expect(rows.length).toBeGreaterThan(0);
    expect(JSON.stringify(rows)).not.toContain('203.0.113.10');
  });

  it('THROTTLE_STORE=memory no comparte: cada réplica cuenta por separado', async () => {
    const a = await open({ THROTTLE_STORE: 'memory', TRUST_PROXY_HOPS: '1' });
    const b = await open({ THROTTLE_STORE: 'memory', TRUST_PROXY_HOPS: '1' });
    await truncateAll(a.prisma);
    await exhaustLogin(a, '203.0.113.10');
    await login(a, '203.0.113.10').expect(429);
    await login(b, '203.0.113.10').expect(401);
    expect(await a.prisma.throttlerRecord.count()).toBe(0);
  });

  it('el almacén Postgres desbloquea al caducar y la limpieza borra solo lo caducado', async () => {
    const ctx = await open({ THROTTLE_STORE: 'postgres' });
    await truncateAll(ctx.prisma);
    const storage = new PostgresThrottlerStorage(ctx.prisma);
    // Ventana de 300 ms, límite 2, bloqueo de 300 ms.
    expect(await storage.increment('k1', 300, 2, 300)).toMatchObject({ totalHits: 1, isBlocked: false });
    expect(await storage.increment('k1', 300, 2, 300)).toMatchObject({ totalHits: 2, isBlocked: false });
    const blocked = await storage.increment('k1', 300, 2, 300);
    expect(blocked).toMatchObject({ totalHits: 3, isBlocked: true });
    expect(blocked.timeToBlockExpire).toBeGreaterThan(0);
    // Durante el bloqueo no se cuentan más golpes.
    expect(await storage.increment('k1', 300, 2, 300)).toMatchObject({ totalHits: 3, isBlocked: true });
    await storage.increment('k2', 60_000, 2, 60_000);
    await new Promise((r) => setTimeout(r, 400));
    expect(await storage.cleanup()).toBe(1);
    expect((await ctx.prisma.throttlerRecord.findMany()).map((r) => r.key)).toEqual(['k2']);
    // Tras el bloqueo, vuelve a empezar la cuenta.
    expect(await storage.increment('k1', 300, 2, 300)).toMatchObject({ totalHits: 1, isBlocked: false });
  });

  it('golpes simultáneos en Postgres no pierden cuentas (upsert atómico)', async () => {
    const ctx = await open({ THROTTLE_STORE: 'postgres' });
    await truncateAll(ctx.prisma);
    const storage = new PostgresThrottlerStorage(ctx.prisma);
    const results = await Promise.all(Array.from({ length: 20 }, () => storage.increment('race', 60_000, 100, 60_000)));
    expect(results.map((r) => r.totalHits).sort((x, y) => x - y)).toEqual(Array.from({ length: 20 }, (_, i) => i + 1));
  });
});
