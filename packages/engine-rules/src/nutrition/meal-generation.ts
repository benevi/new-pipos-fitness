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
 * Generate meals for one day: use meal templates in order, scale each to target calories per meal.
 * dailyCalorieTarget and macroTarget are for the whole day; we only use calorie split per meal here.
 * Respects dislikedFoodIds (templates using only disliked foods are skipped).
 * Deterministic: templates sorted by id.
 */
export function generateMealsForDay(
  templates: MealTemplateRecord[],
  foods: FoodRecord[],
  dislikedFoodIds: string[],
  dailyCalorieTarget: number,
  mealsPerDay: number = 3,
): GeneratedMeal[] {
  const foodMap = buildFoodMap(foods, dislikedFoodIds);
  const targetPerMeal = dailyCalorieTarget / mealsPerDay;
  const sortedTemplates = [...templates].sort((a, b) => a.id.localeCompare(b.id));
  const result: GeneratedMeal[] = [];
  let used = 0;
  for (const template of sortedTemplates) {
    if (used >= mealsPerDay) break;
    const items = scaleTemplateToCalories(template, foodMap, targetPerMeal);
    if (items.length === 0) continue;
    result.push({
      mealIndex: used,
      name: template.name,
      templateId: template.id,
      items,
    });
    used += 1;
  }
  return result;
}
