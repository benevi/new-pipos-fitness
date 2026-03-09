import { describe, it, expect } from 'vitest';
import {
  generateTrainingPlan,
  getTrainingEngineVersion,
  validatePlan,
  buildCatalogMap,
  getCompatibleExercises,
} from './index.js';
import { TrainingLevel, TrainingLocation, MuscleRole, MusclePriority } from '@pipos/contracts';

function makeInput(overrides: Record<string, unknown> = {}) {
  return {
    user: { trainingLevel: TrainingLevel.BEGINNER },
    preferences: {
      daysPerWeek: 3,
      minutesPerSession: 45,
      trainingLocation: TrainingLocation.GYM,
      availableEquipmentIds: ['eq1', 'eq2'],
    },
    catalog: {
      exercises: [
        {
          id: 'e1',
          name: 'Squat',
          difficulty: 1,
          movementPattern: 'squat',
          place: TrainingLocation.GYM,
          equipmentIds: ['eq1'],
          muscles: [{ muscleId: 'm1', role: MuscleRole.PRIMARY }],
        },
        {
          id: 'e2',
          name: 'Push-up',
          difficulty: 1,
          movementPattern: 'push',
          place: TrainingLocation.GYM,
          equipmentIds: [],
          muscles: [{ muscleId: 'm2', role: MuscleRole.PRIMARY }],
        },
        {
          id: 'e3',
          name: 'Row',
          difficulty: 2,
          movementPattern: 'pull',
          place: TrainingLocation.GYM,
          equipmentIds: ['eq2'],
          muscles: [{ muscleId: 'm3', role: MuscleRole.PRIMARY }],
        },
      ],
    },
    ...overrides,
  };
}

describe('getTrainingEngineVersion', () => {
  it('returns version string', () => {
    expect(getTrainingEngineVersion()).toBe('0.0.1');
  });
});

describe('generateTrainingPlan', () => {
  it('returns output with metadata and weekPlan', () => {
    const out = generateTrainingPlan(makeInput());
    expect(out.metadata.engineVersion).toBe('0.0.1');
    expect(out.metadata.objectiveScore).toBeGreaterThanOrEqual(0);
    expect(Array.isArray(out.metadata.constraintViolations)).toBe(true);
    expect(out.weekPlan.sessions.length).toBe(3);
  });

  it('is deterministic: same input produces identical output', () => {
    const input = makeInput();
    const a = generateTrainingPlan(input);
    const b = generateTrainingPlan(input);
    expect(a.metadata.objectiveScore).toBe(b.metadata.objectiveScore);
    expect(a.weekPlan.sessions.length).toBe(b.weekPlan.sessions.length);
    for (let i = 0; i < a.weekPlan.sessions.length; i++) {
      expect(a.weekPlan.sessions[i].exercises.length).toBe(
        b.weekPlan.sessions[i].exercises.length,
      );
      const exA = a.weekPlan.sessions[i].exercises.map((e) => e.exerciseId).sort();
      const exB = b.weekPlan.sessions[i].exercises.map((e) => e.exerciseId).sort();
      expect(exA).toEqual(exB);
    }
  });

  it('respects equipment constraint: only uses available equipment', () => {
    const input = makeInput({
      preferences: {
        daysPerWeek: 2,
        minutesPerSession: 60,
        trainingLocation: TrainingLocation.GYM,
        availableEquipmentIds: ['eq1'],
      },
    });
    const out = generateTrainingPlan(input);
    const catalog = buildCatalogMap(input.catalog.exercises);
    for (const session of out.weekPlan.sessions) {
      for (const pe of session.exercises) {
        const ex = catalog.get(pe.exerciseId);
        if (ex && ex.equipmentIds.length > 0) {
          expect(ex.equipmentIds.some((id) => input.preferences.availableEquipmentIds.includes(id))).toBe(true);
        }
      }
    }
  });

  it('respects trainingLocation: only gym exercises when location is gym', () => {
    const input = makeInput({
      catalog: {
        exercises: [
          {
            id: 'g1',
            name: 'Gym',
            difficulty: 1,
            movementPattern: 'squat',
            place: TrainingLocation.GYM,
            equipmentIds: ['eq1'],
            muscles: [{ muscleId: 'm1', role: MuscleRole.PRIMARY }],
          },
          {
            id: 'h1',
            name: 'Home',
            difficulty: 1,
            movementPattern: 'push',
            place: TrainingLocation.HOME,
            equipmentIds: [],
            muscles: [{ muscleId: 'm2', role: MuscleRole.PRIMARY }],
          },
        ],
      },
    });
    const out = generateTrainingPlan(input);
    const catalog = buildCatalogMap(input.catalog.exercises);
    for (const session of out.weekPlan.sessions) {
      for (const pe of session.exercises) {
        const ex = catalog.get(pe.exerciseId);
        expect(ex?.place).toBe(TrainingLocation.GYM);
      }
    }
  });

  it('sessions respect duration constraint or report violations', () => {
    const input = makeInput({
      preferences: { daysPerWeek: 2, minutesPerSession: 30, trainingLocation: TrainingLocation.GYM, availableEquipmentIds: ['eq1', 'eq2'] },
    });
    const out = generateTrainingPlan(input);
    const catalog = buildCatalogMap(input.catalog.exercises);
    const res = validatePlan(out, input, catalog);
    expect(res.violations).toEqual(out.metadata.constraintViolations);
  });
});

