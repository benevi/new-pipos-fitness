/**
 * Session duration estimation. Pure.
 */

import type { PlanSession, CatalogExerciseSnapshot } from '@pipos/contracts';
import { ESTIMATED_SECONDS_PER_SET } from './model.js';

export function estimateSessionDurationMinutes(
  session: PlanSession,
  catalog: Map<string, CatalogExerciseSnapshot>,
): number {
  let totalSeconds = 0;
  for (const pe of session.exercises) {
    const ex = catalog.get(pe.exerciseId);
    const sets = pe.sets;
    const avgReps = (pe.repRangeMin + pe.repRangeMax) / 2;
    const workPerSet = Math.min(60, avgReps * 4);
    totalSeconds += sets * (workPerSet + pe.restSeconds);
  }
  return Math.ceil(totalSeconds / 60);
}

export function estimateSessionDurationMinutesSimple(session: PlanSession): number {
  let totalSeconds = 0;
  for (const pe of session.exercises) {
    totalSeconds += pe.sets * (ESTIMATED_SECONDS_PER_SET + pe.restSeconds);
  }
  return Math.ceil(totalSeconds / 60);
}
