import { describe, it, expect } from 'vitest';
import { generateMealsForDay } from './meal-generation.js';

const foods = [
  {
    id: 'f1',
    name: 'Oats',
    caloriesPer100g: 389,
    proteinPer100g: 17,
    carbsPer100g: 66,
    fatPer100g: 7,
  },
  {
    id: 'f2',
    name: 'Banana',
    caloriesPer100g: 89,
    proteinPer100g: 1,
    carbsPer100g: 23,
    fatPer100g: 0,
  },
];

const templates = [
  { id: 't1', name: 'Breakfast', foods: [{ foodId: 'f1', quantityG: 80 }, { foodId: 'f2', quantityG: 100 }] },
  { id: 't2', name: 'Lunch', foods: [{ foodId: 'f1', quantityG: 50 }] },
];

describe('generateMealsForDay', () => {
  it('scales templates to target calories per meal', () => {
    const dailyCal = 2100;
    const meals = generateMealsForDay(templates, foods, [], dailyCal, 3);
    expect(meals.length).toBeGreaterThan(0);
    expect(meals.length).toBeLessThanOrEqual(3);
    const first = meals[0];
    expect(first.items.length).toBeGreaterThan(0);
    expect(first.name).toBe('Breakfast');
    expect(first.templateId).toBe('t1');
  });

  it('excludes templates that only reference disliked foods', () => {
    const meals = generateMealsForDay(templates, foods, ['f1', 'f2'], 2100, 3);
    expect(meals.length).toBe(0);
  });

  it('is deterministic (stable order)', () => {
    const a = generateMealsForDay(templates, foods, [], 2000, 3);
    const b = generateMealsForDay(templates, foods, [], 2000, 3);
    expect(a.length).toBe(b.length);
    expect(JSON.stringify(a)).toBe(JSON.stringify(b));
  });
});
