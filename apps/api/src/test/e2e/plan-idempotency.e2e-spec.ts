import request from 'supertest';
import { randomUUID } from 'crypto';
import { bearer, createTestApp, HOME_INTERMEDIATE, putProfile, registerUser, truncateAll, type TestContext } from './helpers';

/** Issue #11: `Idempotency-Key` en POST /plans/generate. */
describe('Idempotencia de POST /plans/generate (e2e, Postgres real)', () => {
  let ctx: TestContext;
  const server = () => ctx.app.getHttpServer();
  const generate = (token: string, key?: string) => {
    const req = request(server()).post('/plans/generate').set(bearer(token));
    return key === undefined ? req : req.set('Idempotency-Key', key);
  };

  beforeAll(async () => {
    ctx = await createTestApp();
  });
  afterAll(async () => {
    await ctx.app.close();
  });
  beforeEach(async () => {
    await truncateAll(ctx.prisma);
  });

  async function userWithProfile() {
    const user = await registerUser(ctx.app);
    await putProfile(ctx.app, user.accessToken);
    // PUT /me/profile genera ya la versión 1 (si no había plan) o no; partimos del número actual.
    return { user, before: await ctx.prisma.planVersion.count({ where: { userId: user.id } }) };
  }

  it('misma clave → misma versión (201 y luego 200), sin crear otra', async () => {
    const { user, before } = await userWithProfile();
    const key = randomUUID();
    const first = await generate(user.accessToken, key).expect(201);
    const again = await generate(user.accessToken, key).expect(200);
    expect(again.body.id).toBe(first.body.id);
    expect(again.body.version).toBe(first.body.version);
    expect(await ctx.prisma.planVersion.count({ where: { userId: user.id } })).toBe(before + 1);
  });

  it('dos toques simultáneos con la misma clave crean una sola versión', async () => {
    const { user, before } = await userWithProfile();
    const key = randomUUID();
    const results = await Promise.all([generate(user.accessToken, key), generate(user.accessToken, key)]);
    expect(results.map((r) => r.status).sort()).toEqual([200, 201]);
    expect(results[0].body.id).toBe(results[1].body.id);
    expect(await ctx.prisma.planVersion.count({ where: { userId: user.id } })).toBe(before + 1);
  });

  it('misma clave con otra entrada (el perfil cambió) → 422 IDEMPOTENCY_KEY_REUSED', async () => {
    const { user } = await userWithProfile();
    const key = randomUUID();
    await generate(user.accessToken, key).expect(201);
    await putProfile(ctx.app, user.accessToken, HOME_INTERMEDIATE);
    const res = await generate(user.accessToken, key).expect(422);
    expect(res.body.code).toBe('IDEMPOTENCY_KEY_REUSED');
    // Con una clave nueva sí genera.
    await generate(user.accessToken, randomUUID()).expect(201);
  });

  it('claves distintas o sin clave → versiones nuevas; la clave es por usuario', async () => {
    const { user, before } = await userWithProfile();
    const other = await registerUser(ctx.app);
    await putProfile(ctx.app, other.accessToken);
    const key = randomUUID();
    await generate(user.accessToken, key).expect(201);
    await generate(user.accessToken, randomUUID()).expect(201);
    await generate(user.accessToken).expect(201);
    await generate(user.accessToken).expect(201);
    expect(await ctx.prisma.planVersion.count({ where: { userId: user.id } })).toBe(before + 4);
    // La misma clave de otro usuario no choca ni revela nada.
    const theirs = await generate(other.accessToken, key).expect(201);
    expect(theirs.body.id).not.toBe(undefined);
  });

  it('clave mal formada → 400', async () => {
    const { user } = await userWithProfile();
    const res = await generate(user.accessToken, 'x'.repeat(129)).expect(400);
    expect(res.body.issues[0].path).toBe('headers.idempotency-key');
  });
});
