/**
 * Objetivos nutricionales diarios (ADR-0004): kcal y macros, sin comidas ni alimentos.
 * Mifflin-St Jeor × PAL ± ajuste por objetivo; proteína y grasa según PROGRAMACION.md §11;
 * hidratos = resto. Entrada inválida o incompleta ⇒ error tipado; nunca valores por defecto.
 */
import { engineV2 } from '@pipos/contracts';
import { ENGINE_VERSION, PROGRAMMING, type ProgrammingConfig } from '../config/programming.js';

type Input = engineV2.DailyTargetsInput;

const ACTIVITY_ES: Record<engineV2.ActivityLevel, string> = {
  sedentary_light: 'sedentaria o ligera',
  active: 'activa',
  vigorous: 'vigorosa',
};

/** REE de Mifflin-St Jeor (forma simplificada, PROGRAMACION.md §11.1). */
export function mifflinStJeor(
  input: Pick<Input, 'sex' | 'weightKg' | 'heightCm' | 'age'>,
  config: ProgrammingConfig = PROGRAMMING,
): number {
  const n = config.nutrition;
  const base = n.msjWeight.value * input.weightKg + n.msjHeight.value * input.heightCm + n.msjAge.value * input.age;
  return base + (input.sex === 'male' ? n.msjMale.value : n.msjFemale.value);
}

export function dailyTargets(input: unknown, config: ProgrammingConfig = PROGRAMMING): engineV2.DailyTargetsResult {
  const parsed = engineV2.DailyTargetsInputSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      error: {
        code: 'INVALID_INPUT',
        issues: parsed.error.issues.map((i) => ({ path: i.path.map(String).join('.'), message: i.message })),
      },
    };
  }
  const p = parsed.data;
  const n = config.nutrition;
  const warnings: { code: string; message: string }[] = [];
  const rationale: string[] = [];

  const ree = mifflinStJeor(p, config);
  const pal = n.pal[p.activityLevel].value;
  const tdee = ree * pal;
  rationale.push(
    `Gasto en reposo ${Math.round(ree)} kcal (Mifflin-St Jeor con ${p.weightKg} kg, ${p.heightCm} cm y ${p.age} años) × actividad ${ACTIVITY_ES[p.activityLevel]} (PAL ${pal}) = ${Math.round(tdee)} kcal de mantenimiento.`,
  );
  const [ageMin, ageMax] = n.studyAgeRange.value;
  if (p.age < ageMin || p.age > ageMax) {
    warnings.push({
      code: 'AGE_OUTSIDE_EQUATION_POPULATION',
      message: `La ecuación se validó en adultos de ${ageMin}-${ageMax} años; tómalo como estimación más gruesa.`,
    });
  }

  let kcal = tdee;
  if (p.goal === 'fat_loss') {
    const weeklyKg = (p.weightKg * n.lossRatePctPerWeek.value) / 100;
    const deficit = (weeklyKg * n.kcalPerKgTissue.value) / 7;
    kcal = tdee - deficit;
    rationale.push(
      `Para perder grasa a un ritmo del ${n.lossRatePctPerWeek.value} % del peso por semana (~${weeklyKg.toFixed(2)} kg) se restan ${Math.round(deficit)} kcal al día.`,
    );
  } else if (p.goal === 'muscle_gain') {
    const pct = p.level === 'advanced' ? n.surplusPctAdvanced.value : n.surplusPct.value;
    kcal = tdee * (1 + pct / 100);
    rationale.push(`Para ganar músculo se suma un superávit del ${pct} % sobre el mantenimiento.`);
  } else {
    rationale.push('Objetivo de mantenimiento: las kcal igualan el gasto estimado.');
  }

  if (n.kcalFloorIsRee.value && kcal < ree) {
    kcal = ree;
    warnings.push({
      code: 'KCAL_FLOOR_APPLIED',
      message: 'El objetivo bajaba de tu gasto en reposo; se fija en ese mínimo por seguridad.',
    });
  }
  kcal = Math.round(kcal);

  let proteinG: number;
  if (p.goal === 'fat_loss') {
    proteinG =
      p.leanMassKg !== undefined
        ? p.leanMassKg * n.proteinDeficitGPerKgLean.value
        : p.weightKg * n.proteinDeficitGPerKgBody.value;
    rationale.push(
      p.leanMassKg !== undefined
        ? `Proteína ${n.proteinDeficitGPerKgLean.value} g/kg de masa magra: en déficit ayuda a conservar músculo.`
        : `Proteína ${n.proteinDeficitGPerKgBody.value} g/kg de peso: en déficit ayuda a conservar músculo.`,
    );
  } else {
    proteinG = p.weightKg * n.proteinGPerKg.value;
    rationale.push(
      `Proteína ${n.proteinGPerKg.value} g/kg: el beneficio sobre la masa muscular se estabiliza alrededor de esa cifra.`,
    );
  }
  proteinG = Math.round(proteinG);

  let fatPct = n.fatPctDefault.value;
  const proteinKcal = proteinG * n.kcalPerGProtein.value;
  let fatG = Math.round((kcal * fatPct) / 100 / n.kcalPerGFat.value);
  let carbKcal = kcal - proteinKcal - fatG * n.kcalPerGFat.value;
  if (carbKcal < 0) {
    fatPct = n.fatPctMin.value;
    fatG = Math.round((kcal * fatPct) / 100 / n.kcalPerGFat.value);
    carbKcal = kcal - proteinKcal - fatG * n.kcalPerGFat.value;
  }
  if (carbKcal < 0) {
    carbKcal = 0;
    warnings.push({
      code: 'MACROS_EXCEED_KCAL',
      message: 'Proteína y grasa mínimas superan las kcal objetivo; los hidratos quedan en 0.',
    });
  }
  const carbsG = Math.round(carbKcal / n.kcalPerGCarb.value);
  rationale.push(`Grasa ${fatPct} % de la energía (rango recomendado 20-35 %); los hidratos cubren el resto.`);
  if (fatG / p.weightKg < n.fatGPerKgGuard.value) {
    warnings.push({
      code: 'FAT_BELOW_PRACTICE_GUARD',
      message: `La grasa queda por debajo de ${n.fatGPerKgGuard.value} g/kg (guía práctica sin evidencia firme).`,
    });
  }
  rationale.push('Son estimaciones poblacionales: recalibra con tu tendencia de peso cada 2-3 semanas.');

  return {
    ok: true,
    targets: {
      engineVersion: ENGINE_VERSION,
      kcal,
      proteinG,
      fatG,
      carbsG,
      reeKcal: Math.round(ree),
      tdeeKcal: Math.round(tdee),
      pal,
      adjustmentKcal: Math.round(kcal - tdee),
      warnings,
      rationale,
    },
  };
}
