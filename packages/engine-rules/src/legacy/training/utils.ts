/**
 * Pure utils: stable sort, tie-breaking by exerciseId.
 */

import type { PlanExercise } from '@pipos/contracts';

export function stableSortByExerciseId<T extends { exerciseId?: string }>(items: T[]): T[] {
  return [...items].sort((a, b) => (a.exerciseId ?? '').localeCompare(b.exerciseId ?? ''));
}

export function comparePlanExercises(a: PlanExercise, b: PlanExercise): number {
  return a.exerciseId.localeCompare(b.exerciseId);
}

/** Deterministic tie-break: prefer lower exerciseId. */
export function sortPlanExercises(exercises: PlanExercise[]): PlanExercise[] {
  return [...exercises].sort(comparePlanExercises);
}
