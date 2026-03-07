export { getNutritionEngineVersion, generateNutritionPlan, NUTRITION_ENGINE_VERSION } from './nutrition-engine.js';
export { calculateBMR, calculateTDEE, calculateDailyCalorieTarget } from './calorie-calculation.js';
export type { NutritionGoal } from './calorie-calculation.js';
export { calculateMacroTargets } from './macro-calculation.js';
export { generateMealsForDay } from './meal-generation.js';
export type { MealItem, GeneratedMeal } from './meal-generation.js';
export type { NutritionUser, FoodRecord, MealTemplateRecord, MacroTarget } from './nutrition-types.js';
