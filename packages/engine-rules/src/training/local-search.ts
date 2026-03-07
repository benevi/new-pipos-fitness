/**
 * Deterministic local search: swap exercise, move exercise, adjust sets. No randomness.
 */

import type {
  TrainingEngineInput,
  TrainingEngineOutput,
  PlanSession,
  PlanExercise,
  CatalogExerciseSnapshot,
} from '@pipos/contracts';
import { buildCatalogMap, getCompatibleExercises, validatePlan } from './constraints.js';
import { scorePlan, defaultPlanExercise } from './scoring.js';
import { sortPlanExercises } from './utils.js';
import { LOCAL_SEARCH_MAX_ITERATIONS } from './model.js';

export function improvePlan(
  plan: TrainingEngineOutput,
  input: TrainingEngineInput,
): TrainingEngineOutput {
  const catalog = buildCatalogMap(input.catalog.exercises);
  const compatible = getCompatibleExercises(input, catalog);
  if (compatible.length === 0) return plan;

  let current = clonePlan(plan);
  let currentScore = scorePlan(current, input, catalog);
  let improved = true;
  let it = 0;

  while (improved && it < LOCAL_SEARCH_MAX_ITERATIONS) {
    improved = false;
    it += 1;

    const next = tryImprove(current, input, catalog, compatible);
    const nextScore = scorePlan(next, input, catalog);
    const nextValid = validatePlan(next, input, catalog);
    if (nextValid.ok && nextScore > currentScore) {
      current = next;
      currentScore = nextScore;
      improved = true;
    }
  }

  const violations = validatePlan(current, input, catalog);
  return {
    ...current,
    metadata: {
      ...current.metadata,
      objectiveScore: currentScore,
      constraintViolations: violations.violations,
    },
  };
}

function clonePlan(plan: TrainingEngineOutput): TrainingEngineOutput {
  return {
    metadata: { ...plan.metadata },
    weekPlan: {
      sessions: plan.weekPlan.sessions.map((s) => ({
        ...s,
        exercises: s.exercises.map((e) => ({ ...e })),
      })),
    },
  };
}

function tryImprove(
  plan: TrainingEngineOutput,
  input: TrainingEngineInput,
  catalog: Map<string, CatalogExerciseSnapshot>,
  compatible: CatalogExerciseSnapshot[],
): TrainingEngineOutput {
  const next = clonePlan(plan);
  const sessions = next.weekPlan.sessions;

  for (let si = 0; si < sessions.length; si++) {
    const session = sessions[si];
    for (let ei = 0; ei < session.exercises.length; ei++) {
      for (const candidate of compatible) {
        if (session.exercises[ei].exerciseId === candidate.id) continue;
        const swapped = clonePlan(next);
        swapped.weekPlan.sessions[si].exercises[ei] = defaultPlanExercise(candidate.id);
        swapped.weekPlan.sessions[si].exercises = sortPlanExercises(
          swapped.weekPlan.sessions[si].exercises,
        );
        const v = validatePlan(swapped, input, catalog);
        if (v.ok && scorePlan(swapped, input, catalog) > scorePlan(next, input, catalog)) {
          return swapped;
        }
      }
    }
  }

  for (let si = 0; si < sessions.length; si++) {
    for (let sj = 0; sj < sessions.length; sj++) {
      if (si === sj) continue;
      const src = sessions[si].exercises;
      const dst = sessions[sj].exercises;
      if (src.length <= 1 || dst.length >= 10) continue;
      for (let ei = 0; ei < src.length; ei++) {
        const moved = clonePlan(next);
        const [ex] = moved.weekPlan.sessions[si].exercises.splice(ei, 1);
        moved.weekPlan.sessions[sj].exercises.push(ex);
        moved.weekPlan.sessions[si].exercises = sortPlanExercises(
          moved.weekPlan.sessions[si].exercises,
        );
        moved.weekPlan.sessions[sj].exercises = sortPlanExercises(
          moved.weekPlan.sessions[sj].exercises,
        );
        const v = validatePlan(moved, input, catalog);
        if (v.ok && scorePlan(moved, input, catalog) > scorePlan(next, input, catalog)) {
          return moved;
        }
      }
    }
  }

  return next;
}
