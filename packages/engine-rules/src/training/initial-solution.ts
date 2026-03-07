/**
 * Greedy initial feasible plan. Deterministic: stable sort by exerciseId, fixed order.
 */

import type {
  TrainingEngineInput,
  TrainingEngineOutput,
  PlanSession,
  PlanExercise,
  CatalogExerciseSnapshot,
} from '@pipos/contracts';
import { buildCatalogMap, getCompatibleExercises } from './constraints.js';
import { defaultPlanExercise } from './scoring.js';
import { sortPlanExercises } from './utils.js';
import { MAX_EXERCISES_PER_SESSION } from './model.js';

export function buildInitialPlan(input: TrainingEngineInput): TrainingEngineOutput {
  const catalog = buildCatalogMap(input.catalog.exercises);
  const compatible = getCompatibleExercises(input, catalog);
  const sessions: PlanSession[] = [];
  const days = input.preferences.daysPerWeek;
  const targetMinutes = input.preferences.minutesPerSession;
  const exercisesPerSession = Math.min(
    MAX_EXERCISES_PER_SESSION,
    Math.max(1, Math.floor(compatible.length / Math.max(1, days))),
  );

  for (let i = 0; i < days; i++) {
    const start = i * exercisesPerSession;
    const slice = compatible.slice(start, start + exercisesPerSession);
    const exercises: PlanExercise[] = slice.map((ex) => defaultPlanExercise(ex.id));
    sessions.push({
      sessionIndex: i,
      name: `Day ${i + 1}`,
      targetDurationMinutes: targetMinutes,
      exercises: sortPlanExercises(exercises),
    });
  }

  return {
    metadata: {
      engineVersion: '0.0.1',
      objectiveScore: 0,
      constraintViolations: [],
    },
    weekPlan: { sessions },
  };
}
