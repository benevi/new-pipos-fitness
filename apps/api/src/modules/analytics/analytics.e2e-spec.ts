import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import * as bcrypt from 'bcrypt';
import { vi } from 'vitest';
import { AppModule } from '../../app.module';
import { PrismaService } from '../../prisma/prisma.service';

describe('Analytics (e2e)', () => {
  let app: INestApplication;
  let accessToken: string;

  const userId = 'user-analytics-1';
  const mockUser = {
    id: userId,
    email: 'analytics@example.com',
    emailNormalized: 'analytics@example.com',
    passwordHash: '',
    createdAt: new Date(),
    updatedAt: new Date(),
    heightCm: null,
    weightKg: null,
    age: null,
    sex: null,
    trainingLevel: null,
    preferredTrainingDays: null,
    availableEquipment: null,
    trainingLocation: null,
    goals: null,
    muscleFocus: null,
  };

  beforeAll(async () => {
    mockUser.passwordHash = await bcrypt.hash('password123', 10);
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue({
        user: { findUnique: vi.fn().mockResolvedValue(mockUser), findFirst: vi.fn(), create: vi.fn(), update: vi.fn() },
        refreshToken: {
          findFirst: vi.fn().mockResolvedValue({
            id: 'rt-1',
            userId: mockUser.id,
            expiresAt: new Date(Date.now() + 86400000),
            revokedAt: null,
            user: mockUser,
          }),
          create: vi.fn(),
          update: vi.fn(),
          delete: vi.fn(),
        },
        workoutSession: {
          findMany: vi.fn().mockResolvedValue([]),
        },
        exerciseProgress: {
          upsert: vi.fn().mockImplementation((args: { where: unknown; create: unknown; update: unknown }) =>
            Promise.resolve({
              userId,
              exerciseId: 'ex-1',
              estimated1RM: null,
              volumeLastWeek: null,
              volumeTrend: null,
              fatigueScore: null,
              lastUpdated: new Date(),
            }),
          ),
        },
        exerciseMuscle: { findMany: vi.fn().mockResolvedValue([]) },
        trainingPlan: {
          findUnique: vi.fn().mockResolvedValue({
            currentVersion: {
              sessions: [{ exercises: [{ sets: 3 }, { sets: 3 }] }],
            },
          }),
        },
      })
      .compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'analytics@example.com', password: 'password123' })
      .expect(200);
    accessToken = loginRes.body.accessToken;
  });

  afterAll(async () => {
    await app.close();
  });

  describe('GET /analytics/progress', () => {
    it('returns 200 and progress shape', async () => {
      const res = await request(app.getHttpServer())
        .get('/analytics/progress')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      expect(res.body).toHaveProperty('exercises');
      expect(res.body).toHaveProperty('adherenceScore');
      expect(res.body).toHaveProperty('fatigueDetected');
      expect(Array.isArray(res.body.exercises)).toBe(true);
    });
  });

  describe('GET /analytics/volume', () => {
    it('returns 200 and volume shape', async () => {
      const res = await request(app.getHttpServer())
        .get('/analytics/volume')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      expect(res.body).toHaveProperty('byExercise');
      expect(res.body).toHaveProperty('byMuscle');
      expect(Array.isArray(res.body.byExercise)).toBe(true);
      expect(Array.isArray(res.body.byMuscle)).toBe(true);
    });
  });
});
