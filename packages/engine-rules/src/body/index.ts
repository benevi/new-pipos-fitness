/**
 * Medidas corporales (PROGRAMACION.md §16.19; idea 7, ADR-0013). Funciones puras.
 *
 * - `weightTrend`: media móvil de 7 días y ritmo semanal en % del peso frente al objetivo de §11.5.
 * - `bmi`: IMC con las categorías de adultos de la OMS (WHO 2000). No distingue músculo de grasa.
 * - `navyBodyFat`: % de grasa ESTIMADO por circunferencias (Hodgdon y Beckett 1984).
 *
 * Nada de esto es un diagnóstico: los textos lo dicen y remiten a un profesional.
 */
import type { engineV2 } from '@pipos/contracts';
import { PROGRAMMING, type ProgrammingConfig } from '../config/programming.js';

const DAY = 86_400_000;

function toMs(date: string): number {
  return Date.UTC(+date.slice(0, 4), +date.slice(5, 7) - 1, +date.slice(8, 10));
}

const round = (n: number, d: number) => Math.round(n * 10 ** d) / 10 ** d;

/** Número con hasta 2 decimales y coma decimal, sin ceros finales (0,25 · 0,5 · 1). */
export function fmtPct(n: number): string {
  const r = round(Math.abs(n), 2);
  const s = String(r).replace('.', ',');
  return n < 0 && r !== 0 ? `\u2212${s}` : s;
}

/** Ritmo con signo explícito: «+0,3» / «−0,5» / «0». */
const signedPct = (n: number) => (round(n, 2) > 0 ? `+${fmtPct(n)}` : fmtPct(n));

/** Por debajo de este ritmo (en valor absoluto, %/sem) el peso se considera estable. */
const STABLE_PCT = 0.05;

export const NOT_A_DIAGNOSIS =
  'Es una estimación orientativa, no un diagnóstico. Para valorar tu salud, consulta a un profesional sanitario.';

// ─────────────────────────────────────────────────────────────
// Tendencia de peso
// ─────────────────────────────────────────────────────────────

/** Media de los pesos de los `days` días que terminan en cada fecha (ambos incluidos). */
export function movingAverage(entries: readonly engineV2.WeightEntry[], days: number): { date: string; kg: number }[] {
  const sorted = [...entries].sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : 0));
  return sorted.map((e) => {
    const from = toMs(e.date) - (days - 1) * DAY;
    const win = sorted.filter((x) => toMs(x.date) >= from && toMs(x.date) <= toMs(e.date));
    return { date: e.date, kg: round(win.reduce((s, x) => s + x.weightKg, 0) / win.length, 2) };
  });
}

/** Pendiente por mínimos cuadrados (kg/día) de pesos frente a fecha. */
function slopeKgPerDay(entries: readonly engineV2.WeightEntry[]): number {
  const xs = entries.map((e) => toMs(e.date) / DAY);
  const ys = entries.map((e) => e.weightKg);
  const mx = xs.reduce((s, x) => s + x, 0) / xs.length;
  const my = ys.reduce((s, y) => s + y, 0) / ys.length;
  let num = 0;
  let den = 0;
  for (let i = 0; i < xs.length; i++) {
    num += (xs[i] - mx) * (ys[i] - my);
    den += (xs[i] - mx) ** 2;
  }
  return den === 0 ? 0 : num / den;
}

/**
 * Ritmo de cambio del peso (PROGRAMACION.md §16.19). Usa los registros de las últimas
 * `trendWindowDays` (28) hasta el último registro; necesita ≥ 14 días entre el primero y el
 * último de esa ventana y ≥ 4 registros. Ritmo = pendiente de mínimos cuadrados × 7 / peso medio.
 * Objetivo: pérdida de grasa 0,5-1 %/sem (§11.5, Helms 2014); hipertrofia 0,25-0,5 %/sem
 * (§11.5, no verificado textualmente). El resto de metas no fija un ritmo (`no_target`).
 */
