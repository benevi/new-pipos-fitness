import { z } from 'zod';
import {
  BodyZoneSchema,
  EquipmentSchema,
  MuscleSchema,
  SexSchema,
  TrainingGoalSchema,
  TrainingLevelSchema,
} from './enums.js';
import { TrainingHistorySchema } from './history.js';

export const BodyDataSchema = z
  .object({
    weightKg: z.number().min(25).max(400).optional(),
    heightCm: z.number().min(100).max(250).optional(),
    age: z.number().int().min(14).max(100).optional(),
    sex: SexSchema.optional(),
  })
  .strict();
export type BodyData = z.infer<typeof BodyDataSchema>;

/**
 * Perfil de entrada del motor v2. No se rellena nada por defecto salvo listas opcionales vacías.
 * `bodyweight` se añade siempre al material al normalizar (todo el mundo tiene su cuerpo).
 */
export const EngineProfileSchema = z
  .object({
    goal: TrainingGoalSchema,
    level: TrainingLevelSchema,
    daysPerWeek: z.number().int().min(2).max(6),
    minutesPerSession: z.number().int().min(30).max(90),
    equipment: z.array(EquipmentSchema),
    limitations: z.array(BodyZoneSchema).default([]),
    priorityMuscles: z.array(MuscleSchema).max(3).default([]),
    bannedExerciseIds: z.array(z.string().min(1)).default([]),
    favouriteExerciseIds: z.array(z.string().min(1)).default([]),
    body: BodyDataSchema.optional(),
    history: TrainingHistorySchema.optional(),
  })
  .strict();
export type EngineProfileInput = z.input<typeof EngineProfileSchema>;
export type EngineProfile = z.infer<typeof EngineProfileSchema>;
