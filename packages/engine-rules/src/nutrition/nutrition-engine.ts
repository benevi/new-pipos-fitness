/**
 * Nutrition plan generator: calorie target (Mifflin-St Jeor + goal), macros, meal generation from templates.
 * Deterministic.
 */

import type {
  NutritionEngineInput,
  NutritionEngineOutput,
  NutritionDayOutput,
  NutritionMealOutput,
  NutritionEngineOutputMetadata,
} from '@pipos/contracts';
import { NutritionEngineInputSchema, NutritionGoalType } from '@pipos/contracts';
import { calculateDailyCalorieTarget, getActivityFactor } from './calorie-calculation.js';
import { calculateMacroTargets } from './macro-calculation.js';
import { generateMealsForDay } from './meal-generation.js';
import type { FoodRecord, MealTemplateRecord } from './nutrition-types.js';

export const NUTRITION_ENGINE_VERSION = '0.0.1';

export function getNutritionEngineVersion(): string {
  return NUTRITION_ENGINE_VERSION;
}

function mapGoal(goal: string): 'lose_fat' | 'build_muscle' | 'maintain' {
  if (goal === NutritionGoalType.BUILD_MUSCLE) return 'build_muscle';
  if (goal === NutritionGoalType.LOSE_FAT) return 'lose_fat';
  return 'maintain';
}

export function generateNutritionPlan(input: unknown): NutritionEngineOutput {
  const parsed = NutritionEngineInputSchema.safeParse(input);
  if (!parsed.success) {
    return {
      metadata: {
        engineVersion: NUTRITION_ENGINE_VERSION,
        dailyCalorieTarget: 2000,
        dailyMacroTarget: { proteinG: 140, carbsG: 200, fatG: 56 },
      },
      weekPlan: { days: [] },
    };
  }

  const { user, goal, dislikedFoodIds = [], catalog } = parsed.data;
  const weightKg = user.weightKg ?? 70;
  const trainingDays = user.preferredTrainingDays ?? 3;
  const activityFactor = getActivityFactor(trainingDays);
  const calorieTarget = calculateDailyCalorieTarget(
    { sex: user.sex, heightCm: user.heightCm, weightKg: user.weightKg, age: user.age },
    mapGoal(goal),
    activityFactor,
  ) ?? 2000;
  const macroResult = calculateMacroTargets(weightKg, calorieTarget);
  const macroTarget = macroResult?.macroTarget ?? {
    proteinG: Math.round(weightKg * 2),
    carbsG: Math.round(Math.max(0, (calorieTarget - (weightKg * 2 * 4) - (weightKg * 0.8 * 9)) / 4)),
    fatG: Math.round(weightKg * 0.8),
  };
  const macrosClamped = macroResult?.clamped ?? false;

  const foods: FoodRecord[] = catalog.foods.map((f) => ({
    id: f.id,
    name: f.name,
    caloriesPer100g: f.caloriesPer100g,
    proteinPer100g: f.proteinPer100g,
    carbsPer100g: f.carbsPer100g,
    fatPer100g: f.fatPer100g,
  }));
  const templates: MealTemplateRecord[] = catalog.mealTemplates.map((t) => ({
    id: t.id,
    name: t.name,
    foods: t.foods.map((f) => ({ foodId: f.foodId, quantityG: f.quantityG })),
  }));

  const days: NutritionDayOutput[] = [];
  for (let dayIndex = 0; dayIndex < 7; dayIndex++) {
    const meals = generateMealsForDay(
      templates,
      foods,
      dislikedFoodIds,
      calorieTarget,
      3,
      dayIndex,
    );
    days.push({
      dayIndex,
      meals: meals.map(
        (m): NutritionMealOutput => ({
          mealIndex: m.mealIndex,
          name: m.name,
          templateId: m.templateId,
          items: m.items.map((i) => ({ foodId: i.foodId, quantityG: i.quantityG })),
        }),
      ),
    });
  }

  const metadata: NutritionEngineOutputMetadata = {
    engineVersion: NUTRITION_ENGINE_VERSION,
    dailyCalorieTarget: calorieTarget,
    dailyMacroTarget: macroTarget,
    macrosClamped: macrosClamped || undefined,
  };

  return {
    metadata,
    weekPlan: { days },
  };
}
