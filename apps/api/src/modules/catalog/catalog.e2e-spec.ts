import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { vi } from 'vitest';
import { AppModule } from '../../app.module';
import { PrismaService } from '../../prisma/prisma.service';

const mockMuscles = [
  { id: 'm1', name: 'Chest', region: 'upper', meshRegionId: null },
  { id: 'm2', name: 'Back', region: 'upper', meshRegionId: null },
];

const mockEquipment = [
  { id: 'e1', name: 'Dumbbell', category: 'free_weights' },
];

const mockExercise = {
  id: 'ex1',
  slug: 'bench-press',
  name: 'Bench Press',
  description: 'Chest press',
  difficulty: 2,
  movementPattern: 'push',
  place: 'gym',
};

const mockMedia = [
  {
    id: 'med1',
    exerciseId: 'ex1',
    youtubeVideoId: 'abc',
    channelName: 'Channel',
    isPrimary: true,
    startSeconds: 0,
    endSeconds: 60,
    curationStatus: 'approved',
  },
];

describe('Catalog (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue({
        muscle: { findMany: vi.fn().mockResolvedValue(mockMuscles) },
        equipmentItem: { findMany: vi.fn().mockResolvedValue(mockEquipment) },
        exercise: {
          findMany: vi.fn().mockResolvedValue([mockExercise]),
          findUnique: vi.fn().mockImplementation((args: { where: { id?: string } }) => {
            if (args.where.id === 'ex1') {
              return Promise.resolve({
                ...mockExercise,
                muscles: [{ exerciseId: 'ex1', muscleId: 'm1', role: 'primary', muscle: mockMuscles[0] }],
                variants: [],
                media: mockMedia,
              });
            }
            return Promise.resolve(null);
          }),
          count: vi.fn().mockResolvedValue(1),
          create: vi.fn().mockResolvedValue({ ...mockExercise, id: 'ex-new' }),
          update: vi.fn().mockResolvedValue(mockExercise),
          findUniqueOrThrow: vi.fn().mockResolvedValue(mockExercise),
        },
        exerciseMuscle: { createMany: vi.fn().mockResolvedValue(undefined), deleteMany: vi.fn().mockResolvedValue(undefined) },
        exerciseMediaYouTube: {
          findMany: vi.fn().mockResolvedValue(mockMedia),
          findUnique: vi.fn(),
          create: vi.fn().mockResolvedValue(mockMedia[0]),
          update: vi.fn().mockResolvedValue(mockMedia[0]),
        },
      })
      .compile();

    app = moduleFixture.createNestApplication();
    prisma = moduleFixture.get(PrismaService);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('GET /muscles', () => {
    it('returns list of muscles', async () => {
      const res = await request(app.getHttpServer()).get('/muscles').expect(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
      expect(res.body[0]).toHaveProperty('name');
      expect(res.body[0]).toHaveProperty('region');
    });
  });

  describe('GET /equipment-items', () => {
    it('returns list of equipment', async () => {
      const res = await request(app.getHttpServer()).get('/equipment-items').expect(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body[0]).toHaveProperty('name');
      expect(res.body[0]).toHaveProperty('category');
    });
  });

  describe('GET /exercises', () => {
    it('returns paginated exercises', async () => {
      const res = await request(app.getHttpServer())
        .get('/exercises')
        .query({ page: 1, limit: 10 })
        .expect(200);
      expect(res.body).toHaveProperty('items');
      expect(res.body).toHaveProperty('totalCount');
      expect(res.body).toHaveProperty('page', 1);
      expect(res.body).toHaveProperty('limit', 10);
      expect(Array.isArray(res.body.items)).toBe(true);
    });
    it('accepts filter query', async () => {
      await request(app.getHttpServer())
        .get('/exercises')
        .query({ muscleId: 'm1', place: 'gym', difficulty: 2 })
        .expect(200);
    });
  });

  describe('GET /exercises/:id', () => {
    it('returns exercise detail', async () => {
      const res = await request(app.getHttpServer()).get('/exercises/ex1').expect(200);
      expect(res.body).toHaveProperty('id', 'ex1');
      expect(res.body).toHaveProperty('slug', 'bench-press');
      expect(res.body).toHaveProperty('muscles');
      expect(res.body).toHaveProperty('variants');
      expect(res.body).toHaveProperty('media');
    });
    it('returns 404 for unknown id', async () => {
      (prisma.exercise.findUnique as ReturnType<typeof vi.fn>).mockResolvedValueOnce(null);
      await request(app.getHttpServer()).get('/exercises/unknown').expect(404);
    });
  });

  describe('GET /exercises/:id/media', () => {
    it('returns media for exercise', async () => {
      const res = await request(app.getHttpServer()).get('/exercises/ex1/media').expect(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('POST /admin/exercises', () => {
    it('creates exercise', async () => {
      (prisma.exercise.findUnique as ReturnType<typeof vi.fn>).mockResolvedValueOnce(null);
      const res = await request(app.getHttpServer())
        .post('/admin/exercises')
        .send({
          slug: 'new-exercise',
          name: 'New Exercise',
          difficulty: 1,
          place: 'home',
        })
        .expect(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('slug');
    });
  });

  describe('PUT /admin/exercises/:id', () => {
    it('updates exercise', async () => {
      await request(app.getHttpServer())
        .put('/admin/exercises/ex1')
        .send({ name: 'Updated Name' })
        .expect(200);
    });
  });
});
