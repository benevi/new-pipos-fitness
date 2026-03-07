/**
 * Progress analytics: e1RM, volume, adherence, fatigue. Pure, deterministic.
 */

import type { SetRecord } from '@pipos/contracts';

/** e1RM = weightKg * (1 + reps / 30). Returns null if insufficient data. */
export function computeE1RM(weightKg: number | null, reps: number | null): number | null {
  if (weightKg == null || weightKg <= 0 || reps == null || reps <= 0) return null;
  return weightKg * (1 + reps / 30);
}

/** Best e1RM per exercise from sets. Sets: array of { exerciseId, weightKg, reps } per set. */
export function getBestE1RMPerExercise(
  setsByExercise: Map<string, Array<{ weightKg: number | null; reps: number | null }>>,
): Map<string, number> {
  const out = new Map<string, number>();
  for (const [exerciseId, sets] of setsByExercise) {
    let best = 0;
    for (const s of sets) {
      const e1 = computeE1RM(s.weightKg, s.reps);
      if (e1 != null && e1 > best) best = e1;
    }
    if (best > 0) out.set(exerciseId, best);
  }
  return out;
}

/** Weekly volume per exercise: sum of weightKg * reps for completed sets. */
export function computeVolumePerExercise(
  setsByExercise: Map<string, Array<{ weightKg: number | null; reps: number | null; completed?: boolean }>>,
): Map<string, number> {
  const out = new Map<string, number>();
  for (const [exerciseId, sets] of setsByExercise) {
    let vol = 0;
    for (const s of sets) {
      if (s.completed === false) continue;
      const w = s.weightKg ?? 0;
      const r = s.reps ?? 0;
      vol += w * r;
    }
    if (vol > 0) out.set(exerciseId, vol);
  }
  return out;
}

/** Adherence: completed_sets / planned_sets. Clamp to [0, 1]. */
export function computeAdherence(completedSets: number, plannedSets: number): number | null {
  if (plannedSets <= 0) return null;
  const ratio = completedSets / plannedSets;
  return Math.max(0, Math.min(1, ratio));
}

/**
 * Fatigue: true if any set has rir <= 0 or reps drop > 20% across sets.
 * Sets assumed ordered by setIndex. Compares consecutive completed sets' reps.
 */
export function detectFatigue(
  sets: Array<{ reps: number | null; rir: number | null; completed?: boolean }>,
): boolean {
  for (const s of sets) {
    if (s.rir != null && s.rir <= 0) return true;
  }
  const repsList = sets
    .filter((s) => s.completed !== false && s.reps != null && s.reps > 0)
    .map((s) => s.reps as number);
  if (repsList.length < 2) return false;
  for (let i = 1; i < repsList.length; i++) {
    const prev = repsList[i - 1];
    const curr = repsList[i];
    if (prev > 0 && curr < prev * 0.8) return true;
  }
  return false;
}

/** Fatigue score per exercise: 1 if fatigue detected, 0 otherwise. */
export function fatigueScorePerExercise(
  setsByExercise: Map<string, Array<{ reps: number | null; rir: number | null; completed?: boolean }>>,
): Map<string, number> {
  const out = new Map<string, number>();
  for (const [exerciseId, sets] of setsByExercise) {
    out.set(exerciseId, detectFatigue(sets) ? 1 : 0);
  }
  return out;
}

/** Volume trend: compare lastWeekVolume to previousWeekVolume. */
export function volumeTrend(
  lastWeekVolume: number,
  previousWeekVolume: number,
): 'up' | 'down' | 'stable' {
  if (previousWeekVolume <= 0) return lastWeekVolume > 0 ? 'up' : 'stable';
  const ratio = lastWeekVolume / previousWeekVolume;
  if (ratio > 1.05) return 'up';
  if (ratio < 0.95) return 'down';
  return 'stable';
}