export function weightTrend(
  entries: readonly engineV2.WeightEntry[],
  goal: engineV2.TrainingGoal,
  config: ProgrammingConfig = PROGRAMMING,
): engineV2.WeightTrend {
  const b = config.body;
  const sorted = [...entries].sort((a, c) => (a.date < c.date ? -1 : a.date > c.date ? 1 : 0));
  const movingAvg = movingAverage(sorted, b.movingAverageDays.value);
  const loss = config.nutrition.lossRatePctPerWeek.range ?? [0.5, 1];
  const gain = b.gainRatePctPerWeek.range ?? [0.25, 0.5];
  const target =
    goal === 'fat_loss'
      ? { direction: 'loss' as const, minPct: loss[0], maxPct: loss[1] }
      : goal === 'hypertrophy'
        ? { direction: 'gain' as const, minPct: gain[0], maxPct: gain[1] }
        : null;

  const last = sorted.at(-1);
  const window = last ? sorted.filter((e) => toMs(e.date) > toMs(last.date) - b.trendWindowDays.value * DAY) : [];
  const spanDays = window.length > 0 ? Math.round((toMs(window[window.length - 1].date) - toMs(window[0].date)) / DAY) : 0;
  if (window.length < b.minEntries.value || spanDays < b.minSpanDays.value) {
    return {
      status: 'insufficient_data',
      weeklyRatePct: null,
      target,
      movingAverage: movingAvg,
      spanDays,
      rationale: [
        `Hacen falta al menos ${b.minEntries.value} pesos en ${b.minSpanDays.value} días o más para calcular un ritmo fiable (tienes ${window.length} en ${spanDays} días). Pésate en condiciones parecidas (p. ej. por la mañana).`,
      ],
    };
  }
  const meanKg = window.reduce((s, e) => s + e.weightKg, 0) / window.length;
  const rate = round(((slopeKgPerDay(window) * 7) / meanKg) * 100, 2);
  const rateText = `${signedPct(rate)} % por semana`;
  const rationale = [`En los últimos ${spanDays} días tu peso cambia a un ritmo de ${rateText} (tendencia de ${window.length} registros).`];
  if (!target) {
    rationale.push('Tu objetivo no fija un ritmo de cambio de peso: la tendencia es solo informativa.');
    return { status: 'no_target', weeklyRatePct: rate, target, movingAverage: movingAvg, spanDays, rationale };
  }
  const signed = target.direction === 'loss' ? -rate : rate; // ritmo en la dirección buscada
  const range = `${fmtPct(target.minPct)}-${fmtPct(target.maxPct)} %`;
  const between = `entre ${fmtPct(target.minPct)} y ${fmtPct(target.maxPct)} %`;
  const review = 'Si se mantiene 2-3 semanas, revisa tus objetivos diarios.';
  let status: engineV2.WeightTrendStatus;
  if (signed > target.maxPct + 1e-9) {
    status = 'too_fast';
    rationale.push(
      target.direction === 'loss'
        ? `Bajas más rápido que el ${range} semanal recomendado: a ese ritmo es más fácil perder masa muscular y rendimiento (§11.5).`
        : `Subes más rápido que el ${range} semanal orientativo: probablemente estás ganando más grasa de la necesaria (§11.5).`,
    );
  } else if (signed < -STABLE_PCT) {
    // Se mueve en sentido contrario al objetivo: no es «ir lento», es ir al revés.
    status = 'wrong_direction';
    rationale.push(
      target.direction === 'loss'
        ? `Estás ganando peso (${signedPct(rate)} %/semana) y tu objetivo es perder ${between} por semana. ${review}`
        : `Estás perdiendo peso (${signedPct(rate)} %/semana) y tu objetivo es ganar ${between} por semana. ${review}`,
    );
  } else if (signed < target.minPct - 1e-9) {
    status = 'too_slow';
    const verb = target.direction === 'loss' ? 'perder' : 'ganar';
    rationale.push(
      Math.abs(rate) <= STABLE_PCT
        ? `Tu peso se mantiene prácticamente estable y tu objetivo es ${verb} ${between} por semana. ${review}`
        : target.direction === 'loss'
          ? `Bajas más despacio que el ${range} semanal recomendado. ${review}`
          : `Subes más despacio que el ${range} semanal orientativo. ${review}`,
    );
  } else {
    status = 'on_track';
    rationale.push(`Dentro del ${range} semanal ${target.direction === 'loss' ? 'de pérdida' : 'de ganancia'} para tu objetivo.`);
  }
  return { status, weeklyRatePct: rate, target, movingAverage: movingAvg, spanDays, rationale };
}

// ─────────────────────────────────────────────────────────────
// IMC (OMS)
// ─────────────────────────────────────────────────────────────

export const BMI_CATEGORY_ES: Record<engineV2.BmiCategory, string> = {
  underweight: 'bajo peso',
  normal: 'peso normal',
  pre_obese: 'sobrepeso (preobesidad)',
  obese_class_1: 'obesidad de clase I',
  obese_class_2: 'obesidad de clase II',
  obese_class_3: 'obesidad de clase III',
};

export const BMI_CAVEATS = [
  'El IMC no distingue músculo de grasa: en personas que entrenan fuerza puede sobrestimar la grasa.',
  'Los puntos de corte son los de la OMS para adultos; en algunas poblaciones (p. ej. asiáticas) se usan cortes más bajos.',
  NOT_A_DIAGNOSIS,
];

