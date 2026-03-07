/**
 * Macro targets: protein 2g/kg, fat 0.8g/kg, carbs from remaining calories.
 * Deterministic; no I/O.
 */

import type { MacroTarget } from './nutrition-types.js';

const PROTEIN_PER_KG = 2;
const FAT_PER_KG = 0.8;
const CALORIES_PER_G_PROTEIN = 4;
const CALORIES_PER_G_CARBS = 4;
const CALORIES_PER_G_FAT = 9;

/**
 * Protein (g) = 2 × weight_kg, Fat (g) = 0.8 × weight_kg.
 * Carbs (g) = (dailyCalories - proteinCal - fatCal) / 4.
 * Returns null if weightKg missing or dailyCalories invalid.
 */
export function calculateMacroTargets(
  weightKg: number | null | undefined,
  dailyCalories: number,
): MacroTarget | null {
  if (weightKg == null || weightKg <= 0 || dailyCalories <= 0) return null;
  const proteinG = Math.round(weightKg * PROTEIN_PER_KG);
  const fatG = Math.round(weightKg * FAT_PER_KG);
  const proteinCal = proteinG * CALORIES_PER_G_PROTEIN;
  const fatCal = fatG * CALORIES_PER_G_FAT;
  const remainingCal = Math.max(0, dailyCalories - proteinCal - fatCal);
  const carbsG = Math.round(remainingCal / CALORIES_PER_G_CARBS);
  return { proteinG, carbsG, fatG };
}
