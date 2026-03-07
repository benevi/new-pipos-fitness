/**
 * Training engine internal types. Aligned with @pipos/contracts training-engine schemas.
 */

import type {
  TrainingEngineInput,
  TrainingEngineOutput,
  PlanSession,
  PlanExercise,
  CatalogExerciseSnapshot,
  ConstraintViolation,
} from '@pipos/contracts';

export type { TrainingEngineInput, TrainingEngineOutput, PlanSession, PlanExercise };
export type { CatalogExerciseSnapshot, ConstraintViolation };

export const MUSCLE_ROLE_WEIGHT = {
  primary: 1,
  secondary: 0.5,
  stabilizer: 0.25,
} as const;

export const MAX_EXERCISES_PER_SESSION = 10;
export const MIN_COMPOUND_PER_SESSION = 1;
export const ESTIMATED_SECONDS_PER_SET = 50; // work + rest portion per set
export const AVOID_MUSCLE_MAX_SETS = 2;
export const WEEKLY_SETS_CAP_BEGINNER = 12;
export const WEEKLY_SETS_CAP_INTERMEDIATE = 16;
export const WEEKLY_SETS_CAP_ADVANCED = 20;
export const WEEKLY_SETS_FLOOR = 4;
export const LOCAL_SEARCH_MAX_ITERATIONS = 50;
