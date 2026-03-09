/**
 * Macro targets: protein 2g/kg, fat 0.8g/kg, carbs from remaining calories.
 * Carbs clamped to 0 when calorie target is too low. Deterministic; no I/O.
 */

import type { MacroTarget } from './nutrition-types.js';

const PROTEIN_PER_KG = 2;
const FAT_PER_KG = 0.8;
const CALORIES_PER_G_PROTEIN = 4;
const CALORIES_PER_G_CARBS = 4;
const CALORIES_PER_G_FAT = 9;

export interface MacroResult {
  macroTarget: MacroTarget;
  clamped: boolean;
}

/**
 * Protein (g) = 2 × weight_kg, Fat (g) = 0.8 × weight_kg.
 * Carbs (g) = max(0, (dailyCalories - proteinCal - fatCal) / 4).
 * If protein + fat calories exceed dailyCalories, carbs = 0 and clamped = true.
 * Returns null if weightKg missing or dailyCalories invalid.
 */
export function calculateMacroTargets(
  weightKg: number | null | undefined,
  dailyCalories: number,
): MacroResult | null {
  if (weightKg == null || weightKg <= 0 || dailyCalories <= 0) return null;
  const proteinG = Math.round(weightKg * PROTEIN_PER_KG);
  const fatG = Math.round(weightKg * FAT_PER_KG);
  const proteinCal = proteinG * CALORIES_PER_G_PROTEIN;
  const fatCal = fatG * CALORIES_PER_G_FAT;
  const remainingCal = Math.max(0, dailyCalories - proteinCal - fatCal);
  const carbsG = Math.round(remainingCal / CALORIES_PER_G_CARBS);
  const clamped = remainingCal <= 0;
  return {
    macroTarget: { proteinG, carbsG, fatG },
    clamped,
  };
}

/** Legacy: returns MacroTarget or null (use calculateMacroTargets for clamped flag). */
export function getMacroTarget(
  weightKg: number | null | undefined,
  dailyCalories: number,
): MacroTarget | null {
  const result = calculateMacroTargets(weightKg, dailyCalories);
  return result ? result.macroTarget : null;
}
