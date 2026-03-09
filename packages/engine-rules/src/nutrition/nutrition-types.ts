/**
 * Internal types for nutrition engine (no DB dependency).
 */

export interface NutritionUser {
  sex?: string;
  heightCm?: number | null;
  weightKg?: number | null;
  age?: number | null;
  preferredTrainingDays?: number | null;
}

export interface FoodRecord {
  id: string;
  name: string;
  caloriesPer100g: number;
  proteinPer100g: number;
  carbsPer100g: number;
  fatPer100g: number;
}

export interface MealTemplateRecord {
  id: string;
  name: string;
  foods: Array<{ foodId: string; quantityG: number }>;
}

export interface MacroTarget {
  proteinG: number;
  carbsG: number;
  fatG: number;
}
