import { describe, it, expect } from 'vitest';
import { getNutritionEngineVersion, calculateBMR, calculateMacroTargets, generateMealsForDay } from './index.js';

describe('nutrition engine', () => {
  it('returns version string', () => {
    expect(getNutritionEngineVersion()).toBe('0.0.1');
  });

  it('exports calorie and macro helpers', () => {
    expect(calculateBMR({ weightKg: 70, heightCm: 175, age: 30, sex: 'male' })).not.toBeNull();
    expect(calculateMacroTargets(70, 2000)).not.toBeNull();
  });

  it('generateMealsForDay returns array', () => {
    const foods = [{ id: 'f1', name: 'Oats', caloriesPer100g: 389, proteinPer100g: 17, carbsPer100g: 66, fatPer100g: 7 }];
    const templates = [{ id: 't1', name: 'B', foods: [{ foodId: 'f1', quantityG: 100 }] }];
    const meals = generateMealsForDay(templates, foods, [], 2000, 3);
    expect(Array.isArray(meals)).toBe(true);
  });
});
