/**
 * @deprecated Capa de compatibilidad TEMPORAL para `apps/api` (nutrition-plans) hasta la Fase 3.
 *
 * Mantiene la firma antigua `generateNutritionPlan(NutritionEngineInput)` pero:
 * - calcula los objetivos con el nuevo `dailyTargets` (sin 70 kg ni 2000 kcal por defecto);
 * - ya NO genera comidas (ADR-0004): `weekPlan.days` siempre está vacío;
 * - con datos incompletos o inválidos LANZA `NutritionInputError` en vez de inventar valores.
 * Mapeo provisional días de entrenamiento → PAL (solo aquí): 0-2 sedentaria/ligera, 3-5 activa,
 * 6-7 vigorosa. Se elimina en la Fase 3, cuando la API llame a `dailyTargets` directamente.
 */
import { NutritionEngineInputSchema, type NutritionEngineOutput } from '@pipos/contracts';
import { ENGINE_VERSION } from '../config/programming.js';
import { dailyTargets } from '../nutrition/daily-targets.js';

export const NUTRITION_ENGINE_VERSION = ENGINE_VERSION;

export function getNutritionEngineVersion(): string {
  return NUTRITION_ENGINE_VERSION;
}

export class NutritionInputError extends Error {
  constructor(public readonly issues: { path: string; message: string }[]) {
    super(`Datos nutricionales incompletos o inválidos: ${issues.map((i) => i.path || i.message).join(', ')}`);
    this.name = 'NutritionInputError';
  }
}

export function generateNutritionPlan(input: unknown): NutritionEngineOutput {
  const parsed = NutritionEngineInputSchema.safeParse(input);
  if (!parsed.success) {
    throw new NutritionInputError(parsed.error.issues.map((i) => ({ path: i.path.join('.'), message: i.message })));
  }
  const { user, goal } = parsed.data;
  const days = user.preferredTrainingDays;
  const activityLevel =
    days === undefined ? undefined : days <= 2 ? 'sedentary_light' : days <= 5 ? 'active' : 'vigorous';
  const result = dailyTargets({
    sex: user.sex,
    age: user.age ?? undefined,
    weightKg: user.weightKg ?? undefined,
    heightCm: user.heightCm ?? undefined,
    activityLevel,
    goal: goal === 'lose_fat' ? 'fat_loss' : goal === 'build_muscle' ? 'muscle_gain' : 'maintenance',
    // El esquema antiguo no tiene nivel; solo afecta al superávit de avanzados.
    level: 'intermediate',
  });
  if (!result.ok) throw new NutritionInputError(result.error.issues);
  const t = result.targets;
  return {
    metadata: {
      engineVersion: NUTRITION_ENGINE_VERSION,
      dailyCalorieTarget: t.kcal,
      dailyMacroTarget: { proteinG: t.proteinG, carbsG: t.carbsG, fatG: t.fatG },
      macrosClamped: t.warnings.some((w) => w.code === 'MACROS_EXCEED_KCAL') || undefined,
    },
    weekPlan: { days: [] },
  };
}
