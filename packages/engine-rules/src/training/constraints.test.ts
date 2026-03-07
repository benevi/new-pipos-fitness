import { describe, it, expect } from 'vitest';
import { buildCatalogMap, getCompatibleExercises, validatePlan } from './constraints.js';
import { TrainingLevel, TrainingLocation, MuscleRole } from '@pipos/contracts';

describe('buildCatalogMap', () => {
  it('builds map by exercise id', () => {
    const exercises = [
      {
        id: 'ex1',
        name: 'Ex1',
        difficulty: 1,
        movementPattern: null,
        place: TrainingLocation.GYM,
        equipmentIds: [],
        muscles: [{ muscleId: 'm1', role: MuscleRole.PRIMARY }],
      },
    ];
    const m = buildCatalogMap(exercises);
    expect(m.size).toBe(1);
    expect(m.get('ex1')?.name).toBe('Ex1');
  });
});

describe('validatePlan', () => {
  it('reports MIN_COMPOUND_PER_SESSION when session has no compound', () => {
    const input = {
      user: { trainingLevel: TrainingLevel.BEGINNER },
      preferences: {
        daysPerWeek: 1,
        minutesPerSession: 45,
        trainingLocation: TrainingLocation.GYM,
        availableEquipmentIds: ['eq1'],
      },
      catalog: {
        exercises: [
          {
            id: 'e1',
            name: 'Isolation',
            difficulty: 1,
            movementPattern: null,
            place: TrainingLocation.GYM,
            equipmentIds: ['eq1'],
            muscles: [{ muscleId: 'm1', role: MuscleRole.PRIMARY }],
          },
        ],
      },
    };
    const catalog = buildCatalogMap(input.catalog.exercises);
    const plan = {
      metadata: { engineVersion: '0.0.1', objectiveScore: 0, constraintViolations: [] },
      weekPlan: {
        sessions: [
          {
            sessionIndex: 0,
            name: 'Day 1',
            targetDurationMinutes: 45,
            exercises: [
              { exerciseId: 'e1', sets: 3, repRangeMin: 10, repRangeMax: 12, restSeconds: 60, rirTarget: 2 },
            ],
          },
        ],
      },
    };
    const res = validatePlan(plan, input, catalog);
    expect(res.violations.some((v) => v.code === 'MIN_COMPOUND_PER_SESSION')).toBe(true);
  });
});
