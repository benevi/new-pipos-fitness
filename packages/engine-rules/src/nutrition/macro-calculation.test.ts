import { describe, it, expect } from 'vitest';
import { calculateMacroTargets } from './macro-calculation.js';

describe('calculateMacroTargets', () => {
  it('returns null when weight missing or dailyCalories invalid', () => {
    expect(calculateMacroTargets(null, 2000)).toBeNull();
    expect(calculateMacroTargets(undefined, 2000)).toBeNull();
    expect(calculateMacroTargets(70, 0)).toBeNull();
    expect(calculateMacroTargets(0, 2000)).toBeNull();
  });

  it('protein 2g/kg, fat 0.8g/kg, carbs from remainder', () => {
    const weightKg = 70;
    const dailyCalories = 2000;
    const out = calculateMacroTargets(weightKg, dailyCalories);
    expect(out).not.toBeNull();
    expect(out!.macroTarget.proteinG).toBe(140);
    expect(out!.macroTarget.fatG).toBe(56);
    const proteinCal = 140 * 4;
    const fatCal = 56 * 9;
    const remainingCal = 2000 - proteinCal - fatCal;
    expect(out!.macroTarget.carbsG).toBe(Math.round(remainingCal / 4));
    expect(out!.clamped).toBe(false);
  });

  it('very low calorie target: carbs clamped to 0, clamped true', () => {
    const out = calculateMacroTargets(70, 400);
    expect(out).not.toBeNull();
    expect(out!.macroTarget.proteinG).toBe(140);
    expect(out!.macroTarget.fatG).toBe(56);
    expect(out!.macroTarget.carbsG).toBe(0);
    expect(out!.clamped).toBe(true);
  });

  it('low bodyweight edge case: carbs non-negative', () => {
    const out = calculateMacroTargets(40, 1200);
    expect(out).not.toBeNull();
    expect(out!.macroTarget.carbsG).toBeGreaterThanOrEqual(0);
    expect(out!.macroTarget.proteinG).toBe(80);
    expect(out!.macroTarget.fatG).toBe(32);
  });
});
