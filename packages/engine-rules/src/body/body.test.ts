import fc from 'fast-check';
import { describe, expect, it } from 'vitest';
import { bmi, fmtPct, movingAverage, navyBodyFat, weightTrend } from './index.js';

const DAY = 86_400_000;
const day = (i: number) => new Date(Date.UTC(2026, 9, 1) + i * DAY).toISOString().slice(0, 10);

/** Pesos diarios con un ritmo semanal exacto en % del peso inicial. */
function series(days: number, startKg: number, pctPerWeek: number, every = 1) {
  const out = [];
  for (let i = 0; i < days; i += every) out.push({ date: day(i), weightKg: Math.round(startKg * (1 + (pctPerWeek / 100) * (i / 7)) * 100) / 100 });
  return out;
}

describe('weightTrend (§16.19)', () => {
  it('datos insuficientes: < 4 registros o < 14 días', () => {
    expect(weightTrend(series(10, 80, -0.7), 'fat_loss').status).toBe('insufficient_data');
    expect(weightTrend(series(28, 80, -0.7, 10), 'fat_loss').status).toBe('insufficient_data'); // 3 registros
    expect(weightTrend([], 'fat_loss')).toMatchObject({ status: 'insufficient_data', weeklyRatePct: null, spanDays: 0 });
  });

  it('pérdida de grasa: 0,7 %/sem en rango, 1,5 % demasiado rápido, 0,2 % demasiado lento', () => {
    const ok = weightTrend(series(28, 80, -0.7), 'fat_loss');
    expect(ok.status).toBe('on_track');
    expect(ok.weeklyRatePct).toBeCloseTo(-0.7, 1);
    expect(ok.target).toEqual({ direction: 'loss', minPct: 0.5, maxPct: 1 });
    expect(weightTrend(series(28, 80, -1.5), 'fat_loss').status).toBe('too_fast');
    expect(weightTrend(series(28, 80, -0.2), 'fat_loss').status).toBe('too_slow');
    expect(weightTrend(series(28, 80, 0.3), 'fat_loss').status).toBe('wrong_direction'); // sube en vez de bajar
  });

  it('dirección contraria al objetivo: wrong_direction con el texto correcto (no «subes más despacio»)', () => {
    const gainButLosing = weightTrend(series(28, 80, -0.5), 'hypertrophy');
    expect(gainButLosing.status).toBe('wrong_direction');
    const text = gainButLosing.rationale.join(' ');
    expect(text).toContain('Estás perdiendo peso (\u22120,5 %/semana) y tu objetivo es ganar entre 0,25 y 0,5 % por semana');
    expect(text).not.toMatch(/Subes/);
    const lossButGaining = weightTrend(series(28, 80, 0.3), 'fat_loss');
    expect(lossButGaining.rationale.join(' ')).toContain('Estás ganando peso (+0,3 %/semana) y tu objetivo es perder entre 0,5 y 1 % por semana');
  });

  it('los rangos del texto coinciden exactamente con el objetivo (hasta 2 decimales, coma decimal)', () => {
    const slow = weightTrend(series(28, 70, 0.15), 'hypertrophy');
    expect(slow.status).toBe('too_slow');
    expect(slow.target).toEqual({ direction: 'gain', minPct: 0.25, maxPct: 0.5 });
    expect(slow.rationale.join(' ')).toContain('0,25-0,5 %');
    expect(slow.rationale.join(' ')).not.toContain('0,3-0,5');
    const flat = weightTrend(series(28, 70, 0), 'hypertrophy');
    expect(flat.status).toBe('too_slow');
    expect(flat.rationale.join(' ')).toMatch(/prácticamente estable/);
    expect(fmtPct(0.25)).toBe('0,25');
    expect(fmtPct(0.5)).toBe('0,5');
    expect(fmtPct(1)).toBe('1');
    expect(fmtPct(-0.456)).toBe('\u22120,46');
  });

  it('hipertrofia: 0,25-0,5 %/sem de ganancia', () => {
    expect(weightTrend(series(21, 70, 0.35), 'hypertrophy').status).toBe('on_track');
    expect(weightTrend(series(21, 70, 1), 'hypertrophy').status).toBe('too_fast');
    expect(weightTrend(series(21, 70, 0.1), 'hypertrophy').status).toBe('too_slow');
    expect(weightTrend(series(21, 70, -0.3), 'hypertrophy').status).toBe('wrong_direction');
  });

  it('metas sin ritmo objetivo: no_target (no se inventa uno)', () => {
    const r = weightTrend(series(21, 70, -0.5), 'strength');
    expect(r).toMatchObject({ status: 'no_target', target: null });
    expect(r.weeklyRatePct).toBeCloseTo(-0.5, 1);
  });

  it('solo usa las últimas 4 semanas', () => {
    const old = series(60, 80, -2); // bajaba deprisa hace tiempo
    const recent = series(28, old[old.length - 1].weightKg, -0.7).map((e, i) => ({ ...e, date: day(60 + i) }));
    expect(weightTrend([...old, ...recent], 'fat_loss').status).toBe('on_track');
  });

  it('media móvil de 7 días (orden de entrada indiferente)', () => {
    const ma = movingAverage([{ date: day(2), weightKg: 82 }, { date: day(0), weightKg: 80 }, { date: day(9), weightKg: 90 }], 7);
    expect(ma).toEqual([
      { date: day(0), kg: 80 },
      { date: day(2), kg: 81 },
      { date: day(9), kg: 90 },
    ]);
  });

  it('propiedad: ritmo con el signo de la tendencia y estado coherente con el objetivo', () => {
    fc.assert(
      fc.property(fc.double({ min: -2, max: 2, noNaN: true }), fc.integer({ min: 50, max: 150 }), (pct, kg) => {
        const r = weightTrend(series(28, kg, pct), 'fat_loss');
        expect(r.weeklyRatePct).not.toBeNull();
        expect(Math.abs(r.weeklyRatePct! - pct)).toBeLessThan(0.1);
        if (-r.weeklyRatePct! > 1 + 1e-9) expect(r.status).toBe('too_fast');
        if (r.weeklyRatePct! > 0.05) expect(r.status).toBe('wrong_direction');
        else if (-r.weeklyRatePct! < 0.5 - 1e-9) expect(r.status).toBe('too_slow');
      }),
      { numRuns: 200, seed: 16019 },
    );
  });
});