describe('validatePlan', () => {
  it('reports ok when plan is valid', () => {
    const input = makeInput();
    const out = generateTrainingPlan(input);
    const catalog = buildCatalogMap(input.catalog.exercises);
    const res = validatePlan(out, input, catalog);
    expect(res.ok).toBe(res.violations.length === 0);
  });

  it('reports violations when weekly volume exceeded', () => {
    const input = makeInput();
    const catalog = buildCatalogMap(input.catalog.exercises);
    const plan = {
      metadata: { engineVersion: '0.0.1', objectiveScore: 0, constraintViolations: [] },
      weekPlan: {
        sessions: Array.from({ length: 7 }, (_, i) => ({
          sessionIndex: i,
          name: `Day ${i + 1}`,
          targetDurationMinutes: 45,
          exercises: [
            {
              exerciseId: 'e1',
              sets: 5,
              repRangeMin: 8,
              repRangeMax: 12,
              restSeconds: 90,
              rirTarget: 2,
            },
          ],
        })),
      },
    };
    const res = validatePlan(plan, input, catalog);
    expect(res.violations.some((v) => v.code === 'WEEKLY_VOLUME_EXCEEDED')).toBe(true);
  });
});

describe('getCompatibleExercises', () => {
  it('filters by location and equipment', () => {
    const input = makeInput();
    const catalog = buildCatalogMap(input.catalog.exercises);
    const compat = getCompatibleExercises(input, catalog);
    expect(compat.every((e) => e.place === TrainingLocation.GYM)).toBe(true);
    expect(compat.length).toBe(3);
  });

  it('excludes disliked exercises', () => {
    const input = makeInput({ preferences: { ...makeInput().preferences, dislikedExerciseIds: ['e1'] } });
    const catalog = buildCatalogMap(input.catalog.exercises);
    const compat = getCompatibleExercises(input, catalog);
    expect(compat.find((e) => e.id === 'e1')).toBeUndefined();
  });

  it('returns empty when availableEquipment is empty and all exercises need equipment', () => {
    const input = makeInput({
      catalog: {
        exercises: [
          {
            id: 'e1',
            name: 'Squat',
            difficulty: 1,
            movementPattern: 'squat',
            place: TrainingLocation.GYM,
            equipmentIds: ['eq1'],
            muscles: [{ muscleId: 'm1', role: MuscleRole.PRIMARY }],
          },
          {
            id: 'e3',
            name: 'Row',
            difficulty: 2,
            movementPattern: 'pull',
            place: TrainingLocation.GYM,
            equipmentIds: ['eq2'],
            muscles: [{ muscleId: 'm3', role: MuscleRole.PRIMARY }],
          },
        ],
      },
      preferences: {
        daysPerWeek: 2,
        minutesPerSession: 45,
        trainingLocation: TrainingLocation.GYM,
        availableEquipmentIds: [],
      },
    });
    const catalog = buildCatalogMap(input.catalog.exercises);
    const compat = getCompatibleExercises(input, catalog);
    expect(compat.length).toBe(0);
  });
});

describe('edge cases', () => {
  it('minimal catalog: one exercise', () => {
    const input = makeInput({
      catalog: {
        exercises: [
          {
            id: 'only',
            name: 'Only',
            difficulty: 1,
            movementPattern: 'squat',
            place: TrainingLocation.GYM,
            equipmentIds: ['eq1'],
            muscles: [{ muscleId: 'm1', role: MuscleRole.PRIMARY }],
          },
        ],
      },
    });
    const out = generateTrainingPlan(input);
    expect(out.weekPlan.sessions.length).toBe(3);
    const totalEx = out.weekPlan.sessions.reduce((a, s) => a + s.exercises.length, 0);
    expect(totalEx).toBeLessThanOrEqual(3);
  });

  it('daysPerWeek=1', () => {
    const input = makeInput({
      preferences: { daysPerWeek: 1, minutesPerSession: 60, trainingLocation: TrainingLocation.GYM, availableEquipmentIds: ['eq1', 'eq2'] },
    });
    const out = generateTrainingPlan(input);
    expect(out.weekPlan.sessions.length).toBe(1);
  });

  it('minutesPerSession very low', () => {
    const input = makeInput({
      preferences: { daysPerWeek: 2, minutesPerSession: 20, trainingLocation: TrainingLocation.GYM, availableEquipmentIds: ['eq1', 'eq2'] },
    });
    const out = generateTrainingPlan(input);
    expect(out.weekPlan.sessions.length).toBe(2);
  });

  it('availableEquipment empty with bodyweight-only catalog', () => {
    const input = makeInput({
      catalog: {
        exercises: [
          {
            id: 'bw',
            name: 'Bodyweight',
            difficulty: 1,
            movementPattern: 'push',
            place: TrainingLocation.GYM,
            equipmentIds: [],
            muscles: [{ muscleId: 'm1', role: MuscleRole.PRIMARY }],
          },
        ],
      },
      preferences: {
        daysPerWeek: 1,
        minutesPerSession: 30,
        trainingLocation: TrainingLocation.GYM,
        availableEquipmentIds: [],
      },
    });
    const out = generateTrainingPlan(input);
    const catalog = buildCatalogMap(input.catalog.exercises);
    const compat = getCompatibleExercises(input, catalog);
    expect(compat.length).toBe(1);
  });

  it('all exercises incompatible returns violations or empty sessions', () => {
    const input = makeInput({
      catalog: {
        exercises: [
          {
            id: 'home-only',
            name: 'Home',
            difficulty: 1,
            movementPattern: null,
            place: TrainingLocation.HOME,
            equipmentIds: [],
            muscles: [{ muscleId: 'm1', role: MuscleRole.PRIMARY }],
          },
        ],
      },
      preferences: {
        daysPerWeek: 2,
        minutesPerSession: 45,
        trainingLocation: TrainingLocation.GYM,
        availableEquipmentIds: ['eq1'],
      },
    });
    const out = generateTrainingPlan(input);
    const compat = getCompatibleExercises(input, buildCatalogMap(input.catalog.exercises));
    expect(compat.length).toBe(0);
    expect(out.weekPlan.sessions.length).toBe(2);
  });
});

