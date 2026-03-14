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
  let prisma: PrismaService;

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
          upsert: vi.fn().mockImplementation((args: { where: unknown; create: unknown; update: unknown }) => {
            void args;
            return Promise.resolve({
              userId,
              exerciseId: 'ex-1',
              estimated1RM: null,
              volumeLastWeek: null,
              volumeTrend: null,
              fatigueScore: null,
              lastUpdated: new Date(),
            });
          }),
        },
        exerciseMuscle: { findMany: vi.fn().mockResolvedValue([]) },
        trainingSession: {
          findUnique: vi.fn().mockResolvedValue(null),
        },
      })
      .compile();

    app = moduleFixture.createNestApplication();
    prisma = moduleFixture.get(PrismaService);
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

    it('adherence null when no workouts in window', async () => {
      vi.mocked(prisma.workoutSession.findMany).mockResolvedValueOnce([]);
      const res = await request(app.getHttpServer())
        .get('/analytics/progress')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      expect(res.body.adherenceScore).toBeNull();
    });

    it('adherence: single workout with linked TrainingSession (session-level planned)', async () => {
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 3);
      vi.mocked(prisma.workoutSession.findMany).mockResolvedValueOnce([
        {
          id: 'ws-1',
          userId,
          planSessionId: 'ts-1',
          planVersionId: 'pv-1',
          startedAt: weekAgo,
          completedAt: new Date(),
          durationMinutes: 45,
          notes: null,
          exercises: [
            {
              id: 'we-1',
              workoutSessionId: 'ws-1',
              exerciseId: 'ex-1',
              order: 0,
              sets: [
                { id: 's1', workoutExerciseId: 'we-1', setIndex: 0, weightKg: 80, reps: 10, rir: 2, completed: true },
                { id: 's2', workoutExerciseId: 'we-1', setIndex: 1, weightKg: 80, reps: 8, rir: 1, completed: true },
              ],
            },
          ],
        },
      ] as never);
      vi.mocked(prisma.trainingSession.findUnique).mockResolvedValueOnce({
        id: 'ts-1',
        planVersionId: 'pv-1',
        sessionIndex: 0,
        name: 'Day 1',
        targetDurationMinutes: 45,
        exercises: [
          { id: 'tse-1', sessionId: 'ts-1', exerciseId: 'ex-1', sets: 3, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 },
        ],
      } as never);
      const res = await request(app.getHttpServer())
        .get('/analytics/progress')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      expect(res.body.adherenceScore).toBeCloseTo(2 / 3);
      expect(res.body.adherenceScore).toBeGreaterThanOrEqual(0);
      expect(res.body.adherenceScore).toBeLessThanOrEqual(1);
    });

    it('adherence: multiple workouts with different TrainingSessions (no over-count)', async () => {
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 3);
      vi.mocked(prisma.workoutSession.findMany).mockResolvedValueOnce([
        {
          id: 'ws-1',
          userId,
          planSessionId: 'ts-1',
          planVersionId: 'pv-1',
          startedAt: weekAgo,
          completedAt: new Date(),
          durationMinutes: 45,
          notes: null,
          exercises: [
            {
              id: 'we-1',
              workoutSessionId: 'ws-1',
              exerciseId: 'ex-1',
              order: 0,
              sets: [
                { id: 's1', workoutExerciseId: 'we-1', setIndex: 0, weightKg: 80, reps: 10, rir: 2, completed: true },
                { id: 's2', workoutExerciseId: 'we-1', setIndex: 1, weightKg: 80, reps: 8, rir: 1, completed: true },
              ],
            },
          ],
        },
        {
          id: 'ws-2',
          userId,
          planSessionId: 'ts-2',
          planVersionId: 'pv-2',
          startedAt: weekAgo,
          completedAt: new Date(),
          durationMinutes: 40,
          notes: null,
          exercises: [
            {
              id: 'we-2',
              workoutSessionId: 'ws-2',
              exerciseId: 'ex-2',
              order: 0,
              sets: [
                { id: 's3', workoutExerciseId: 'we-2', setIndex: 0, weightKg: 50, reps: 12, rir: 1, completed: true },
                { id: 's4', workoutExerciseId: 'we-2', setIndex: 1, weightKg: 50, reps: 10, rir: 2, completed: true },
                { id: 's5', workoutExerciseId: 'we-2', setIndex: 2, weightKg: 50, reps: 8, rir: 1, completed: true },
              ],
            },
          ],
        },
      ] as never);
      vi.mocked(prisma.trainingSession.findUnique)
        .mockResolvedValueOnce({
          id: 'ts-1',
          planVersionId: 'pv-1',
          sessionIndex: 0,
          name: 'Day 1',
          targetDurationMinutes: 45,
          exercises: [{ id: 'tse-1', sessionId: 'ts-1', exerciseId: 'ex-1', sets: 3, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 }],
        } as never)
        .mockResolvedValueOnce({
          id: 'ts-2',
          planVersionId: 'pv-2',
          sessionIndex: 0,
          name: 'Day 1',
          targetDurationMinutes: 40,
          exercises: [{ id: 'tse-2', sessionId: 'ts-2', exerciseId: 'ex-2', sets: 4, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 }],
        } as never);
      const res = await request(app.getHttpServer())
        .get('/analytics/progress')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      expect(res.body.adherenceScore).toBeCloseTo(5 / 7);
      expect(res.body.adherenceScore).toBeGreaterThanOrEqual(0);
      expect(res.body.adherenceScore).toBeLessThanOrEqual(1);
    });

    it('adherence: workout without planSessionId is ignored', async () => {
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 3);
      vi.mocked(prisma.workoutSession.findMany).mockResolvedValueOnce([
        {
          id: 'ws-1',
          userId,
          planSessionId: null,
          planVersionId: null,
          startedAt: weekAgo,
          completedAt: new Date(),
          durationMinutes: 45,
          notes: null,
          exercises: [
            {
              id: 'we-1',
              workoutSessionId: 'ws-1',
              exerciseId: 'ex-1',
              order: 0,
              sets: [{ id: 's1', workoutExerciseId: 'we-1', setIndex: 0, weightKg: 80, reps: 10, rir: 2, completed: true }],
            },
          ],
        },
      ] as never);
      const res = await request(app.getHttpServer())
        .get('/analytics/progress')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      expect(res.body.adherenceScore).toBeNull();
    });

    it('adherence: workout with incomplete sets (only completed count)', async () => {
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 3);
      vi.mocked(prisma.workoutSession.findMany).mockResolvedValueOnce([
        {
          id: 'ws-1',
          userId,
          planSessionId: 'ts-1',
          planVersionId: 'pv-1',
          startedAt: weekAgo,
          completedAt: new Date(),
          durationMinutes: 45,
          notes: null,
          exercises: [
            {
              id: 'we-1',
              workoutSessionId: 'ws-1',
              exerciseId: 'ex-1',
              order: 0,
              sets: [
                { id: 's1', workoutExerciseId: 'we-1', setIndex: 0, weightKg: 80, reps: 10, rir: 2, completed: true },
                { id: 's2', workoutExerciseId: 'we-1', setIndex: 1, weightKg: 80, reps: 8, rir: 1, completed: false },
              ],
            },
          ],
        },
      ] as never);
      vi.mocked(prisma.trainingSession.findUnique).mockResolvedValueOnce({
        id: 'ts-1',
        planVersionId: 'pv-1',
        sessionIndex: 0,
        name: 'Day 1',
        targetDurationMinutes: 45,
        exercises: [{ id: 'tse-1', sessionId: 'ts-1', exerciseId: 'ex-1', sets: 3, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 }],
      } as never);
      const res = await request(app.getHttpServer())
        .get('/analytics/progress')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      expect(res.body.adherenceScore).toBeCloseTo(1 / 3);
      expect(res.body.adherenceScore).toBeGreaterThanOrEqual(0);
      expect(res.body.adherenceScore).toBeLessThanOrEqual(1);
    });

    it('adherence: mixed completed and incomplete sets in [0,1]', async () => {
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 3);
      vi.mocked(prisma.workoutSession.findMany).mockResolvedValueOnce([
        {
          id: 'ws-1',
          userId,
          planSessionId: 'ts-1',
          planVersionId: 'pv-1',
          startedAt: weekAgo,
          completedAt: new Date(),
          durationMinutes: 45,
          notes: null,
          exercises: [
            {
              id: 'we-1',
              workoutSessionId: 'ws-1',
              exerciseId: 'ex-1',
              order: 0,
              sets: [
                { id: 's1', workoutExerciseId: 'we-1', setIndex: 0, weightKg: 80, reps: 10, rir: 2, completed: true },
                { id: 's2', workoutExerciseId: 'we-1', setIndex: 1, weightKg: 80, reps: 8, rir: 1, completed: true },
                { id: 's3', workoutExerciseId: 'we-1', setIndex: 2, weightKg: 80, reps: 6, rir: 0, completed: false },
              ],
            },
          ],
        },
      ] as never);
      vi.mocked(prisma.trainingSession.findUnique).mockResolvedValueOnce({
        id: 'ts-1',
        planVersionId: 'pv-1',
        sessionIndex: 0,
        name: 'Day 1',
        targetDurationMinutes: 45,
        exercises: [{ id: 'tse-1', sessionId: 'ts-1', exerciseId: 'ex-1', sets: 3, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 }],
      } as never);
      const res = await request(app.getHttpServer())
        .get('/analytics/progress')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      expect(res.body.adherenceScore).toBeCloseTo(2 / 3);
      expect(res.body.adherenceScore).toBeGreaterThanOrEqual(0);
      expect(res.body.adherenceScore).toBeLessThanOrEqual(1);
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
