/**
 * Adapt plan using progress: reduce sets only for exercises targeting fatigued muscles. Pure.
 * Uses catalog ExerciseMuscle mapping for localized adaptation. Deterministic.
 */

import type {
  TrainingEngineOutput,
  TrainingEngineProgress,
  PlanSession,
  PlanExercise,
  CatalogExerciseSnapshot,
} from '@pipos/contracts';

const ADHERENCE_DELOAD_THRESHOLD = 0.7;
const FATIGUE_THRESHOLD = 0.5;
const MIN_SETS_AFTER_REDUCTION = 1;

/**
 * Identify muscle IDs that are associated with fatigued exercises (exerciseHistory fatigueScore > threshold).
 */
function getFatiguedMuscleIds(
  progress: TrainingEngineProgress,
  catalog: Map<string, CatalogExerciseSnapshot>,
): Set<string> {
  const fatiguedMuscleIds = new Set<string>();
  for (const item of progress.exerciseHistory) {
    if ((item.fatigueScore ?? 0) <= FATIGUE_THRESHOLD) continue;
    const ex = catalog.get(item.exerciseId);
    if (!ex) continue;
    for (const m of ex.muscles) {
      fatiguedMuscleIds.add(m.muscleId);
    }
  }
  return fatiguedMuscleIds;
}

/**
 * True if this plan exercise targets any of the given muscle IDs (via catalog).
 */
function exerciseTargetsMuscles(
  pe: PlanExercise,
  muscleIds: Set<string>,
  catalog: Map<string, CatalogExerciseSnapshot>,
): boolean {
  const ex = catalog.get(pe.exerciseId);
  if (!ex) return false;
  return ex.muscles.some((m) => muscleIds.has(m.muscleId));
}

/**
 * Localized adaptation: reduce sets only for exercises that target fatigued muscles.
 * If low adherence (global), reduce sets for all exercises. Deterministic.
 */
export function adaptPlanToProgress(
  plan: TrainingEngineOutput,
  progress: TrainingEngineProgress | undefined,
  catalog: Map<string, CatalogExerciseSnapshot>,
): TrainingEngineOutput {
  if (!progress) return plan;

  const lowAdherence =
    progress.adherenceScore != null && progress.adherenceScore < ADHERENCE_DELOAD_THRESHOLD;
  const fatiguedMuscleIds = getFatiguedMuscleIds(progress, catalog);

  const shouldReduceAll = lowAdherence;
  const shouldReduceLocal = !shouldReduceAll && fatiguedMuscleIds.size > 0;

  if (!shouldReduceAll && !shouldReduceLocal) return plan;

  const sessions: PlanSession[] = plan.weekPlan.sessions.map((s) => ({
    ...s,
    exercises: s.exercises.map((e: PlanExercise) => {
      const reduce =
        shouldReduceAll ||
        (shouldReduceLocal && exerciseTargetsMuscles(e, fatiguedMuscleIds, catalog));
      return {
        ...e,
        sets: reduce ? Math.max(MIN_SETS_AFTER_REDUCTION, e.sets - 1) : e.sets,
      };
    }),
  }));

  return {
    ...plan,
    weekPlan: { sessions },
  };
}
