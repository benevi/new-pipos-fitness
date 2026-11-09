import { z } from 'zod';
import { IsoDateSchema } from './history.js';

/**
 * Medidas corporales y estimaciones derivadas (idea 7, ADR-0013; PROGRAMACION.md §16.19).
 * Datos de salud (RGPD art. 9). Nada de esto es un diagnóstico.
 */

export const WeightEntrySchema = z.object({ date: IsoDateSchema, weightKg: z.number().min(25).max(400) }).strict();
export type WeightEntry = z.infer<typeof WeightEntrySchema>;

export const WEIGHT_TREND_STATUSES = ['on_track', 'too_fast', 'too_slow', 'no_target', 'insufficient_data'] as const;
export const WeightTrendStatusSchema = z.enum(WEIGHT_TREND_STATUSES);
export type WeightTrendStatus = z.infer<typeof WeightTrendStatusSchema>;

export const WeightTrendSchema = z
  .object({
    status: WeightTrendStatusSchema,
    /** Ritmo semanal en % del peso (negativo = bajando); null sin datos suficientes. */
    weeklyRatePct: z.number().nullable(),
    /** Ritmo objetivo según la meta (PROGRAMACION.md §11.5); null si la meta no fija ritmo. */
    target: z
      .object({ direction: z.enum(['loss', 'gain']), minPct: z.number(), maxPct: z.number() })
      .strict()
      .nullable(),
    /** Media móvil de 7 días en cada fecha con peso. */
    movingAverage: z.array(z.object({ date: IsoDateSchema, kg: z.number() }).strict()),
    /** Días entre el primer y el último registro de la ventana usada. */
    spanDays: z.number().int().min(0),
    rationale: z.array(z.string()),
  })
  .strict();
export type WeightTrend = z.infer<typeof WeightTrendSchema>;

/** Categorías de IMC para adultos de la OMS (WHO 2000, TRS 894). */
export const BMI_CATEGORIES = [
  'underweight',
  'normal',
  'pre_obese',
  'obese_class_1',
  'obese_class_2',
  'obese_class_3',
] as const;
export const BmiCategorySchema = z.enum(BMI_CATEGORIES);
export type BmiCategory = z.infer<typeof BmiCategorySchema>;

export const BmiResultSchema = z
  .object({
    status: z.enum(['ok', 'invalid_input']),
    value: z.number().nullable(),
    /** null si no es adulto (< 18 años) o si la entrada no es válida. */
    category: BmiCategorySchema.nullable(),
    categoryEs: z.string().nullable(),
    caveats: z.array(z.string()),
  })
  .strict();
export type BmiResult = z.infer<typeof BmiResultSchema>;

export const BodyFatResultSchema = z
  .object({
    status: z.enum(['ok', 'not_applicable', 'invalid_input']),
    /** % de grasa estimado (método de circunferencias de la Marina de EE. UU.); null si no aplica. */
    percent: z.number().nullable(),
    method: z.literal('navy_hodgdon_beckett_1984'),
    issues: z.array(z.string()),
    caveats: z.array(z.string()),
  })
  .strict();
export type BodyFatResult = z.infer<typeof BodyFatResultSchema>;
