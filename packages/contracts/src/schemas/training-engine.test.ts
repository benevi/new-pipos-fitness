import { describe, it, expect } from 'vitest';
import {
  CatalogExerciseSnapshotSchema,
  TrainingEngineInputSchema,
  TrainingEngineOutputSchema,
  PlanExerciseSchema,
  GenerateTrainingPlanResponseSchema,
  TrainingSessionExerciseSchema,
} from './training-engine.js';
import { MuscleRole, TrainingLevel, TrainingLocation } from '../enums/index.js';

describe('CatalogExerciseSnapshotSchema', () => {
  it('accepts valid snapshot', () => {
    expect(
      CatalogExerciseSnapshotSchema.safeParse({
        id: 'e1',
        name: 'Squat',
        difficulty: 2,
        movementPattern: 'squat',
        place: TrainingLocation.GYM,
        equipmentIds: ['eq1'],
        muscles: [{ muscleId: 'm1', role: MuscleRole.PRIMARY }],
      }).success,
    ).toBe(true);
  });
  it('rejects missing equipmentIds', () => {
    expect(
      CatalogExerciseSnapshotSchema.safeParse({
        id: 'e1',
        name: 'Squat',
        difficulty: 2,
        place: TrainingLocation.GYM,
        muscles: [],
      }).success,
    ).toBe(false);
  });
});

describe('TrainingEngineInputSchema', () => {
  it('accepts minimal valid input', () => {
    expect(
      TrainingEngineInputSchema.safeParse({
        user: { trainingLevel: TrainingLevel.BEGINNER },
        preferences: {
          daysPerWeek: 3,
          minutesPerSession: 45,
          trainingLocation: TrainingLocation.GYM,
          availableEquipmentIds: ['eq1'],
        },
        catalog: { exercises: [] },
      }).success,
    ).toBe(true);
  });
  it('accepts full input with goals and muscleFocus', () => {
    expect(
      TrainingEngineInputSchema.safeParse({
        user: { trainingLevel: TrainingLevel.INTERMEDIATE, sex: 'male' },
        preferences: {
          daysPerWeek: 4,
          minutesPerSession: 60,
          trainingLocation: TrainingLocation.GYM,
          availableEquipmentIds: ['eq1', 'eq2'],
          dislikedExerciseIds: ['e-dislike'],
        },
        goals: [{ type: 'muscle_gain', priority: 1 }],
        muscleFocus: [{ muscleId: 'm1', priority: 'grow' }],
        catalog: { exercises: [] },
      }).success,
    ).toBe(true);
  });
});

describe('PlanExerciseSchema', () => {
  it('accepts valid plan exercise', () => {
    expect(
      PlanExerciseSchema.safeParse({
        exerciseId: 'e1',
        sets: 3,
        repRangeMin: 8,
        repRangeMax: 12,
        restSeconds: 90,
        rirTarget: 2,
      }).success,
    ).toBe(true);
  });
  it('rejects repRangeMin > repRangeMax', () => {
    expect(
      PlanExerciseSchema.safeParse({
        exerciseId: 'e1',
        sets: 3,
        repRangeMin: 12,
        repRangeMax: 8,
        restSeconds: 90,
        rirTarget: 0,
      }).success,
    ).toBe(false);
  });
});

describe('TrainingEngineOutputSchema', () => {
  it('accepts valid output with empty violations', () => {
    expect(
      TrainingEngineOutputSchema.safeParse({
        metadata: {
          engineVersion: '0.0.1',
          objectiveScore: 0.85,
          constraintViolations: [],
        },
        weekPlan: {
          sessions: [
            {
              sessionIndex: 0,
              name: 'Day 1',
              targetDurationMinutes: 45,
              exercises: [
                {
                  exerciseId: 'e1',
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
      }).success,
    ).toBe(true);
  });
  it('accepts output with constraint violations', () => {
    expect(
      TrainingEngineOutputSchema.safeParse({
        metadata: {
          engineVersion: '0.0.1',
          objectiveScore: 0,
          constraintViolations: [{ code: 'NO_EXERCISES', message: 'No compatible exercises' }],
        },
        weekPlan: { sessions: [] },
      }).success,
    ).toBe(true);
  });
});

describe('Phase 5 API schemas', () => {
  it('GenerateTrainingPlanResponseSchema accepts valid response', () => {
    expect(
      GenerateTrainingPlanResponseSchema.safeParse({
        plan: {
          id: '550e8400-e29b-41d4-a716-446655440000',
          userId: '550e8400-e29b-41d4-a716-446655440001',
          createdAt: '2025-01-01T00:00:00.000Z',
          currentVersionId: '550e8400-e29b-41d4-a716-446655440002',
        },
        version: {
          id: '550e8400-e29b-41d4-a716-446655440002',
          planId: '550e8400-e29b-41d4-a716-446655440000',
          version: 1,
          createdAt: '2025-01-01T00:00:00.000Z',
          engineVersion: '0.0.1',
          objectiveScore: 0.8,
          sessions: [
            {
              id: '550e8400-e29b-41d4-a716-446655440003',
              planVersionId: '550e8400-e29b-41d4-a716-446655440002',
              sessionIndex: 0,
              name: 'Day 1',
              targetDurationMinutes: 45,
              exercises: [
                {
                  id: '550e8400-e29b-41d4-a716-446655440004',
                  sessionId: '550e8400-e29b-41d4-a716-446655440003',
                  exerciseId: 'ex1',
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
      }).success,
    ).toBe(true);
  });
  it('TrainingSessionExerciseSchema rejects invalid rirTarget', () => {
    expect(
      TrainingSessionExerciseSchema.safeParse({
        id: '550e8400-e29b-41d4-a716-446655440004',
        sessionId: '550e8400-e29b-41d4-a716-446655440003',
        exerciseId: 'ex1',
        sets: 3,
        repRangeMin: 8,
        repRangeMax: 12,
        restSeconds: 90,
        rirTarget: 5,
      }).success,
    ).toBe(false);
  });
});
