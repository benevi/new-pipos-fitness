import request from 'supertest';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { AUTH_REFRESH_RACE, AUTH_REFRESH_REUSED, BCRYPT_COST } from './auth.service';
import { createTestApp, registerUser, truncateAll, bearer, type TestContext } from '../../test/e2e/helpers';

describe('Auth (e2e, Postgres real)', () => {
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

  describe('POST /auth/register', () => {
    it('201: crea usuario con rol user, hash bcrypt coste 12 y devuelve tokens', async () => {
      const res = await request(server())
        .post('/auth/register')
        .send({ email: 'New@Example.com', password: 'password123' })
        .expect(201);
      expect(res.body.accessToken).toEqual(expect.any(String));
      expect(res.body.refreshToken).toEqual(expect.any(String));
      expect(res.body.expiresIn).toBe(900);
      expect(res.body.user).toEqual({ id: expect.any(String), email: 'New@Example.com' });

      const user = await ctx.prisma.user.findUniqueOrThrow({ where: { id: res.body.user.id } });
      expect(user.emailNormalized).toBe('new@example.com');
      expect(user.role).toBe('user');
      expect(bcrypt.getRounds(user.passwordHash)).toBe(BCRYPT_COST);
      expect(await bcrypt.compare('password123', user.passwordHash)).toBe(true);
    });

    it('el access token lleva userId y role, sin email (minimización)', async () => {
      const { accessToken, id } = await registerUser(ctx.app, 'claims@example.com');
      const payload = new JwtService({}).decode(accessToken) as Record<string, unknown>;
      expect(payload).toMatchObject({ userId: id, role: 'user' });
      expect(payload.email).toBeUndefined();
      expect((payload.exp as number) - (payload.iat as number)).toBe(900);
    });

    it('409 AUTH_EMAIL_TAKEN si el email ya existe (aunque cambie mayúsculas)', async () => {
      await registerUser(ctx.app, 'user@example.com');
      const res = await request(server())
        .post('/auth/register')
        .send({ email: 'USER@Example.COM', password: 'password123' })
        .expect(409);
      expect(res.body.code).toBe('AUTH_EMAIL_TAKEN');
    });

    it('400 si la contraseña supera 72 bytes', async () => {
      await request(server())
        .post('/auth/register')
        .send({ email: 'long@example.com', password: 'ñ'.repeat(37) })
        .expect(400);
    });

    it('400 si el body es inválido', async () => {
      await request(server()).post('/auth/register').send({ email: 'nope' }).expect(400);
    });
  });

  describe('POST /auth/login', () => {
    it('200 y tokens con credenciales válidas (email insensible a mayúsculas)', async () => {
      await registerUser(ctx.app, 'test@example.com');
      const res = await request(server())
        .post('/auth/login')
        .send({ email: 'TEST@EXAMPLE.COM', password: 'password123' })
        .expect(200);
      expect(res.body.accessToken).toEqual(expect.any(String));
      expect(res.body.refreshToken).toEqual(expect.any(String));
    });

    it('401 con contraseña incorrecta', async () => {
      await registerUser(ctx.app, 'test@example.com');
      await request(server())
        .post('/auth/login')
        .send({ email: 'test@example.com', password: 'wrong-password' })
        .expect(401);
    });

    it('401 con el mismo mensaje si el usuario no existe', async () => {
      await registerUser(ctx.app, 'test@example.com');
      const wrongPwd = await request(server())
        .post('/auth/login')
        .send({ email: 'test@example.com', password: 'wrong-password' })
        .expect(401);
      const noUser = await request(server())
        .post('/auth/login')
        .send({ email: 'ghost@example.com', password: 'wrong-password' })
        .expect(401);
      expect(noUser.body.message).toBe(wrongPwd.body.message);
    });
  });

  describe('POST /auth/refresh', () => {
    it('200: rota el token (nuevo par, el antiguo queda revocado y enlazado)', async () => {
      const u = await registerUser(ctx.app);
      const res = await request(server())
        .post('/auth/refresh')
        .send({ refreshToken: u.refreshToken })
        .expect(200);
      expect(res.body.refreshToken).not.toBe(u.refreshToken);
      expect(res.body.accessToken).toEqual(expect.any(String));
      expect(res.body.expiresIn).toBe(900);

      const tokens = await ctx.prisma.refreshToken.findMany({ where: { userId: u.id } });
      expect(tokens).toHaveLength(2);
      const old = tokens.find((t) => t.revokedAt !== null);
      const fresh = tokens.find((t) => t.revokedAt === null);
      expect(old?.replacedById).toBe(fresh?.id);
      expect(old?.revokedReason).toBe('rotated');
      expect(fresh?.familyId).toBe(old?.familyId);
    });

    it('401 con token desconocido', async () => {
      await request(server()).post('/auth/refresh').send({ refreshToken: 'invalid' }).expect(401);
    });

    it('401 con token caducado', async () => {
      const u = await registerUser(ctx.app);
      await ctx.prisma.refreshToken.updateMany({
        where: { userId: u.id },
        data: { expiresAt: new Date(Date.now() - 1000) },
      });
      await request(server()).post('/auth/refresh').send({ refreshToken: u.refreshToken }).expect(401);
    });

    it('reutilización: 401 AUTH_REFRESH_REUSED y se revocan TODAS las sesiones del usuario', async () => {
      const u = await registerUser(ctx.app, 'victim@example.com');
      // Segunda sesión (otro dispositivo) del mismo usuario.
      const login = await request(server())
        .post('/auth/login')
        .send({ email: u.email, password: u.password })
        .expect(200);
      // Rotación legítima.
      const rotated = await request(server())
        .post('/auth/refresh')
        .send({ refreshToken: u.refreshToken })
        .expect(200);
      // Fuera de la ventana de gracia (rotado hace 60 s), un atacante reutiliza el token rotado.
      await ctx.prisma.refreshToken.updateMany({
        where: { userId: u.id, revokedReason: 'rotated' },
        data: { rotatedAt: new Date(Date.now() - 60_000) },
      });
      const reuse = await request(server())
        .post('/auth/refresh')
        .send({ refreshToken: u.refreshToken })
        .expect(401);
      expect(reuse.body.code).toBe(AUTH_REFRESH_REUSED);

      expect(await ctx.prisma.refreshToken.count({ where: { userId: u.id, revokedAt: null } })).toBe(0);
      // Ni el token rotado ni la otra sesión siguen siendo válidos.
      await request(server())
        .post('/auth/refresh')
        .send({ refreshToken: rotated.body.refreshToken })
        .expect(401);
      await request(server())
        .post('/auth/refresh')
        .send({ refreshToken: login.body.refreshToken })
        .expect(401);
    });

    it('la reutilización no afecta a sesiones de otros usuarios', async () => {
      const a = await registerUser(ctx.app);
      const b = await registerUser(ctx.app);
      await request(server()).post('/auth/refresh').send({ refreshToken: a.refreshToken }).expect(200);
      await ctx.prisma.refreshToken.updateMany({ where: { userId: a.id }, data: { rotatedAt: new Date(Date.now() - 60_000) } });
      await request(server()).post('/auth/refresh').send({ refreshToken: a.refreshToken }).expect(401);
      await request(server()).post('/auth/refresh').send({ refreshToken: b.refreshToken }).expect(200);
    });

    it('ventana de gracia: reenviar un token recién rotado → 401 AUTH_REFRESH_RACE sin revocar la familia', async () => {
      const u = await registerUser(ctx.app);
      const rotated = await request(server()).post('/auth/refresh').send({ refreshToken: u.refreshToken }).expect(200);
      // Otra petición simultánea del mismo cliente llega con el token viejo.
      const retry = await request(server()).post('/auth/refresh').send({ refreshToken: u.refreshToken }).expect(401);
      expect(retry.body.code).toBe(AUTH_REFRESH_RACE);
      // Nada revocado: el token nuevo sigue funcionando.
      expect(await ctx.prisma.refreshToken.count({ where: { userId: u.id, revokedReason: 'reuse_detected' } })).toBe(0);
      await request(server()).post('/auth/refresh').send({ refreshToken: rotated.body.refreshToken }).expect(200);
    });

    it('limitación: si se pierde la respuesta del refresh, el token viejo no recupera el par nuevo (hay que volver a entrar)', async () => {
      const u = await registerUser(ctx.app);
      await request(server()).post('/auth/refresh').send({ refreshToken: u.refreshToken }).expect(200); // respuesta «perdida»
      for (let i = 0; i < 2; i++) {
        const retry = await request(server()).post('/auth/refresh').send({ refreshToken: u.refreshToken }).expect(401);
        expect(retry.body.code).toBe(AUTH_REFRESH_RACE);
        expect(retry.body).not.toHaveProperty('refreshToken');
      }
      // Pero no se trata como robo: nada revocado y el login sigue funcionando.
      expect(await ctx.prisma.refreshToken.count({ where: { userId: u.id, revokedReason: 'reuse_detected' } })).toBe(0);
      await request(server()).post('/auth/login').send({ email: u.email, password: u.password }).expect(200);
    });

    it('fuera de la ventana (REFRESH_REUSE_GRACE_SECONDS=0) la reutilización revoca todo', async () => {
      const strict = await createTestApp({ REFRESH_REUSE_GRACE_SECONDS: '0' });
      try {
        const u = await registerUser(strict.app);
        const rotated = await request(strict.app.getHttpServer())
          .post('/auth/refresh')
          .send({ refreshToken: u.refreshToken })
          .expect(200);
        const reuse = await request(strict.app.getHttpServer())
          .post('/auth/refresh')
          .send({ refreshToken: u.refreshToken })
          .expect(401);
        expect(reuse.body.code).toBe(AUTH_REFRESH_REUSED);
        await request(strict.app.getHttpServer())
          .post('/auth/refresh')
          .send({ refreshToken: rotated.body.refreshToken })
          .expect(401);
      } finally {
        await strict.app.close();
      }
    });

    it('carrera: refresh concurrentes con el mismo token → uno gana, el resto AUTH_REFRESH_RACE y la sesión sigue viva', async () => {
      const u = await registerUser(ctx.app);
      const results = await Promise.all(
        Array.from({ length: 5 }, () =>
          request(server()).post('/auth/refresh').send({ refreshToken: u.refreshToken }),
        ),
      );
      const winners = results.filter((r) => r.status === 200);
      expect(winners).toHaveLength(1);
      for (const r of results.filter((x) => x.status !== 200)) {
        expect(r.status).toBe(401);
        expect(r.body.code).toBe(AUTH_REFRESH_RACE);
      }
      // Nunca quedan dos tokens hijos del mismo padre y no se revocó la familia.
      const original = await ctx.prisma.refreshToken.findMany({
        where: { userId: u.id, replacedById: { not: null } },
      });
      expect(original).toHaveLength(1);
      await request(server()).post('/auth/refresh').send({ refreshToken: winners[0].body.refreshToken }).expect(200);
    });
  });

  describe('POST /auth/logout', () => {
    it('200 y revoca el token: un refresh posterior falla', async () => {
      const u = await registerUser(ctx.app);
      await request(server()).post('/auth/logout').send({ refreshToken: u.refreshToken }).expect(200);
      await request(server()).post('/auth/refresh').send({ refreshToken: u.refreshToken }).expect(401);
    });

    it('200 también con un token desconocido (no revela nada)', async () => {
      await request(server()).post('/auth/logout').send({ refreshToken: 'nope' }).expect(200);
    });
  });

  describe('JWT', () => {
    it('401 con un token firmado con otro secreto', async () => {
      const u = await registerUser(ctx.app);
      const forged = new JwtService({ secret: 'another-secret-another-secret-another' }).sign({
        userId: u.id,
        role: 'admin',
      });
      await request(server()).get('/me').set(bearer(forged)).expect(401);
    });

    it('401 si el usuario del token ya no existe', async () => {
      const u = await registerUser(ctx.app);
      await ctx.prisma.user.delete({ where: { id: u.id } });
      await request(server()).get('/me').set(bearer(u.accessToken)).expect(401);
    });
  });
});
