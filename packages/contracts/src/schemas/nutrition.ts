import { z } from 'zod';
import { DailyTargetsSchema, NutritionGoalSchema } from '../engine-v2/nutrition.js';

/**
 * GET /me/nutrition-targets (ADR-0004): objetivos diarios calculados por el motor a partir
 * del perfil; no se guardan (minimización, ADR-0011). Si faltan datos → 422
 * NUTRITION_INPUT_INCOMPLETE con `issues` por campo.
 *
 * Objetivo nutricional derivado del objetivo de entrenamiento: fat_loss → fat_loss,
 * hypertrophy → muscle_gain, resto → maintenance.
 */
export const NutritionTargetsResponseSchema = DailyTargetsSchema.extend({
  nutritionGoal: NutritionGoalSchema,
}).strict();
export type NutritionTargetsResponse = z.infer<typeof NutritionTargetsResponseSchema>;