describe('bmi (WHO 2000)', () => {
  it('ejemplo: 70 kg y 175 cm → 22,9, peso normal', () => {
    expect(bmi(70, 175)).toMatchObject({ status: 'ok', value: 22.9, category: 'normal', categoryEs: 'peso normal' });
  });
  it('cortes de la OMS en los límites', () => {
    const at = (v: number) => bmi(v, 100).category; // altura 1 m → IMC = kg
    expect(at(18.49)).toBe('underweight');
    expect(at(18.5)).toBe('normal');
    expect(at(24.99)).toBe('normal');
    expect(at(25)).toBe('pre_obese');
    expect(at(30)).toBe('obese_class_1');
    expect(at(35)).toBe('obese_class_2');
    expect(at(40)).toBe('obese_class_3');
  });
  it('menores de 18: valor sin categoría; entrada inválida', () => {
    expect(bmi(60, 170, 16)).toMatchObject({ status: 'ok', category: null });
    expect(bmi(0, 170).status).toBe('invalid_input');
    expect(bmi(70, Number.NaN).status).toBe('invalid_input');
  });
  it('siempre advierte de que no distingue músculo de grasa y de que no es un diagnóstico', () => {
    const c = bmi(90, 180).caveats.join(' ');
    expect(c).toMatch(/no distingue músculo de grasa/);
    expect(c).toMatch(/no un diagnóstico/);
  });
});

describe('navyBodyFat (Hodgdon y Beckett 1984)', () => {
  it('hombre 180 cm, cuello 38, abdomen 85 → ~16,1 %', () => {
    const r = navyBodyFat({ sex: 'male', heightCm: 180, neckCm: 38, waistCm: 85 });
    expect(r.status).toBe('ok');
    expect(r.percent).toBeCloseTo(16.1, 1);
  });

  it('coincide con la forma en pulgadas del Departamento de Defensa (hombres y mujeres)', () => {
    const inch = (cm: number) => cm / 2.54;
    fc.assert(
      fc.property(
        fc.integer({ min: 155, max: 195 }),
        fc.integer({ min: 30, max: 42 }),
        fc.integer({ min: 75, max: 105 }),
        fc.integer({ min: 85, max: 110 }),
        (h, neck, waist, hip) => {
          const m = navyBodyFat({ sex: 'male', heightCm: h, neckCm: neck, waistCm: waist });
          const dodMale = 86.01 * Math.log10(inch(waist) - inch(neck)) - 70.041 * Math.log10(inch(h)) + 36.76;
          if (m.status === 'ok') expect(Math.abs(m.percent! - dodMale)).toBeLessThan(1);
          const f = navyBodyFat({ sex: 'female', heightCm: h, neckCm: neck, waistCm: waist - 15, hipCm: hip });
          const dodFemale = 163.205 * Math.log10(inch(waist - 15) + inch(hip) - inch(neck)) - 97.684 * Math.log10(inch(h)) - 78.387;
          if (f.status === 'ok') expect(Math.abs(f.percent! - dodFemale)).toBeLessThan(1);
        },
      ),
      { numRuns: 200, seed: 1984 },
    );
  });

  it('mujer 165 cm, cuello 32, cintura 70, cadera 95 → ~24 %', () => {
    const r = navyBodyFat({ sex: 'female', heightCm: 165, neckCm: 32, waistCm: 70, hipCm: 95 });
    expect(r.status).toBe('ok');
    expect(r.percent!).toBeGreaterThan(22);
    expect(r.percent!).toBeLessThan(26);
    expect(r.caveats.join(' ')).toMatch(/estimación|Estimación/);
  });

  it('sexo distinto de hombre/mujer o desconocido → not_applicable', () => {
    expect(navyBodyFat({ sex: 'other', heightCm: 170, neckCm: 35, waistCm: 80 }).status).toBe('not_applicable');
    expect(navyBodyFat({ sex: null, heightCm: 170, neckCm: 35, waistCm: 80 }).status).toBe('not_applicable');
  });

  it('validación: faltan medidas, cintura ≤ cuello, mujer sin cadera', () => {
    expect(navyBodyFat({ sex: 'male', heightCm: null, neckCm: 38, waistCm: 85 }).status).toBe('invalid_input');
    const r = navyBodyFat({ sex: 'male', heightCm: 180, neckCm: 40, waistCm: 40 });
    expect(r).toMatchObject({ status: 'invalid_input', percent: null });
    expect(r.issues[0]).toMatch(/cintura debe ser mayor que el cuello/);
    expect(navyBodyFat({ sex: 'female', heightCm: 165, neckCm: 32, waistCm: 70 }).issues).toContain('Falta el perímetro de la cadera.');
  });
});
