import { describe, expect, it } from 'vitest';
import {
  ExerciseMusclesSchema,
  PlanExerciseResponseSchema,
  sortExerciseMuscles,
  TodayExerciseSchema,
} from '../index.js';

const ID = '11111111-1111-4111-8111-111111111111';
const REF = { id: ID, slug: 'back-squat', nameEs: 'Sentadilla trasera' };

/** Ejercicio de Hoy tal y como lo enviaba la API antes de la Fase 1 (sin `muscles`). */
const OLD_TODAY = {
  planExerciseId: ID,
  order: 1,
  exercise: REF,
  substitutedFrom: null,
  cuesEs: [],
  movementPattern: 'squat',
  loadType: 'weighted',
  role: 'main',
  restSeconds: 150,
  prescription: {
    action: 'hold',
    sets: 3,
    repMin: 6,
    repMax: 10,
    targetRir: 2,
    loadKg: 60,
    isDeload: false,
    rationale: [],
  },
  warmupSets: [],
  loggedSets: [],
};

const OLD_PLAN_EXERCISE = {
  id: ID,
  order: 1,
  exerciseId: ID,
  slug: REF.slug,
  nameEs: REF.nameEs,
  movementPattern: 'squat',
  loadType: 'weighted',
  role: 'main',
  sets: 3,
  repMin: 6,
  repMax: 10,
  targetRir: 2,
  restSeconds: 150,
  initialLoadKg: 60,
  initialLoadIsEstimate: true,
  warmupSets: [],
  estimatedMinutes: 12,
  rationale: [],
};

describe('músculos del ejercicio (ADR-0014, Fase 1)', () => {
  it('una respuesta antigua sin `muscles` sigue siendo válida y queda con lista vacía', () => {
    expect(TodayExerciseSchema.parse(OLD_TODAY).muscles).toEqual([]);
    expect(PlanExerciseResponseSchema.parse(OLD_PLAN_EXERCISE).muscles).toEqual([]);
  });

  it('acepta principales primero y, dentro de cada rol, el orden del enum', () => {
    const muscles = [
      { muscle: 'glutes', role: 'primary' },
      { muscle: 'quads', role: 'primary' },
      { muscle: 'lower_back', role: 'secondary' },
      { muscle: 'adductors', role: 'secondary' },
    ];
    expect(TodayExerciseSchema.parse({ ...OLD_TODAY, muscles }).muscles).toEqual(muscles);
    expect(PlanExerciseResponseSchema.parse({ ...OLD_PLAN_EXERCISE, muscles }).muscles).toEqual(muscles);
  });

  it('rechaza un secundario antes que un principal, el orden del enum invertido y repetidos', () => {
    const bad = (muscles: unknown) => ExerciseMusclesSchema.safeParse(muscles).success;
    expect(bad([{ muscle: 'triceps', role: 'secondary' }, { muscle: 'chest', role: 'primary' }])).toBe(false);
    expect(bad([{ muscle: 'quads', role: 'primary' }, { muscle: 'glutes', role: 'primary' }])).toBe(false);
    expect(bad([{ muscle: 'chest', role: 'primary' }, { muscle: 'chest', role: 'secondary' }])).toBe(false);
    expect(bad([{ muscle: 'chest', role: 'primary', fraction: 1 }])).toBe(false);
  });

  it('sortExerciseMuscles ordena y quita la fracción', () => {
    const sorted = sortExerciseMuscles([
      { muscle: 'triceps', role: 'secondary', fraction: 0.5 },
      { muscle: 'front_delts', role: 'secondary', fraction: 0.5 },
      { muscle: 'chest', role: 'primary', fraction: 1 },
    ] as const);
    expect(sorted).toEqual([
      { muscle: 'chest', role: 'primary' },
      { muscle: 'front_delts', role: 'secondary' },
      { muscle: 'triceps', role: 'secondary' },
    ]);
    expect(ExerciseMusclesSchema.safeParse(sorted).success).toBe(true);
  });
});
