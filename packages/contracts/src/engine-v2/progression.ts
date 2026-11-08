import { z } from 'zod';
import { MovementPatternSchema } from './enums.js';
import { ExerciseSessionLogSchema, IsoDateSchema } from './history.js';

export const CurrentPrescriptionSchema = z
  .object({
    exerciseId: z.string().min(1),
    movementPattern: MovementPatternSchema,
    loadType: z.enum(['external', 'bodyweight']),
    sets: z.number().int().min(1).max(10),
    repMin: z.number().int().min(1).max(50),
    repMax: z.number().int().min(1).max(50),
    targetRir: z.number().int().min(0).max(5),
    loadKg: z.number().min(0).nullable(),
  })
  .strict()
  .refine((p) => p.repMin <= p.repMax, { message: 'repMin > repMax', path: ['repMin'] });
export type CurrentPrescription = z.infer<typeof CurrentPrescriptionSchema>;

export const NextPrescriptionInputSchema = z
  .object({
    prescription: CurrentPrescriptionSchema,
    /** Sesiones de ESTE ejercicio, en cualquier orden; el motor las ordena por fecha. */
    history: z.array(ExerciseSessionLogSchema),
    today: IsoDateSchema,
    /** Semanas completas desde la última descarga (o desde el inicio del plan). */
    weeksSinceDeload: z.number().int().min(0).max(52),
  })
  .strict();
export type NextPrescriptionInput = z.infer<typeof NextPrescriptionInputSchema>;

export const PROGRESSION_ACTIONS = [
  'start',
  'increase_load',
  'increase_reps',
  'hold',
  'decrease_load',
  'deload',
  'return_after_break',
  'progress_variant',
] as const;
export const ProgressionActionSchema = z.enum(PROGRESSION_ACTIONS);
export type ProgressionAction = z.infer<typeof ProgressionActionSchema>;

export const NextPrescriptionSchema = z
  .object({
    action: ProgressionActionSchema,
    sets: z.number().int().min(1).max(10),
    repMin: z.number().int().min(1).max(50),
    repMax: z.number().int().min(1).max(50),
    targetRir: z.number().int().min(0).max(5),
    loadKg: z.number().min(0).nullable(),
    isDeload: z.boolean(),
    rationale: z.array(z.string()),
  })
  .strict();
export type NextPrescription = z.infer<typeof NextPrescriptionSchema>;

export type NextPrescriptionResult =
  | { ok: true; next: NextPrescription }
  | { ok: false; error: { code: 'INVALID_INPUT'; issues: { path: string; message: string }[] } };
