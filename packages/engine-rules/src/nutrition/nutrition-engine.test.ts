import { describe, it, expect } from 'vitest';
import { getNutritionEngineVersion, generateNutritionPlan } from './nutrition-engine.js';
import { NutritionGoalType } from '@pipos/contracts';

describe('getNutritionEngineVersion', () => {
  it('returns version string', () => {
    expect(getNutritionEngineVersion()).toBe('0.0.1');
  });
});

describe('generateNutritionPlan', () => {
  const validInput = {
    user: { weightKg: 70, heightCm: 175, age: 30, sex: 'male' },
    goal: NutritionGoalType.MAINTAIN,
    catalog: {
      foods: [
        { id: 'f1', name: 'Oats', caloriesPer100g: 389, proteinPer100g: 17, carbsPer100g: 66, fatPer100g: 7 },
        { id: 'f2', name: 'Banana', caloriesPer100g: 89, proteinPer100g: 1, carbsPer100g: 23, fatPer100g: 0 },
      ],
      mealTemplates: [
        { id: 't1', name: 'Breakfast', foods: [{ foodId: 'f1', quantityG: 80 }, { foodId: 'f2', quantityG: 100 }] },
      ],
    },
  };

  it('returns 7 days with metadata', () => {
    const out = generateNutritionPlan(validInput);
    expect(out.metadata.engineVersion).toBe('0.0.1');
    expect(out.metadata.dailyCalorieTarget).toBeGreaterThan(0);
    expect(out.metadata.dailyMacroTarget.proteinG).toBeGreaterThan(0);
    expect(out.weekPlan.days.length).toBe(7);
  });

  it('invalid input returns empty days', () => {
    const out = generateNutritionPlan({});
    expect(out.weekPlan.days.length).toBe(0);
    expect(out.metadata.engineVersion).toBe('0.0.1');
  });

  it('respects goal for calorie target', () => {
    const maintain = generateNutritionPlan(validInput);
    const lose = generateNutritionPlan({ ...validInput, goal: NutritionGoalType.LOSE_FAT });
    const build = generateNutritionPlan({ ...validInput, goal: NutritionGoalType.BUILD_MUSCLE });
    expect(lose.metadata.dailyCalorieTarget).toBeLessThan(maintain.metadata.dailyCalorieTarget);
    expect(build.metadata.dailyCalorieTarget).toBeGreaterThan(maintain.metadata.dailyCalorieTarget);
  });
});
