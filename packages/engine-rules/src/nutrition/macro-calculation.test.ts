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
    expect(out!.proteinG).toBe(140);
    expect(out!.fatG).toBe(56);
    const proteinCal = 140 * 4;
    const fatCal = 56 * 9;
    const remainingCal = 2000 - proteinCal - fatCal;
    expect(out!.carbsG).toBe(Math.round(remainingCal / 4));
  });
});