/** IMC = kg / m² y categoría de adultos de la OMS (WHO 2000). Sin categoría si la edad es < 18. */
export function bmi(
  weightKg: number,
  heightCm: number,
  age: number | null = null,
  config: ProgrammingConfig = PROGRAMMING,
): engineV2.BmiResult {
  if (!(weightKg > 0) || !(heightCm > 0) || !Number.isFinite(weightKg) || !Number.isFinite(heightCm)) {
    return { status: 'invalid_input', value: null, category: null, categoryEs: null, caveats: [NOT_A_DIAGNOSIS] };
  }
  const m = heightCm / 100;
  const value = round(weightKg / (m * m), 1);
  const raw = weightKg / (m * m);
  if (age !== null && age < config.body.bmiAdultAge.value) {
    return {
      status: 'ok',
      value,
      category: null,
      categoryEs: null,
      caveats: ['Las categorías de la OMS son para adultos; antes de los 18 años se usan percentiles por edad y sexo.', ...BMI_CAVEATS],
    };
  }
  const [under, over, ob1, ob2, ob3] = config.body.bmiCutoffs.value;
  const category: engineV2.BmiCategory =
    raw < under ? 'underweight' : raw < over ? 'normal' : raw < ob1 ? 'pre_obese' : raw < ob2 ? 'obese_class_1' : raw < ob3 ? 'obese_class_2' : 'obese_class_3';
  return { status: 'ok', value, category, categoryEs: BMI_CATEGORY_ES[category], caveats: [...BMI_CAVEATS] };
}

// ─────────────────────────────────────────────────────────────
// % de grasa: método de circunferencias de la Marina (Hodgdon y Beckett 1984)
// ─────────────────────────────────────────────────────────────

export interface NavyInput {
  sex: engineV2.Sex | null;
  heightCm: number | null;
  neckCm: number | null;
  /** Hombres: abdomen a la altura del ombligo. Mujeres: cintura en su parte más estrecha. */
  waistCm: number | null;
  /** Solo mujeres: cadera en su parte más ancha. */
  hipCm?: number | null;
}

export const BODY_FAT_CAVEATS = [
  'Estimación por circunferencias (método de la Marina de EE. UU., Hodgdon y Beckett 1984), no una medición: el error típico es de varios puntos porcentuales y crece en personas muy musculadas o con mucha grasa abdominal.',
  'Sirve para ver tu evolución midiendo siempre igual, no como valor exacto.',
  NOT_A_DIAGNOSIS,
];

/**
 * % de grasa = 495 / D − 450 (Siri 1961), con la densidad D de Hodgdon y Beckett (1984), en cm:
 * - hombres: D = 1,0324 − 0,19077·log10(abdomen − cuello) + 0,15456·log10(altura)
 * - mujeres: D = 1,29579 − 0,35004·log10(cintura + cadera − cuello) + 0,22100·log10(altura)
 * Solo para sexo `male`/`female` (con otro valor o sin dato: `not_applicable`).
 */
export function navyBodyFat(input: NavyInput, config: ProgrammingConfig = PROGRAMMING): engineV2.BodyFatResult {
  const base = { method: 'navy_hodgdon_beckett_1984' as const };
  if (input.sex !== 'male' && input.sex !== 'female') {
    return {
      ...base,
      status: 'not_applicable',
      percent: null,
      issues: ['La fórmula solo está validada para hombres y para mujeres por separado.'],
      caveats: [NOT_A_DIAGNOSIS],
    };
  }
  const issues: string[] = [];
  const { heightCm, neckCm, waistCm } = input;
  const hipCm = input.hipCm ?? null;
  if (heightCm === null || !(heightCm > 0)) issues.push('Falta la altura.');
  if (neckCm === null || !(neckCm > 0)) issues.push('Falta el perímetro del cuello.');
  if (waistCm === null || !(waistCm > 0)) issues.push('Falta el perímetro de la cintura.');
  if (input.sex === 'female' && (hipCm === null || !(hipCm > 0))) issues.push('Falta el perímetro de la cadera.');
  if (issues.length === 0) {
    if (input.sex === 'male' && waistCm! <= neckCm!) issues.push('La cintura debe ser mayor que el cuello.');
    if (input.sex === 'female' && waistCm! + hipCm! <= neckCm!) issues.push('Cintura + cadera debe ser mayor que el cuello.');
  }
  if (issues.length > 0) return { ...base, status: 'invalid_input', percent: null, issues, caveats: [NOT_A_DIAGNOSIS] };

  const d =
    input.sex === 'male'
      ? config.body.navyMale.value.c -
        config.body.navyMale.value.abdomenNeck * Math.log10(waistCm! - neckCm!) +
        config.body.navyMale.value.height * Math.log10(heightCm!)
      : config.body.navyFemale.value.c -
        config.body.navyFemale.value.waistHipNeck * Math.log10(waistCm! + hipCm! - neckCm!) +
        config.body.navyFemale.value.height * Math.log10(heightCm!);
  const percent = 495 / d - 450;
  if (!Number.isFinite(percent) || percent < 2 || percent > 60) {
    return {
      ...base,
      status: 'invalid_input',
      percent: null,
      issues: ['Las medidas dan un valor fuera del rango de la fórmula: revisa cómo se han tomado.'],
      caveats: [NOT_A_DIAGNOSIS],
    };
  }
  return { ...base, status: 'ok', percent: round(percent, 1), issues: [], caveats: [...BODY_FAT_CAVEATS] };
}