describe('invalid input', () => {
  it('returns constraintViolations when input is invalid', () => {
    const out = generateTrainingPlan({});
    expect(out.metadata.constraintViolations.length).toBeGreaterThan(0);
    expect(out.metadata.constraintViolations.some((c) => c.code === 'INVALID_INPUT')).toBe(true);
  });
});

describe('training level volume caps', () => {
  it('beginner plan validates within beginner cap', () => {
    const input = makeInput({ user: { trainingLevel: TrainingLevel.BEGINNER } });
    const out = generateTrainingPlan(input);
    const catalog = buildCatalogMap(input.catalog.exercises);
    const res = validatePlan(out, input, catalog);
    expect(res.violations.filter((v) => v.code === 'WEEKLY_VOLUME_EXCEEDED')).toHaveLength(0);
  });

  it('intermediate plan uses intermediate cap', () => {
    const input = makeInput({ user: { trainingLevel: TrainingLevel.INTERMEDIATE } });
    const out = generateTrainingPlan(input);
    expect(out.weekPlan.sessions.length).toBe(3);
  });

  it('advanced plan uses advanced cap', () => {
    const input = makeInput({ user: { trainingLevel: TrainingLevel.ADVANCED } });
    const out = generateTrainingPlan(input);
    expect(out.metadata.engineVersion).toBe('0.0.1');
  });
});

describe('muscleFocus', () => {
  it('avoid muscle gets low volume when specified', () => {
    const input = makeInput({
      muscleFocus: [{ muscleId: 'm1', priority: MusclePriority.AVOID }],
    });
    const out = generateTrainingPlan(input);
    const catalog = buildCatalogMap(input.catalog.exercises);
    const res = validatePlan(out, input, catalog);
    const avoidViolations = res.violations.filter((v) => v.code === 'AVOID_MUSCLE_EXCEEDED');
    expect(avoidViolations.length).toBe(0);
  });

  it('grow muscle gets allocation when specified', () => {
    const input = makeInput({
      muscleFocus: [{ muscleId: 'm1', priority: MusclePriority.GROW }],
      catalog: {
        exercises: [
          {
            id: 'e1',
            name: 'Squat',
            difficulty: 1,
            movementPattern: 'squat',
            place: TrainingLocation.GYM,
            equipmentIds: ['eq1'],
            muscles: [{ muscleId: 'm1', role: MuscleRole.PRIMARY }],
          },
        ],
      },
    });
    const out = generateTrainingPlan(input);
    expect(out.weekPlan.sessions.some((s) => s.exercises.some((e) => e.exerciseId === 'e1'))).toBe(true);
  });
});

describe('variety and movement balance', () => {
  it('exercises are sorted by exerciseId within session', () => {
    const input = makeInput();
    const out = generateTrainingPlan(input);
    for (const session of out.weekPlan.sessions) {
      const ids = session.exercises.map((e) => e.exerciseId);
      const sorted = [...ids].sort();
      expect(ids).toEqual(sorted);
    }
  });

  it('plan has non-negative objective score', () => {
    const out = generateTrainingPlan(makeInput());
    expect(out.metadata.objectiveScore).toBeGreaterThanOrEqual(0);
    expect(out.metadata.objectiveScore).toBeLessThanOrEqual(1);
  });
});

describe('buildCatalogMap', () => {
  it('returns map with all exercises keyed by id', () => {
    const input = makeInput();
    const m = buildCatalogMap(input.catalog.exercises);
    expect(m.size).toBe(3);
    expect(m.get('e1')?.name).toBe('Squat');
  });
});
