import request from 'supertest';
import { createTestApp, registerUser, truncateAll, bearer, type TestContext, type RegisteredUser } from '../../test/e2e/helpers';

describe('Users /me (e2e, Postgres real)', () => {
  let ctx: TestContext;
  let user: RegisteredUser;
  const server = () => ctx.app.getHttpServer();

  beforeAll(async () => {
    ctx = await createTestApp();
  });

  beforeEach(async () => {
    await truncateAll(ctx.prisma);
    user = await registerUser(ctx.app, 'me@example.com');
  });

  afterAll(async () => {
    await ctx.app.close();
  });

  describe('GET /me', () => {
    it('200 con el usuario autenticado (sin passwordHash)', async () => {
      const res = await request(server()).get('/me').set(bearer(user.accessToken)).expect(200);
      expect(res.body.id).toBe(user.id);
      expect(res.body.email).toBe('me@example.com');
      expect(res.body).not.toHaveProperty('passwordHash');
    });

    it('401 sin token', async () => {
      await request(server()).get('/me').expect(401);
    });

    it('401 con token malformado', async () => {
      await request(server()).get('/me').set(bearer('not-a-jwt')).expect(401);
    });
  });

  describe('PUT /me/profile', () => {
    it('200 y persiste los datos', async () => {
      const res = await request(server())
        .put('/me/profile')
        .set(bearer(user.accessToken))
        .send({ heightCm: 180, weightKg: 75, age: 30, sex: 'male' })
        .expect(200);
      expect(res.body).toMatchObject({ id: user.id, heightCm: 180, weightKg: 75, age: 30, sex: 'male' });
      const stored = await ctx.prisma.user.findUniqueOrThrow({ where: { id: user.id } });
      expect(stored.weightKg).toBe(75);
    });

    it('400 con valores inválidos', async () => {
      await request(server())
        .put('/me/profile')
        .set(bearer(user.accessToken))
        .send({ weightKg: -1 })
        .expect(400);
    });
  });

  describe('PUT /me/preferences', () => {
    it('200 con preferencias válidas', async () => {
      const res = await request(server())
        .put('/me/preferences')
        .set(bearer(user.accessToken))
        .send({ trainingLevel: 'intermediate', preferredTrainingDays: 3, trainingLocation: 'gym' })
        .expect(200);
      expect(res.body).toMatchObject({ trainingLevel: 'intermediate', preferredTrainingDays: 3, trainingLocation: 'gym' });
    });

    it('200 con availableEquipment válido', async () => {
      const res = await request(server())
        .put('/me/preferences')
        .set(bearer(user.accessToken))
        .send({ availableEquipment: ['eq-dumbbell', 'eq-barbell'] })
        .expect(200);
      expect(res.body.availableEquipment).toEqual(['eq-dumbbell', 'eq-barbell']);
    });
  });

  describe('PUT /me/goals', () => {
    it('200 con el esquema estricto de goals', async () => {
      await request(server())
        .put('/me/goals')
        .set(bearer(user.accessToken))
        .send({
          goals: [
            { type: 'muscle_gain', priority: 1 },
            { type: 'custom', priority: 2, customText: 'Other' },
          ],
        })
        .expect(200);
    });

    it('400 si customText supera el límite', async () => {
      await request(server())
        .put('/me/goals')
        .set(bearer(user.accessToken))
        .send({ goals: [{ type: 'custom', priority: 1, customText: 'x'.repeat(201) }] })
        .expect(400);
    });
  });

  describe('PUT /me/muscle-focus', () => {
    it('200 con el esquema estricto de muscleFocus', async () => {
      await request(server())
        .put('/me/muscle-focus')
        .set(bearer(user.accessToken))
        .send({
          muscleFocus: [
            { muscleId: 'muscle-chest', priority: 'grow' },
            { muscleId: 'muscle-back', priority: 'maintain' },
          ],
        })
        .expect(200);
    });
  });

  it('cada usuario sólo ve y modifica su propio perfil', async () => {
    const other = await registerUser(ctx.app, 'other@example.com');
    await request(server())
      .put('/me/profile')
      .set(bearer(other.accessToken))
      .send({ weightKg: 99 })
      .expect(200);
    const mine = await request(server()).get('/me').set(bearer(user.accessToken)).expect(200);
    expect(mine.body.weightKg).toBeNull();
  });
});
