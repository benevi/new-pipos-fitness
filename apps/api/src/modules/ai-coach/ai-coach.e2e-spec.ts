import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { vi } from 'vitest';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../../app.module';
import { PrismaService } from '../../prisma/prisma.service';

describe('AI Coach (e2e)', () => {
  let app: INestApplication;
  let accessToken: string;

  const userId = 'user-ai-1';
  const mockUser = {
    id: userId,
    email: 'ai@example.com',
    emailNormalized: 'ai@example.com',
    passwordHash: 'hash',
    createdAt: new Date(),
    updatedAt: new Date(),
    heightCm: 180,
    weightKg: 80,
    age: 30,
    sex: 'male',
    trainingLevel: 'intermediate',
    preferredTrainingDays: 4,
    availableEquipment: ['eq-1'],
    trainingLocation: 'gym',
    goals: [{ type: 'muscle_gain', priority: 1 }],
    muscleFocus: [{ muscleId: 'chest', priority: 'grow' }],
    dislikedFoodIds: null,
  };

  const mockPrisma = {
    user: {
      findUnique: vi.fn().mockResolvedValue(mockUser),
    },
    trainingPlan: {
      findUnique: vi.fn().mockResolvedValue({
        id: 'tp-1',
        userId,
        currentVersionId: 'tpv-1',
        currentVersion: {
          id: 'tpv-1',
          planId: 'tp-1',
          version: 1,
          createdAt: new Date(),
          engineVersion: '0.1.0',
          objectiveScore: 0.8,
          sessions: [
            {
              id: 'ts-1',
              sessionIndex: 0,
              name: 'Day 1',
              targetDurationMinutes: 45,
              exercises: [
                {
                  id: 'tse-1',
                  sessionId: 'ts-1',
                  exerciseId: 'ex-from',
                  sets: 3,
                  repRangeMin: 8,
                  repRangeMax: 12,
                  restSeconds: 90,
                  rirTarget: 2,
                },
              ],
            },
          ],
        },
      }),
    },
    nutritionPlan: {
      findUnique: vi.fn().mockResolvedValue({
        id: 'np-1',
        userId,
        currentVersionId: 'npv-1',
        currentVersion: {
          id: 'npv-1',
          planId: 'np-1',
          version: 1,
          createdAt: new Date(),
          engineVersion: '0.1.0',
          days: [
            {
              id: 'nd-1',
              dayIndex: 0,
              meals: [
                { id: 'nm-1', nutritionDayId: 'nd-1', mealIndex: 0, name: 'Meal', templateId: null, items: [] },
              ],
            },
          ],
        },
      }),
    },
    workoutSession: {
      findMany: vi.fn().mockResolvedValue([]),
    },
    exerciseProgress: {
      upsert: vi.fn(),
    },
    trainingSession: {
      findUnique: vi.fn(),
    },
    exercise: {
      findUnique: vi.fn().mockImplementation((args: { where: { id: string } }) => {
        if (args.where.id !== 'ex-from') return Promise.resolve(null);
        return Promise.resolve({
          id: 'ex-from',
          movementPattern: 'push',
          place: 'gym',
          difficulty: 2,
        });
      }),
      findMany: vi.fn().mockImplementation((args: {
        where: { id?: { in?: string[]; not?: string }; movementPattern?: string; place?: string };
        include?: { equipment: boolean };
      }) => {
        const inIds = args.where?.id && 'in' in args.where.id ? args.where.id.in : undefined;
        if (inIds) {
          return Promise.resolve([
            {
              id: 'ex-from',
              movementPattern: 'push',
              place: 'gym',
              difficulty: 2,
              equipment: [{ equipmentItemId: 'eq-1' }],
            },
            {
              id: 'ex-to',
              movementPattern: 'push',
              place: 'gym',
              difficulty: 3,
              equipment: [{ equipmentItemId: 'eq-1' }],
            },
          ]);
        }
        return Promise.resolve([
          {
            id: 'ex-to',
            movementPattern: 'push',
            place: 'gym',
            difficulty: 3,
            equipment: [{ equipmentItemId: 'eq-1' }],
          },
        ]);
      }),
    },
    aIInteraction: {
      create: vi.fn().mockResolvedValue({ id: 'ai-int-1' }),
    },
  };

  beforeAll(async () => {
    process.env.JWT_ACCESS_SECRET = 'test-secret-ai';
    const jwtService = new JwtService({
      secret: 'test-secret-ai',
      signOptions: { expiresIn: '15m' },
    });
    accessToken = jwtService.sign({ userId: mockUser.id, email: mockUser.email });

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue(mockPrisma)
      .compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('returns 401 when no token', async () => {
    await request(app.getHttpServer()).post('/ai-coach/ask').send({ question: 'help' }).expect(401);
  });

  it('returns answer for generic question', async () => {
    const res = await request(app.getHttpServer())
      .post('/ai-coach/ask')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ question: 'What can you do for me?' })
      .expect(201);

    expect(res.body.responseType).toBe('answer');
    expect(typeof res.body.content).toBe('string');
    expect(res.body.proposal).toBeUndefined();
    expect(res.body.proposalStatus).toBeUndefined();
  });

  it('returns validated proposal with proposalStatus for swap question', async () => {
    const res = await request(app.getHttpServer())
      .post('/ai-coach/ask')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ question: 'Can you swap an exercise?' })
      .expect(201);

    expect(res.body.responseType).toBe('proposal');
    expect(res.body.proposal).toEqual({
      type: 'exercise_swap',
      fromExerciseId: 'ex-from',
      toExerciseId: 'ex-to',
    });
    expect(res.body.proposalStatus).toBe('valid');
  });
});
