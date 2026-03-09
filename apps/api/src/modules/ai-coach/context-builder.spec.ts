import { NotFoundException } from '@nestjs/common';
import { vi } from 'vitest';
import { ContextBuilderService } from './context-builder';
import { UsersService } from '../users/users.service';
import { TrainingPlansService } from '../training-plans/training-plans.service';
import { NutritionPlansService } from '../nutrition-plans/nutrition-plans.service';
import { AnalyticsService } from '../analytics/analytics.service';

describe('ContextBuilderService', () => {
  let service: ContextBuilderService;

  const mockUsersService = {
    getMe: vi.fn(),
  };
  const mockTrainingPlansService = {
    getCurrent: vi.fn(),
  };
  const mockNutritionPlansService = {
    getCurrent: vi.fn(),
  };
  const mockAnalyticsService = {
    getProgress: vi.fn(),
  };

  beforeEach(async () => {
    vi.clearAllMocks();

    mockUsersService.getMe.mockResolvedValue({
      id: 'user-1',
      sex: 'male',
      age: 30,
      heightCm: 180,
      weightKg: 80,
      trainingLevel: 'intermediate',
      preferredTrainingDays: 4,
      trainingLocation: 'gym',
      availableEquipment: ['eq-1', 'eq-2'],
      goals: [{ type: 'muscle_gain', priority: 1 }],
      muscleFocus: [{ muscleId: 'chest', priority: 'grow' }],
    });
    mockTrainingPlansService.getCurrent.mockResolvedValue({
      version: {
        id: 'tpv-1',
        sessions: [
          {
            exercises: [{ exerciseId: 'ex-2' }, { exerciseId: 'ex-1' }],
          },
          {
            exercises: [{ exerciseId: 'ex-1' }],
          },
        ],
      },
    });
    mockNutritionPlansService.getCurrent.mockResolvedValue({
      version: {
        id: 'npv-1',
        days: [{ meals: [{}, {}] }, { meals: [{}] }],
      },
    });
    mockAnalyticsService.getProgress.mockResolvedValue({
      exercises: [{ exerciseId: 'ex-1' }, { exerciseId: 'ex-2' }],
      adherenceScore: 0.8,
      fatigueDetected: false,
    });

    service = new ContextBuilderService(
      mockUsersService as unknown as UsersService,
      mockTrainingPlansService as unknown as TrainingPlansService,
      mockNutritionPlansService as unknown as NutritionPlansService,
      mockAnalyticsService as unknown as AnalyticsService,
    );
  });

  it('builds trimmed context from profile, plans, and progress', async () => {
    const context = await service.build('user-1');

    expect(context.profile.id).toBe('user-1');
    expect(context.profile.availableEquipmentIds).toEqual(['eq-1', 'eq-2']);
    expect(context.profile.goalsCount).toBe(1);
    expect(context.trainingPlanSummary).toEqual({
      versionId: 'tpv-1',
      sessionsCount: 2,
      exercisesCount: 3,
      exerciseIds: ['ex-1', 'ex-2'],
    });
    expect(context.nutritionPlanSummary).toEqual({
      versionId: 'npv-1',
      daysCount: 2,
      mealsCount: 3,
    });
    expect(context.progressMetrics).toEqual({
      adherenceScore: 0.8,
      fatigueDetected: false,
      trackedExercisesCount: 2,
    });
  });

  it('sets summaries to null when plans do not exist', async () => {
    mockTrainingPlansService.getCurrent.mockRejectedValue(new NotFoundException());
    mockNutritionPlansService.getCurrent.mockRejectedValue(new NotFoundException());

    const context = await service.build('user-1');
    expect(context.trainingPlanSummary).toBeNull();
    expect(context.nutritionPlanSummary).toBeNull();
  });
});
