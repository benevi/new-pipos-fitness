import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { vi } from 'vitest';
import { TrainingPlansService } from './training-plans.service';
import { PrismaService } from '../../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { AnalyticsService } from '../analytics/analytics.service';
import * as engineRules from '@pipos/engine-rules';

vi.mock('@pipos/engine-rules', () => ({
  generateTrainingPlan: vi.fn(),
}));

describe('TrainingPlansService', () => {
  let service: TrainingPlansService;

  const mockPrisma = {
    trainingPlan: {
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    trainingPlanVersion: {
      findFirst: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
    },
    trainingSession: { create: vi.fn() },
    trainingSessionExercise: { create: vi.fn() },
    exercise: {
      findMany: vi.fn().mockResolvedValue([]),
    },
  };

  const mockUsersService = {
    getMe: vi.fn().mockResolvedValue({
      id: 'user-1',
      trainingLevel: 'beginner',
      preferredTrainingDays: 3,
      availableEquipment: ['eq1'],
      trainingLocation: 'gym',
      goals: [],
      muscleFocus: [],
    }),
  };

  const mockAnalyticsService = {
    getProgress: vi.fn().mockResolvedValue({
      exercises: [],
      adherenceScore: 0.9,
      fatigueDetected: false,
    }),
  };

  beforeEach(async () => {
    vi.mocked(engineRules.generateTrainingPlan).mockReturnValue({
      metadata: {
        engineVersion: '0.0.1',
        objectiveScore: 0.8,
        constraintViolations: [],
      },
      weekPlan: { sessions: [] },
    });
    vi.clearAllMocks();
    mockUsersService.getMe.mockResolvedValue({
      id: 'user-1',
      trainingLevel: 'beginner',
      preferredTrainingDays: 3,
      availableEquipment: ['eq1'],
      trainingLocation: 'gym',
      goals: [],
      muscleFocus: [],
    });
    mockAnalyticsService.getProgress.mockResolvedValue({
      exercises: [],
      adherenceScore: 0.9,
      fatigueDetected: false,
    });
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TrainingPlansService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: UsersService, useValue: mockUsersService },
        { provide: AnalyticsService, useValue: mockAnalyticsService },
      ],
    }).compile();
    service = module.get<TrainingPlansService>(TrainingPlansService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('generatePlan', () => {
    it('throws BadRequestException and does not persist when engine returns constraint violations', async () => {
      vi.mocked(engineRules.generateTrainingPlan).mockReturnValue({
        metadata: {
          engineVersion: '0.0.1',
          objectiveScore: 0,
          constraintViolations: [
            { code: 'SESSION_DURATION_EXCEEDED', message: 'Session 0 estimated 60 min > 45 min' },
          ],
        },
        weekPlan: { sessions: [] },
      });
      mockPrisma.trainingPlan.findUnique.mockResolvedValue(null);

      await expect(service.generatePlan('user-1')).rejects.toThrow(BadRequestException);

      expect(mockPrisma.trainingPlanVersion.create).not.toHaveBeenCalled();
      expect(mockPrisma.trainingPlan.update).not.toHaveBeenCalled();
    });

    it('includes constraintViolations in error response', async () => {
      const violations = [{ code: 'INVALID_INPUT', message: 'Validation failed' }];
      vi.mocked(engineRules.generateTrainingPlan).mockReturnValue({
        metadata: {
          engineVersion: '0.0.1',
          objectiveScore: 0,
          constraintViolations: violations,
        },
        weekPlan: { sessions: [] },
      });
      mockPrisma.trainingPlan.findUnique.mockResolvedValue(null);

      try {
        await service.generatePlan('user-1');
      } catch (e) {
        expect(e.getResponse()).toMatchObject({
          code: 'PLAN_CONSTRAINT_VIOLATIONS',
          constraintViolations: violations,
        });
      }
    });
  });

  describe('getCurrent', () => {
    it('throws when no plan exists', async () => {
      mockPrisma.trainingPlan.findUnique.mockResolvedValue(null);
      await expect(service.getCurrent('user-1')).rejects.toThrow(NotFoundException);
    });

    it('throws when plan has no current version', async () => {
      mockPrisma.trainingPlan.findUnique.mockResolvedValue({
        id: 'plan-1',
        userId: 'user-1',
        currentVersionId: null,
        currentVersion: null,
      });
      await expect(service.getCurrent('user-1')).rejects.toThrow(NotFoundException);
    });
  });

  describe('getVersions', () => {
    it('returns empty array when no plan', async () => {
      mockPrisma.trainingPlan.findUnique.mockResolvedValue(null);
      expect(await service.getVersions('user-1')).toEqual([]);
    });
  });

  describe('getVersionById', () => {
    it('throws when version not found', async () => {
      mockPrisma.trainingPlanVersion.findFirst.mockResolvedValue(null);
      await expect(service.getVersionById('user-1', 'v1')).rejects.toThrow(NotFoundException);
    });
  });
});
