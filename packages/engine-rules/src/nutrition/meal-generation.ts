/**
 * Generate daily meals from meal templates to meet calorie and macro targets.
 * Respects dislikedFoodIds. Deterministic (stable sort by id).
 */

import type { FoodRecord, MealTemplateRecord, MacroTarget } from './nutrition-types.js';

export interface MealItem {
  foodId: string;
  quantityG: number;
}

export interface GeneratedMeal {
  mealIndex: number;
  name: string;
  templateId: string | null;
  items: MealItem[];
}

function caloriesForFood(food: FoodRecord, quantityG: number): number {
  return (food.caloriesPer100g * quantityG) / 100;
}
function proteinForFood(food: FoodRecord, quantityG: number): number {
  return (food.proteinPer100g * quantityG) / 100;
}
function carbsForFood(food: FoodRecord, quantityG: number): number {
  return (food.carbsPer100g * quantityG) / 100;
}
function fatForFood(food: FoodRecord, quantityG: number): number {
  return (food.fatPer100g * quantityG) / 100;
}

/**
 * Build food map and filter out disliked. Templates that reference only disliked foods are skipped.
 */
function buildFoodMap(
  foods: FoodRecord[],
  dislikedFoodIds: string[],
): Map<string, FoodRecord> {
  const set = new Set(dislikedFoodIds);
  const map = new Map<string, FoodRecord>();
  for (const f of foods) {
    if (!set.has(f.id)) map.set(f.id, f);
  }
  return map;
}

/**
 * Scale template portion so one full template contributes ~targetCaloriesPerMeal (e.g. daily/3).
 * Returns items with quantityG scaled. Uses template's default proportions.
 */
function scaleTemplateToCalories(
  template: MealTemplateRecord,
  foodMap: Map<string, FoodRecord>,
  targetCaloriesPerMeal: number,
): MealItem[] {
  let totalCal = 0;
  const parts: Array<{ foodId: string; quantityG: number; calPer100g: number }> = [];
  for (const { foodId, quantityG } of template.foods) {
    const food = foodMap.get(foodId);
    if (!food) continue;
    const cal = caloriesForFood(food, quantityG);
    totalCal += cal;
    parts.push({ foodId, quantityG, calPer100g: food.caloriesPer100g });
  }
  if (totalCal <= 0) return [];
  const scale = targetCaloriesPerMeal / totalCal;
  return parts.map(({ foodId, quantityG }) => ({
    foodId,
    quantityG: Math.round(quantityG * scale),
  })).filter((i) => i.quantityG > 0);
}

/**
 * Generate meals for one day. Respects dislikedFoodIds.
 * When multiple valid templates exist, rotates by day so the same template is not repeated every day.
 * Deterministic: templates sorted by id; rotation index = (dayIndex + mealIndex) % numValidTemplates.
 */
export function generateMealsForDay(
  templates: MealTemplateRecord[],
  foods: FoodRecord[],
  dislikedFoodIds: string[],
  dailyCalorieTarget: number,
  mealsPerDay: number = 3,
  dayIndex: number = 0,
): GeneratedMeal[] {
  const foodMap = buildFoodMap(foods, dislikedFoodIds);
  const targetPerMeal = dailyCalorieTarget / mealsPerDay;
  const sortedTemplates = [...templates].sort((a, b) => a.id.localeCompare(b.id));
  const validTemplates: MealTemplateRecord[] = [];
  for (const template of sortedTemplates) {
    const items = scaleTemplateToCalories(template, foodMap, targetPerMeal);
    if (items.length > 0) validTemplates.push(template);
  }
  if (validTemplates.length === 0) return [];
  const result: GeneratedMeal[] = [];
  for (let mealIndex = 0; mealIndex < mealsPerDay; mealIndex++) {
    const template = validTemplates[(dayIndex + mealIndex) % validTemplates.length];
    const items = scaleTemplateToCalories(template, foodMap, targetPerMeal);
    if (items.length === 0) continue;
    result.push({
      mealIndex,
      name: template.name,
      templateId: template.id,
      items,
    });
  }
  return result;
}
