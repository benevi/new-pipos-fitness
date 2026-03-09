/**
 * Mifflin-St Jeor BMR and goal-adjusted daily calorie target.
 * Activity factor from training days per week. Deterministic; no I/O.
 */

import type { NutritionUser } from './nutrition-types.js';

/** Activity factor by training days per week: 0–1 → 1.2, 2–3 → 1.375, 4–5 → 1.55, 6–7 → 1.725. */
export function getActivityFactor(trainingDaysPerWeek: number): number {
  const n = Math.max(0, Math.min(7, Math.round(trainingDaysPerWeek)));
  if (n <= 1) return 1.2;
  if (n <= 3) return 1.375;
  if (n <= 5) return 1.55;
  return 1.725;
}

const DEFAULT_ACTIVITY_FACTOR = 1.375;

/**
 * BMR via Mifflin-St Jeor (kcal/day).
 * Men: (10 × weight_kg) + (6.25 × height_cm) − (5 × age) + 5
 * Women: (10 × weight_kg) + (6.25 × height_cm) − (5 × age) − 161
 */
export function calculateBMR(user: NutritionUser): number | null {
  const { weightKg, heightCm, age, sex } = user;
  if (weightKg == null || weightKg <= 0 || heightCm == null || heightCm <= 0 || age == null || age <= 0) {
    return null;
  }
  const base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  const isMale = sex === 'male';
  return base + (isMale ? 5 : -161);
}

/**
 * TDEE = BMR × activity factor. Returns null if BMR cannot be computed.
 */
export function calculateTDEE(user: NutritionUser, activityFactor: number = DEFAULT_ACTIVITY_FACTOR): number | null {
  const bmr = calculateBMR(user);
  if (bmr == null) return null;
  return Math.round(bmr * activityFactor);
}

export type NutritionGoal = 'lose_fat' | 'build_muscle' | 'maintain';

const GOAL_MULTIPLIERS: Record<NutritionGoal, number> = {
  lose_fat: 0.85,
  build_muscle: 1.1,
  maintain: 1,
};

/**
 * Daily calorie target from TDEE and goal.
 * lose_fat: -15%, build_muscle: +10%, maintain: baseline.
 * Returns null if TDEE cannot be computed.
 */
export function calculateDailyCalorieTarget(
  user: NutritionUser,
  goal: NutritionGoal,
  activityFactor: number = DEFAULT_ACTIVITY_FACTOR,
): number | null {
  const tdee = calculateTDEE(user, activityFactor);
  if (tdee == null) return null;
  const mult = GOAL_MULTIPLIERS[goal];
  return Math.round(tdee * mult);
}
