import { z } from 'zod';
import { TrainingLevelSchema } from './enums.js';

/** Categorías PAL de FAO/WHO/UNU 2004 (PROGRAMACION.md §11.2). */
export const ACTIVITY_LEVELS = ['sedentary_light', 'active', 'vigorous'] as const;
export const ActivityLevelSchema = z.enum(ACTIVITY_LEVELS);
export type ActivityLevel = z.infer<typeof ActivityLevelSchema>;

export const NUTRITION_GOALS = ['fat_loss', 'maintenance', 'muscle_gain'] as const;
export const NutritionGoalSchema = z.enum(NUTRITION_GOALS);
export type NutritionGoal = z.infer<typeof NutritionGoalSchema>;

/**
 * Todos los campos son obligatorios salvo `leanMassKg`: nada se rellena por defecto.
 * Mifflin-St Jeor solo está definida para hombre/mujer; v1 excluye menores de edad.
 */
export const DailyTargetsInputSchema = z
  .object({
    sex: z.enum(['male', 'female']),
    age: z.number().int().min(18).max(100),
    weightKg: z.number().min(25).max(400),
    heightCm: z.number().min(100).max(250),
    activityLevel: ActivityLevelSchema,
    goal: NutritionGoalSchema,
    level: TrainingLevelSchema,
    leanMassKg: z.number().min(15).max(200).optional(),
  })
  .strict();
export type DailyTargetsInput = z.infer<typeof DailyTargetsInputSchema>;

export const NutritionWarningSchema = z.object({ code: z.string(), message: z.string() }).strict();

export const DailyTargetsSchema = z
  .object({
    engineVersion: z.string(),
    kcal: z.number().int().min(0),
    proteinG: z.number().int().min(0),
    fatG: z.number().int().min(0),
    carbsG: z.number().int().min(0),
    reeKcal: z.number().int().min(0),
    tdeeKcal: z.number().int().min(0),
    pal: z.number(),
    adjustmentKcal: z.number().int(),
    warnings: z.array(NutritionWarningSchema),
    rationale: z.array(z.string()),
  })
  .strict();
export type DailyTargets = z.infer<typeof DailyTargetsSchema>;

export type DailyTargetsResult =
  | { ok: true; targets: DailyTargets }
  | { ok: false; error: { code: 'INVALID_INPUT'; issues: { path: string; message: string }[] } };
