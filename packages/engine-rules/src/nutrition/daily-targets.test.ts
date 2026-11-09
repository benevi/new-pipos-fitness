import fc from 'fast-check';
import { describe, expect, it } from 'vitest';
import { dailyTargets, mifflinStJeor } from './daily-targets.js';

const base = {
  sex: 'male' as const,
  age: 30,
  weightKg: 80,
  heightCm: 180,
  activityLevel: 'active' as const,
  goal: 'maintenance' as const,
  level: 'intermediate' as const,
};

function ok(input: unknown) {
  const r = dailyTargets(input);
  if (!r.ok) throw new Error(JSON.stringify(r.error));
  return r.targets;
}

describe('mifflinStJeor', () => {
  it('aplica la forma simplificada de 1990', () => {
    expect(mifflinStJeor(base)).toBe(10 * 80 + 6.25 * 180 - 5 * 30 + 5); // 1780
    expect(mifflinStJeor({ ...base, sex: 'female' })).toBe(10 * 80 + 6.25 * 180 - 5 * 30 - 161);
  });
});

describe('dailyTargets', () => {
  it('mantenimiento = REE × PAL, proteína 1,6 g/kg, grasa 25 %', () => {
    const t = ok(base);
    expect(t.reeKcal).toBe(1780);
    expect(t.pal).toBe(1.85);
    expect(t.kcal).toBe(Math.round(1780 * 1.85));
    expect(t.adjustmentKcal).toBe(0);
    expect(t.proteinG).toBe(128);
    expect(t.fatG).toBe(Math.round((t.kcal * 0.25) / 9));
    expect(t.engineVersion).toBe('2.0.0');
  });

  it('pérdida de grasa: déficit para 0,7 %/semana y proteína 2,2 g/kg', () => {
    const t = ok({ ...base, goal: 'fat_loss' });
    const deficit = (80 * 0.007 * 7700) / 7; // 616
    expect(t.kcal).toBe(Math.round(1780 * 1.85 - deficit));
    expect(t.proteinG).toBe(176);
    expect(t.rationale.join(' ')).toMatch(/0,7|0.7/);
  });

  it('pérdida de grasa con masa magra conocida usa 2,3 g/kg de masa magra', () => {
    expect(ok({ ...base, goal: 'fat_loss', leanMassKg: 65 }).proteinG).toBe(Math.round(65 * 2.3));
  });

  it('ganancia: +10 % (5 % en avanzados)', () => {
    const tdee = 1780 * 1.85;
    expect(ok({ ...base, goal: 'muscle_gain' }).kcal).toBe(Math.round(tdee * 1.1));
    expect(ok({ ...base, goal: 'muscle_gain', level: 'advanced' }).kcal).toBe(Math.round(tdee * 1.05));
  });

  it('nunca baja del gasto en reposo y lo avisa', () => {
    const t = ok({ ...base, weightKg: 200, heightCm: 150, activityLevel: 'sedentary_light', goal: 'fat_loss', age: 80 });
    expect(t.kcal).toBe(t.reeKcal);
    expect(t.warnings.map((w) => w.code)).toContain('KCAL_FLOOR_APPLIED');
  });

  it('avisa fuera de la población de la ecuación', () => {
    expect(ok({ ...base, age: 85 }).warnings.map((w) => w.code)).toContain('AGE_OUTSIDE_EQUATION_POPULATION');
  });

  it('avisa si la grasa queda bajo la guía práctica de 0,8 g/kg', () => {
    const t = ok({ ...base, weightKg: 120, heightCm: 160, age: 60, activityLevel: 'sedentary_light', sex: 'female' });
    expect(t.fatG / 120).toBeLessThan(0.8);
    expect(t.warnings.map((w) => w.code)).toContain('FAT_BELOW_PRACTICE_GUARD');
  });

  it('si proteína + grasa no caben, baja la grasa al 20 % y deja hidratos ≥ 0', () => {
    const t = ok({ ...base, weightKg: 200, heightCm: 100, age: 90, activityLevel: 'sedentary_light', goal: 'fat_loss', sex: 'female' });
    expect(t.carbsG).toBeGreaterThanOrEqual(0);
    expect(t.warnings.length).toBeGreaterThan(0);
  });

  it.each([
    ['sin sexo', { sex: undefined }],
    ['sexo other (la ecuación no lo define)', { sex: 'other' }],
    ['sin peso (nunca 70 kg por defecto)', { weightKg: undefined }],
    ['sin talla', { heightCm: undefined }],
    ['sin edad', { age: undefined }],
    ['menor de edad', { age: 16 }],
    ['sin actividad', { activityLevel: undefined }],
    ['peso fuera de rango', { weightKg: 10 }],
    ['objetivo desconocido', { goal: 'bulk' }],
    ['campo extra', { foods: [] }],
  ])('entrada inválida (%s) → error tipado, sin valores inventados', (_n, patch) => {
    const r = dailyTargets({ ...base, ...patch });
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.error.code).toBe('INVALID_INPUT');
      expect(r.error.issues.length).toBeGreaterThan(0);
    }
  });

  it('propiedad: las macros suman las kcal (±1 %) y kcal ≥ REE', () => {
    fc.assert(
      fc.property(
        fc.record({
          sex: fc.constantFrom('male', 'female'),
          age: fc.integer({ min: 18, max: 100 }),
          weightKg: fc.integer({ min: 40, max: 200 }),
          heightCm: fc.integer({ min: 140, max: 210 }),
          activityLevel: fc.constantFrom('sedentary_light', 'active', 'vigorous'),
          goal: fc.constantFrom('fat_loss', 'maintenance', 'muscle_gain'),
          level: fc.constantFrom('beginner', 'intermediate', 'advanced'),
        }),
        (input) => {
          const t = ok(input);
          expect(t.kcal).toBeGreaterThanOrEqual(t.reeKcal);
          const sum = t.proteinG * 4 + t.carbsG * 4 + t.fatG * 9;
          if (!t.warnings.some((w) => w.code === 'MACROS_EXCEED_KCAL')) {
            expect(Math.abs(sum - t.kcal) / t.kcal).toBeLessThan(0.01);
          }
          expect(t.fatG * 9).toBeGreaterThanOrEqual(t.kcal * 0.2 - 9);
        },
      ),
      { numRuns: 300 },
    );
  });
});
