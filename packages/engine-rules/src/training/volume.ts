/**
 * Weekly volume by muscle (weighted by role). Pure.
 */

import type { TrainingEngineOutput, CatalogExerciseSnapshot } from '@pipos/contracts';
import { MUSCLE_ROLE_WEIGHT } from './model.js';

export function computeWeeklySetsByMuscle(
  weekPlan: TrainingEngineOutput['weekPlan'],
  catalog: Map<string, CatalogExerciseSnapshot>,
): Map<string, number> {
  const byMuscle = new Map<string, number>();
  for (const session of weekPlan.sessions) {
    for (const pe of session.exercises) {
      const ex = catalog.get(pe.exerciseId);
      if (!ex) continue;
      const sets = pe.sets;
      for (const m of ex.muscles) {
        const w = MUSCLE_ROLE_WEIGHT[m.role as keyof typeof MUSCLE_ROLE_WEIGHT] ?? 0.25;
        const prev = byMuscle.get(m.muscleId) ?? 0;
        byMuscle.set(m.muscleId, prev + sets * w);
      }
    }
  }
  return byMuscle;
}
