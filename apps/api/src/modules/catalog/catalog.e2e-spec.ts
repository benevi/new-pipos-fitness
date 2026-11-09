import request from 'supertest';
import { randomUUID } from 'crypto';
import { createTestApp, createExercise, truncateAll, type TestContext } from '../../test/e2e/helpers';

describe('Catalog (e2e, Postgres real)', () => {
  let ctx: TestContext;
  let benchId: string;
  const server = () => ctx.app.getHttpServer();

  beforeAll(async () => {
    ctx = await createTestApp();
  });

  beforeEach(async () => {
    await truncateAll(ctx.prisma);
    await ctx.prisma.muscle.create({ data: { id: 'muscle-back', name: 'Back', region: 'upper' } });
    await ctx.prisma.equipmentItem.create({
      data: { id: 'eq-dumbbell', name: 'Dumbbell', category: 'free_weights' },
    });
    const bench = await createExercise(ctx.prisma, { slug: 'bench-press', name: 'Bench Press' });
    benchId = bench.id;
    await createExercise(ctx.prisma, { slug: 'push-up', name: 'Push-up', place: 'home' });
    await ctx.prisma.exerciseMediaYouTube.createMany({
      data: [
        { exerciseId: benchId, youtubeVideoId: 'approved1', isPrimary: true, curationStatus: 'approved' },
        { exerciseId: benchId, youtubeVideoId: 'pending1', curationStatus: 'pending' },
      ],
    });
    await ctx.prisma.food.createMany({
      data: [
        { id: 'food-a', name: 'A', caloriesPer100g: 1, proteinPer100g: 1, carbsPer100g: 1, fatPer100g: 1 },
        { id: 'food-b', name: 'B', caloriesPer100g: 1, proteinPer100g: 1, carbsPer100g: 1, fatPer100g: 1 },
        { id: 'food-c', name: 'C', caloriesPer100g: 1, proteinPer100g: 1, carbsPer100g: 1, fatPer100g: 1 },
      ],
    });
  });

  afterAll(async () => {
    await ctx.app.close();
  });

  it('GET /muscles lista músculos', async () => {
    const res = await request(server()).get('/muscles').expect(200);
    expect(res.body.map((m: { id: string }) => m.id).sort()).toEqual(['muscle-back', 'muscle-chest']);
    expect(res.body[0]).toHaveProperty('region');
  });

  it('GET /equipment-items lista equipamiento', async () => {
    const res = await request(server()).get('/equipment-items').expect(200);
    expect(res.body).toEqual([{ id: 'eq-dumbbell', name: 'Dumbbell', category: 'free_weights' }]);
  });

  describe('GET /exercises', () => {
    it('paginado', async () => {
      const res = await request(server()).get('/exercises').query({ page: 1, limit: 1 }).expect(200);
      expect(res.body).toMatchObject({ page: 1, limit: 1, totalCount: 2 });
      expect(res.body.items).toHaveLength(1);
    });

    it('filtra por músculo, lugar y dificultad', async () => {
      const res = await request(server())
        .get('/exercises')
        .query({ muscleId: 'muscle-chest', place: 'gym', difficulty: 2 })
        .expect(200);
      expect(res.body.items.map((e: { slug: string }) => e.slug)).toEqual(['bench-press']);
    });

    it('búsqueda por texto', async () => {
      const res = await request(server()).get('/exercises').query({ search: 'push' }).expect(200);
      expect(res.body.items.map((e: { slug: string }) => e.slug)).toEqual(['push-up']);
    });

    it('400 si search supera 100 caracteres o limit > 100', async () => {
      await request(server()).get('/exercises').query({ search: 's'.repeat(101) }).expect(400);
      await request(server()).get('/exercises').query({ limit: 1000 }).expect(400);
    });
  });

  describe('GET /exercises/:id', () => {
    it('detalle con músculos, variantes y media', async () => {
      const res = await request(server()).get(`/exercises/${benchId}`).expect(200);
      expect(res.body).toMatchObject({ id: benchId, slug: 'bench-press' });
      expect(res.body.muscles).toHaveLength(1);
      expect(res.body).toHaveProperty('variants');
      expect(res.body).toHaveProperty('media');
    });

    it('404 para un UUID inexistente', async () => {
      await request(server()).get(`/exercises/${randomUUID()}`).expect(404);
    });

    it('400 para un id que no es UUID', async () => {
      await request(server()).get('/exercises/unknown').expect(400);
    });
  });

  it('GET /exercises/:id/media devuelve sólo media aprobada', async () => {
    const res = await request(server()).get(`/exercises/${benchId}/media`).expect(200);
    expect(res.body.map((m: { youtubeVideoId: string }) => m.youtubeVideoId)).toEqual(['approved1']);
  });

  describe('GET /foods', () => {
    it('paginación por cursor', async () => {
      const first = await request(server()).get('/foods').query({ limit: 2 }).expect(200);
      expect(first.body.map((f: { id: string }) => f.id)).toEqual(['food-a', 'food-b']);
      const next = await request(server()).get('/foods').query({ limit: 2, cursor: 'food-b' }).expect(200);
      expect(next.body.map((f: { id: string }) => f.id)).toEqual(['food-c']);
    });

    it('400 con limit o cursor inválidos', async () => {
      await request(server()).get('/foods').query({ limit: 'abc' }).expect(400);
      await request(server()).get('/foods').query({ limit: 5000 }).expect(400);
      await request(server()).get('/foods').query({ cursor: "x' OR 1=1" }).expect(400);
    });
  });

  describe('administración del catálogo eliminada (ADR-0005)', () => {
    it.each([
      ['post', '/admin/exercises'],
      ['put', '/admin/exercises/00000000-0000-0000-0000-000000000000'],
      ['post', '/admin/exercises/00000000-0000-0000-0000-000000000000/media'],
      ['put', '/admin/exercise-media/00000000-0000-0000-0000-000000000000/approve'],
    ] as const)('%s %s → 404 y no modifica el catálogo', async (method, path) => {
      await request(server())[method](path).send({ slug: 'hacked', name: 'Hacked', difficulty: 1, place: 'home' }).expect(404);
      expect(await ctx.prisma.exercise.count({ where: { slug: 'hacked' } })).toBe(0);
    });
  });
});
