/**
 * Hard constraints and plan validation. Pure.
 */

import type {
  TrainingEngineInput,
  TrainingEngineOutput,
  PlanSession,
  CatalogExerciseSnapshot,
  ConstraintViolation,
} from '@pipos/contracts';
import { TrainingLevel } from '@pipos/contracts';
import { estimateSessionDurationMinutesSimple } from './duration.js';
import { computeWeeklySetsByMuscle } from './volume.js';
import {
  MAX_EXERCISES_PER_SESSION,
  MIN_COMPOUND_PER_SESSION,
  AVOID_MUSCLE_MAX_SETS,
  WEEKLY_SETS_CAP_BEGINNER,
  WEEKLY_SETS_CAP_INTERMEDIATE,
  WEEKLY_SETS_CAP_ADVANCED,
} from './model.js';

export function buildCatalogMap(
  exercises: CatalogExerciseSnapshot[],
): Map<string, CatalogExerciseSnapshot> {
  const m = new Map<string, CatalogExerciseSnapshot>();
  for (const e of exercises) m.set(e.id, e);
  return m;
}

export function getCompatibleExercises(
  input: TrainingEngineInput,
  catalog: Map<string, CatalogExerciseSnapshot>,
): CatalogExerciseSnapshot[] {
  const { preferences, catalog: cat } = input;
  const loc = preferences.trainingLocation;
  const equip = new Set(preferences.availableEquipmentIds);
  const disliked = new Set(preferences.dislikedExerciseIds ?? []);
  const out: CatalogExerciseSnapshot[] = [];
  for (const ex of cat.exercises) {
    if (disliked.has(ex.id)) continue;
    if (ex.place !== loc) continue;
    const hasEquipment = ex.equipmentIds.length === 0 || ex.equipmentIds.some((id) => equip.has(id));
    if (!hasEquipment) continue;
    out.push(ex);
  }
  return out.sort((a, b) => a.id.localeCompare(b.id));
}

function weeklySetsCap(level: string): number {
  switch (level) {
    case TrainingLevel.BEGINNER:
      return WEEKLY_SETS_CAP_BEGINNER;
    case TrainingLevel.INTERMEDIATE:
      return WEEKLY_SETS_CAP_INTERMEDIATE;
    case TrainingLevel.ADVANCED:
      return WEEKLY_SETS_CAP_ADVANCED;
    default:
      return WEEKLY_SETS_CAP_INTERMEDIATE;
  }
}

export function validatePlan(
  plan: TrainingEngineOutput,
  input: TrainingEngineInput,
  catalog: Map<string, CatalogExerciseSnapshot>,
): { ok: boolean; violations: ConstraintViolation[] } {
  const violations: ConstraintViolation[] = [];
  const maxDuration = input.preferences.minutesPerSession;
  const muscleFocus = new Map((input.muscleFocus ?? []).map((m) => [m.muscleId, m.priority]));
  const level = input.user.trainingLevel;
  const cap = weeklySetsCap(level);

  for (const session of plan.weekPlan.sessions) {
    const est = estimateSessionDurationMinutesSimple(session);
    if (est > maxDuration) {
      violations.push({
        code: 'SESSION_DURATION_EXCEEDED',
        message: `Session ${session.sessionIndex} estimated ${est} min > ${maxDuration} min`,
      });
    }
    if (session.exercises.length > MAX_EXERCISES_PER_SESSION) {
      violations.push({
        code: 'EXERCISES_PER_SESSION_EXCEEDED',
        message: `Session ${session.sessionIndex} has ${session.exercises.length} exercises`,
      });
    }
    let compounds = 0;
    for (const pe of session.exercises) {
      const ex = catalog.get(pe.exerciseId);
      if (ex?.movementPattern) compounds += 1;
    }
    if (compounds < MIN_COMPOUND_PER_SESSION && session.exercises.length > 0) {
      violations.push({
        code: 'MIN_COMPOUND_PER_SESSION',
        message: `Session ${session.sessionIndex} has fewer than ${MIN_COMPOUND_PER_SESSION} compound movement(s)`,
      });
    }
  }

  const weeklyByMuscle = computeWeeklySetsByMuscle(plan.weekPlan, catalog);
  for (const [muscleId, sets] of weeklyByMuscle) {
    const priority = muscleFocus.get(muscleId);
    if (priority === 'avoid' && sets > AVOID_MUSCLE_MAX_SETS) {
      violations.push({
        code: 'AVOID_MUSCLE_EXCEEDED',
        message: `Muscle ${muscleId} (avoid) has ${sets} weighted sets`,
      });
    }
    if (sets > cap) {
      violations.push({
        code: 'WEEKLY_VOLUME_EXCEEDED',
        message: `Muscle ${muscleId} has ${sets} weighted sets (cap ${cap})`,
      });
    }
  }

  return {
    ok: violations.length === 0,
    violations,
  };
}
