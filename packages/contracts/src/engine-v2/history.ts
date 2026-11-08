import { z } from 'zod';

export const IsoDateSchema = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'fecha ISO YYYY-MM-DD');

export const LoggedSetSchema = z
  .object({
    reps: z.number().int().min(0).max(100),
    loadKg: z.number().min(0).max(1000),
    rir: z.number().int().min(0).max(10).optional(),
    isWarmup: z.boolean().optional(),
  })
  .strict();
export type LoggedSet = z.infer<typeof LoggedSetSchema>;

/** Una sesión de un ejercicio concreto (`exerciseId` = slug del catálogo). */
export const ExerciseSessionLogSchema = z
  .object({
    date: IsoDateSchema,
    exerciseId: z.string().min(1),
    sets: z.array(LoggedSetSchema).min(1),
  })
  .strict();
export type ExerciseSessionLog = z.infer<typeof ExerciseSessionLogSchema>;

export const TrainingHistorySchema = z
  .object({
    entries: z.array(ExerciseSessionLogSchema).max(5000),
  })
  .strict();
export type TrainingHistory = z.infer<typeof TrainingHistorySchema>;
