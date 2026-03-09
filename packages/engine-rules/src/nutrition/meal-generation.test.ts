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
    const meals = generateMealsForDay(templates, foods, [], dailyCal, 3, 0);
    expect(meals.length).toBeGreaterThan(0);
    expect(meals.length).toBeLessThanOrEqual(3);
    const first = meals[0];
    expect(first.items.length).toBeGreaterThan(0);
    expect(first.name).toBe('Breakfast');
    expect(first.templateId).toBe('t1');
  });

  it('excludes templates that only reference disliked foods', () => {
    const meals = generateMealsForDay(templates, foods, ['f1', 'f2'], 2100, 3, 0);
    expect(meals.length).toBe(0);
  });

  it('is deterministic (stable order)', () => {
    const a = generateMealsForDay(templates, foods, [], 2000, 3, 0);
    const b = generateMealsForDay(templates, foods, [], 2000, 3, 0);
    expect(a.length).toBe(b.length);
    expect(JSON.stringify(a)).toBe(JSON.stringify(b));
  });

  it('multiple templates: rotation by day reduces same-template repetition', () => {
    const threeTemplates = [
      { id: 't1', name: 'B1', foods: [{ foodId: 'f1', quantityG: 80 }] },
      { id: 't2', name: 'B2', foods: [{ foodId: 'f1', quantityG: 80 }] },
      { id: 't3', name: 'B3', foods: [{ foodId: 'f1', quantityG: 80 }] },
    ];
    const day0 = generateMealsForDay(threeTemplates, foods, [], 2100, 3, 0);
    const day1 = generateMealsForDay(threeTemplates, foods, [], 2100, 3, 1);
    expect(day0.length).toBe(3);
    expect(day1.length).toBe(3);
    const ids0 = day0.map((m) => m.templateId);
    const ids1 = day1.map((m) => m.templateId);
    expect(ids0[0]).not.toBe(ids1[0]);
    expect(ids0).toEqual([day0[0].templateId, day0[1].templateId, day0[2].templateId]);
  });

  it('only one valid template: repetition allowed', () => {
    const oneTemplate = [{ id: 't1', name: 'B', foods: [{ foodId: 'f1', quantityG: 80 }] }];
    const day0 = generateMealsForDay(oneTemplate, foods, [], 2100, 3, 0);
    const day1 = generateMealsForDay(oneTemplate, foods, [], 2100, 3, 1);
    expect(day0.every((m) => m.templateId === 't1')).toBe(true);
    expect(day1.every((m) => m.templateId === 't1')).toBe(true);
  });

  it('deterministic: same inputs same output', () => {
    const threeTemplates = [
      { id: 't1', name: 'B1', foods: [{ foodId: 'f1', quantityG: 80 }] },
      { id: 't2', name: 'B2', foods: [{ foodId: 'f1', quantityG: 80 }] },
    ];
    const a = generateMealsForDay(threeTemplates, foods, [], 2000, 3, 2);
    const b = generateMealsForDay(threeTemplates, foods, [], 2000, 3, 2);
    expect(JSON.stringify(a)).toBe(JSON.stringify(b));
  });
});
