/**
 * Objective function: muscle coverage, duration fit, movement balance, variety, difficulty. Pure, deterministic.
 */

import type {
  TrainingEngineInput,
  TrainingEngineOutput,
  CatalogExerciseSnapshot,
  PlanExercise,
} from '@pipos/contracts';
import { TrainingLevel } from '@pipos/contracts';
import { estimateSessionDurationMinutesSimple } from './duration.js';
import { computeWeeklySetsByMuscle } from './volume.js';
import { MUSCLE_ROLE_WEIGHT } from './model.js';

export function scorePlan(
  plan: TrainingEngineOutput,
  input: TrainingEngineInput,
  catalog: Map<string, CatalogExerciseSnapshot>,
): number {
  const w = {
    muscleAlignment: 0.3,
    durationFit: 0.2,
    movementBalance: 0.2,
    variety: 0.15,
    difficultyFit: 0.15,
  };
  let s = 0;
  s += w.muscleAlignment * scoreMuscleAlignment(plan, input, catalog);
  s += w.durationFit * scoreDurationFit(plan, input);
  s += w.movementBalance * scoreMovementBalance(plan, catalog);
  s += w.variety * scoreVariety(plan);
  s += w.difficultyFit * scoreDifficultyFit(plan, input, catalog);
  return Math.max(0, Math.min(1, s));
}

function scoreMuscleAlignment(
  plan: TrainingEngineOutput,
  input: TrainingEngineInput,
  catalog: Map<string, CatalogExerciseSnapshot>,
): number {
  const focus = new Map((input.muscleFocus ?? []).map((m) => [m.muscleId, m.priority]));
  const weekly = computeWeeklySetsByMuscle(plan.weekPlan, catalog);
  if (weekly.size === 0) return 0.5;
  let score = 0;
  let count = 0;
  for (const [muscleId, sets] of weekly) {
    const pri = focus.get(muscleId);
    if (pri === 'grow' && sets >= 6) score += 1;
    else if (pri === 'grow') score += sets / 8;
    else if (pri === 'maintain' && sets >= 4 && sets <= 12) score += 1;
    else if (pri === 'avoid' && sets <= 2) score += 1;
    else if (!pri) score += 0.7;
    count += 1;
  }
  return count === 0 ? 0.5 : score / count;
}

function scoreDurationFit(plan: TrainingEngineOutput, input: TrainingEngineInput): number {
  const maxMin = input.preferences.minutesPerSession;
  let total = 0;
  let n = 0;
  for (const session of plan.weekPlan.sessions) {
    const est = estimateSessionDurationMinutesSimple(session);
    const ratio = Math.min(1, maxMin / Math.max(1, est));
    total += ratio;
    n += 1;
  }
  return n === 0 ? 1 : total / n;
}

function scoreMovementBalance(
  plan: TrainingEngineOutput,
  catalog: Map<string, CatalogExerciseSnapshot>,
): number {
  const patternCounts = new Map<string, number>();
  for (const session of plan.weekPlan.sessions) {
    for (const pe of session.exercises) {
      const ex = catalog.get(pe.exerciseId);
      const p = ex?.movementPattern ?? 'other';
      patternCounts.set(p, (patternCounts.get(p) ?? 0) + 1);
    }
  }
  const total = [...patternCounts.values()].reduce((a, b) => a + b, 0);
  if (total === 0) return 1;
  const ideal = total / Math.max(1, patternCounts.size);
  const variance = [...patternCounts.values()].reduce(
    (acc, c) => acc + (c - ideal) * (c - ideal),
    0,
  );
  const norm = total * total;
  return norm === 0 ? 1 : Math.max(0, 1 - variance / norm);
}

function scoreVariety(plan: TrainingEngineOutput): number {
  const ids = new Set<string>();
  let total = 0;
  for (const session of plan.weekPlan.sessions) {
    for (const pe of session.exercises) {
      total += 1;
      ids.add(pe.exerciseId);
    }
  }
  if (total === 0) return 1;
  return ids.size / total;
}

function scoreDifficultyFit(
  plan: TrainingEngineOutput,
  input: TrainingEngineInput,
  catalog: Map<string, CatalogExerciseSnapshot>,
): number {
  const level = input.user.trainingLevel;
  const idealDiff =
    level === TrainingLevel.BEGINNER ? 1.5 : level === TrainingLevel.INTERMEDIATE ? 2.5 : 3.5;
  let sum = 0;
  let n = 0;
  for (const session of plan.weekPlan.sessions) {
    for (const pe of session.exercises) {
      const ex = catalog.get(pe.exerciseId);
      if (ex) {
        const d = Math.abs(ex.difficulty - idealDiff);
        sum += Math.max(0, 1 - d / 3);
        n += 1;
      }
    }
  }
  return n === 0 ? 1 : sum / n;
}

export function defaultPlanExercise(exerciseId: string): PlanExercise {
  return {
    exerciseId,
    sets: 3,
    repRangeMin: 8,
    repRangeMax: 12,
    restSeconds: 90,
    rirTarget: 2,
  };
}
