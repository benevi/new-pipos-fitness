import { describe, it, expect } from 'vitest';
import { calculateBMR, calculateTDEE, calculateDailyCalorieTarget } from './calorie-calculation.js';

describe('calculateBMR', () => {
  it('returns null when weight or height or age missing', () => {
    expect(calculateBMR({})).toBeNull();
    expect(calculateBMR({ weightKg: 70 })).toBeNull();
    expect(calculateBMR({ weightKg: 70, heightCm: 175 })).toBeNull();
    expect(calculateBMR({ weightKg: 70, heightCm: 175, age: 30 })).toBeNull();
  });

  it('computes BMR for male', () => {
    const bmr = calculateBMR({ weightKg: 70, heightCm: 175, age: 30, sex: 'male' });
    expect(bmr).not.toBeNull();
    expect(bmr).toBe(10 * 70 + 6.25 * 175 - 5 * 30 + 5);
  });

  it('computes BMR for female', () => {
    const bmr = calculateBMR({ weightKg: 60, heightCm: 165, age: 25, sex: 'female' });
    expect(bmr).not.toBeNull();
    expect(bmr).toBe(10 * 60 + 6.25 * 165 - 5 * 25 - 161);
  });
});

describe('calculateTDEE', () => {
  it('returns null when BMR cannot be computed', () => {
    expect(calculateTDEE({})).toBeNull();
  });

  it('returns BMR * activity factor', () => {
    const tdee = calculateTDEE(
      { weightKg: 70, heightCm: 175, age: 30, sex: 'male' },
      1.2,
    );
    expect(tdee).not.toBeNull();
    const bmr = 10 * 70 + 6.25 * 175 - 5 * 30 + 5;
    expect(tdee).toBe(Math.round(bmr * 1.2));
  });
});

describe('calculateDailyCalorieTarget', () => {
  const user = { weightKg: 70, heightCm: 175, age: 30, sex: 'male' as const };

  it('returns null when TDEE cannot be computed', () => {
    expect(calculateDailyCalorieTarget({}, 'maintain')).toBeNull();
  });

  it('maintain: baseline', () => {
    const tdee = calculateTDEE(user)!;
    const target = calculateDailyCalorieTarget(user, 'maintain');
    expect(target).toBe(Math.round(tdee));
  });

  it('lose_fat: -15%', () => {
    const tdee = calculateTDEE(user)!;
    const target = calculateDailyCalorieTarget(user, 'lose_fat');
    expect(target).toBe(Math.round(tdee * 0.85));
  });

  it('build_muscle: +10%', () => {
    const tdee = calculateTDEE(user)!;
    const target = calculateDailyCalorieTarget(user, 'build_muscle');
    expect(target).toBe(Math.round(tdee * 1.1));
  });
});
