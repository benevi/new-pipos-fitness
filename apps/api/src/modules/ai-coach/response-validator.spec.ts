import { vi } from 'vitest';
import { ResponseValidatorService } from './response-validator';
import { PrismaService } from '../../prisma/prisma.service';
import type { AICoachContext } from './context-builder';

describe('ResponseValidatorService', () => {
  let service: ResponseValidatorService;

  const mockPrisma = {
    exercise: {
      findMany: vi.fn(),
    },
  };

  const baseContext: AICoachContext = {
    profile: {
      id: 'user-1',
      sex: 'male',
      age: 30,
      heightCm: 180,
      weightKg: 80,
      trainingLevel: 'intermediate',
      preferredTrainingDays: 4,
      trainingLocation: 'gym',
      availableEquipmentIds: ['eq-1', 'eq-2'],
      goalsCount: 1,
      muscleFocusCount: 1,
    },
    trainingPlanSummary: {
      versionId: 'tpv-1',
      sessionsCount: 2,
      exercisesCount: 3,
      exerciseIds: ['ex-from'],
    },
    nutritionPlanSummary: null,
    progressMetrics: {
      adherenceScore: 0.8,
      fatigueDetected: false,
      trackedExercisesCount: 1,
    },
  };

  beforeEach(async () => {
    vi.clearAllMocks();
    service = new ResponseValidatorService(mockPrisma as unknown as PrismaService);
  });

  it('returns proposalStatus valid for accepted exercise_swap', async () => {
    mockPrisma.exercise.findMany.mockResolvedValue([
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
        equipment: [{ equipmentItemId: 'eq-2' }],
      },
    ]);

    const result = await service.validate(
      {
        responseType: 'proposal',
        content: 'swap',
        proposal: {
          type: 'exercise_swap',
          fromExerciseId: 'ex-from',
          toExerciseId: 'ex-to',
        },
      },
      baseContext,
    );

    expect(result.proposalStatus).toBe('valid');
    expect(result.response.proposalStatus).toBe('valid');
    expect(result.rejectionReason).toBeUndefined();
  });

  it('returns proposalStatus rejected with reason for invalid exercise', async () => {
    mockPrisma.exercise.findMany.mockResolvedValue([
      {
        id: 'ex-from',
        movementPattern: 'push',
        place: 'gym',
        difficulty: 2,
        equipment: [],
      },
    ]);

    const result = await service.validate(
      {
        responseType: 'proposal',
        content: 'swap',
        proposal: {
          type: 'exercise_swap',
          fromExerciseId: 'ex-from',
          toExerciseId: 'missing',
        },
      },
      baseContext,
    );

    expect(result.proposalStatus).toBe('rejected');
    expect(result.response.proposalStatus).toBe('rejected');
    expect(result.rejectionReason).toBe('Referenced exercise does not exist');
  });

  it('returns rejected when equipment is unavailable', async () => {
    mockPrisma.exercise.findMany.mockResolvedValue([
      {
        id: 'ex-from',
        movementPattern: 'push',
        place: 'gym',
        difficulty: 2,
        equipment: [],
      },
      {
        id: 'ex-to',
        movementPattern: 'push',
        place: 'gym',
        difficulty: 2,
        equipment: [{ equipmentItemId: 'eq-missing' }],
      },
    ]);

    const result = await service.validate(
      {
        responseType: 'proposal',
        content: 'swap',
        proposal: {
          type: 'exercise_swap',
          fromExerciseId: 'ex-from',
          toExerciseId: 'ex-to',
        },
      },
      baseContext,
    );

    expect(result.proposalStatus).toBe('rejected');
    expect(result.rejectionReason).toBe('Equipment not available for replacement');
  });

  it('returns rejected when movement-pattern breaks', async () => {
    mockPrisma.exercise.findMany.mockResolvedValue([
      {
        id: 'ex-from',
        movementPattern: 'push',
        place: 'gym',
        difficulty: 2,
        equipment: [],
      },
      {
        id: 'ex-to',
        movementPattern: 'pull',
        place: 'gym',
        difficulty: 2,
        equipment: [],
      },
    ]);

    const result = await service.validate(
      {
        responseType: 'proposal',
        content: 'swap',
        proposal: {
          type: 'exercise_swap',
          fromExerciseId: 'ex-from',
          toExerciseId: 'ex-to',
        },
      },
      baseContext,
    );

    expect(result.proposalStatus).toBe('rejected');
    expect(result.rejectionReason).toBe('Replacement breaks movement-pattern constraints');
  });

  it('passes through non-proposal responses without status', async () => {
    const result = await service.validate(
      { responseType: 'answer', content: 'hello' },
      baseContext,
    );

    expect(result.proposalStatus).toBeUndefined();
    expect(result.response).toEqual({ responseType: 'answer', content: 'hello' });
  });
});
