import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import * as bcrypt from 'bcrypt';
import { vi } from 'vitest';
import { AppModule } from '../../app.module';
import { PrismaService } from '../../prisma/prisma.service';

describe('Workouts (e2e)', () => {
  let app: INestApplication;
  let accessToken: string;

  const userId = 'user-workout-1';
  const mockUser = {
    id: userId,
    email: 'workout@example.com',
    emailNormalized: 'workout@example.com',
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

  const workoutSessionId = 'ws-1';
  const workoutExerciseId = 'we-1';
  const exerciseId = 'ex-bench';

  let sessionCompletedAt: Date | null = null;
  let sessionDurationMinutes: number | null = null;
  let sessionNotes: string | null = null;
  const sessionExercises: Array<{ id: string; workoutSessionId: string; exerciseId: string; order: number; sets: unknown[] }> = [];

  beforeAll(async () => {
    mockUser.passwordHash = await bcrypt.hash('password123', 10);
    let sessionPlanVersionId: string | null = null;
    const mockWorkoutSession = () => ({
      id: workoutSessionId,
      userId,
      planSessionId: null,
      planVersionId: sessionPlanVersionId,
      startedAt: new Date(),
      completedAt: sessionCompletedAt,
      durationMinutes: sessionDurationMinutes,
      notes: sessionNotes,
      exercises: sessionExercises.map((e) => ({ ...e, sets: e.sets })),
    });
    const mockWorkoutExercise = {
      id: workoutExerciseId,
      workoutSessionId,
      exerciseId,
      order: 0,
      sets: [] as unknown[],
    };

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue({
        user: {
          findUnique: vi.fn().mockResolvedValue(mockUser),
          findFirst: vi.fn(),
          create: vi.fn(),
          update: vi.fn(),
        },
        refreshToken: {
          findFirst: vi.fn().mockResolvedValue({
            id: 'rt-1',
            userId: mockUser.id,
            expiresAt: new Date(Date.now() + 86400000),
            revokedAt: null,
            user: mockUser,
          }),
          create: vi.fn().mockResolvedValue({ id: 'rt-new', userId: mockUser.id }),
          update: vi.fn(),
          delete: vi.fn(),
        },
        workoutSession: {
          create: vi.fn().mockImplementation((args: { data: { userId: string; planSessionId?: string | null; planVersionId?: string | null } }) => {
            sessionPlanVersionId = args.data.planVersionId ?? null;
            return Promise.resolve({
              ...mockWorkoutSession(),
              ...args.data,
              exercises: [],
            });
          }),
          findUnique: vi.fn().mockImplementation((args: { where: { id: string } }) => {
            if (args.where.id === workoutSessionId) return Promise.resolve(mockWorkoutSession());
            if (args.where.id === 'ws-other-user')
              return Promise.resolve({ ...mockWorkoutSession(), id: 'ws-other-user', userId: 'other-user-id', completedAt: null });
            return Promise.resolve(null);
          }),
          findMany: vi.fn().mockImplementation(() =>
            Promise.resolve([mockWorkoutSession()]),
          ),
          update: vi.fn().mockImplementation((args: { data: { completedAt?: Date; durationMinutes?: number; notes?: string | null } }) => {
            sessionCompletedAt = args.data.completedAt ?? sessionCompletedAt;
            sessionDurationMinutes = args.data.durationMinutes ?? sessionDurationMinutes;
            sessionNotes = args.data.notes ?? sessionNotes;
            return Promise.resolve(mockWorkoutSession());
          }),
        },
        workoutExercise: {
          create: vi.fn().mockImplementation(() => {
            sessionExercises.push({ ...mockWorkoutExercise, sets: [] });
            return Promise.resolve({
              ...mockWorkoutExercise,
              sets: [],
            });
          }),
          findFirst: vi.fn().mockImplementation(() => {
            const ex = sessionExercises[sessionExercises.length - 1] ?? mockWorkoutExercise;
            return Promise.resolve({ ...ex, sets: ex.sets ?? [] });
          }),
        },
        workoutSet: {
          create: vi.fn().mockImplementation(() => {
            const lastEx = sessionExercises[sessionExercises.length - 1];
            if (lastEx) lastEx.sets.push({ setIndex: lastEx.sets.length, weightKg: 80, reps: 10, rir: 2, completed: true });
            return Promise.resolve({
              id: 'set-1',
              workoutExerciseId,
              setIndex: 0,
              weightKg: 80,
              reps: 10,
              rir: 2,
              completed: true,
            });
          }),
        },
        trainingSession: {
          findUnique: vi.fn().mockImplementation((args: { where: { id: string } }) =>
            args.where.id === 'ts-1'
              ? Promise.resolve({ id: 'ts-1', planVersionId: 'pv-1' })
              : Promise.resolve(null),
          ),
        },
        exercise: {
          findUnique: vi.fn().mockResolvedValue({ id: exerciseId }),
        },
      })
      .compile();

    app = moduleFixture.createNestApplication();
    void moduleFixture.get(PrismaService);
    await app.init();

    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'workout@example.com', password: 'password123' })
      .expect(200);
    accessToken = loginRes.body.accessToken;
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /workouts/start', () => {
    it('returns 201 and workout session', async () => {
      const res = await request(app.getHttpServer())
        .post('/workouts/start')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({})
        .expect(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body.userId).toBe(userId);
      expect(res.body.exercises).toEqual([]);
      expect(res.body.startedAt).toBeDefined();
    });

    it('accepts planSessionId in body and returns planVersionId', async () => {
      const res = await request(app.getHttpServer())
        .post('/workouts/start')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ planSessionId: 'ts-1' })
        .expect(201);
      expect(res.body.planVersionId).toBe('pv-1');
    });

    it('returns planVersionId null when starting without planSessionId', async () => {
      const res = await request(app.getHttpServer())
        .post('/workouts/start')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({})
        .expect(201);
      expect(res.body.planVersionId).toBeNull();
    });
  });

  describe('POST /workouts/:id/exercises', () => {
    it('adds exercise and returns session', async () => {
      const res = await request(app.getHttpServer())
        .post(`/workouts/${workoutSessionId}/exercises`)
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ exerciseId })
        .expect(201);
      expect(res.body.id).toBe(workoutSessionId);
      expect(Array.isArray(res.body.exercises)).toBe(true);
    });
  });

  describe('POST /workouts/:id/exercises/:workoutExerciseId/sets', () => {
    it('logs set and returns session', async () => {
      const res = await request(app.getHttpServer())
        .post(`/workouts/${workoutSessionId}/exercises/${workoutExerciseId}/sets`)
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ weightKg: 80, reps: 10, rir: 2, completed: true })
        .expect(201);
      expect(res.body.id).toBe(workoutSessionId);
    });

    it('returns 404 when workoutExerciseId does not belong to session', async () => {
      await request(app.getHttpServer())
        .post(`/workouts/${workoutSessionId}/exercises/non-existent-we-id/sets`)
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ weightKg: 80, reps: 10 })
        .expect(404);
    });

    it('returns 403 when session belongs to another user', async () => {
      await request(app.getHttpServer())
        .post('/workouts/ws-other-user/exercises/we-1/sets')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ weightKg: 80, reps: 10 })
        .expect(403);
    });
  });

  describe('POST /workouts/:id/finish', () => {
    it('finishes session', async () => {
      const res = await request(app.getHttpServer())
        .post(`/workouts/${workoutSessionId}/finish`)
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ durationMinutes: 45, notes: 'Good session' })
        .expect(201);
      expect(res.body.completedAt).toBeDefined();
      expect(res.body.durationMinutes).toBe(45);
      expect(res.body.notes).toBe('Good session');
    });
  });

  describe('GET /workouts/history', () => {
    it('returns recent sessions', async () => {
      const res = await request(app.getHttpServer())
        .get('/workouts/history')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });
});
