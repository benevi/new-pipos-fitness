import { z } from 'zod';
import {
  EngineWarningSchema,
  ExerciseRoleSchema,
  GroupVolumeSchema,
  SessionKindSchema,
  SplitTypeSchema,
} from '../engine-v2/plan.js';
import { LoadImplementSchema } from '../engine-v2/enums.js';
import { LoadTypeSchema, MovementPatternSchema } from '../enums/index.js';
import { DateTimeSchema, IdSchema, paginatedSchema } from './common.js';

export const WarmupSetResponseSchema = z
  .object({
    reps: z.number().int(),
    /** % de la carga de trabajo. */
    loadPct: z.number().nullable(),
    /** Redondeado al incremento de disco; null si no hay carga de trabajo conocida. */
    loadKg: z.number().nullable(),
  })
  .strict();
export type WarmupSetResponse = z.infer<typeof WarmupSetResponseSchema>;

export const PlanExerciseResponseSchema = z
  .object({
    /** Id del hueco del plan (planExerciseId en los endpoints de entrenamiento). */
    id: IdSchema,
    order: z.number().int(),
    exerciseId: IdSchema,
    slug: z.string(),
    nameEs: z.string(),
    movementPattern: MovementPatternSchema,
    loadType: LoadTypeSchema,
    role: ExerciseRoleSchema,
    sets: z.number().int(),
    repMin: z.number().int(),
    repMax: z.number().int(),
    targetRir: z.number().int(),
    restSeconds: z.number().int(),
    initialLoadKg: z.number().nullable(),
    initialLoadIsEstimate: z.boolean(),
    /**
     * Material que fija el paso de carga (PROGRAMACION.md §16.16); null sin carga en kg.
     * El servidor siempre lo envía; el `default` solo mantiene válidos los clientes anteriores.
     */
    loadImplement: LoadImplementSchema.nullable().default(null),
    warmupSets: z.array(WarmupSetResponseSchema),
    estimatedMinutes: z.number(),
    rationale: z.array(z.string()),
  })
  .strict();
export type PlanExerciseResponse = z.infer<typeof PlanExerciseResponseSchema>;

export const PlanSessionResponseSchema = z
  .object({
    id: IdSchema,
    order: z.number().int(),
    dayIndex: z.number().int().min(0).max(6),
    kind: SessionKindSchema,
    name: z.string(),
    targetMinutes: z.number().int(),
    estimatedMinutes: z.number(),
    rationale: z.array(z.string()),
    exercises: z.array(PlanExerciseResponseSchema),
  })
  .strict();
export type PlanSessionResponse = z.infer<typeof PlanSessionResponseSchema>;

export const PlanVersionSummarySchema = z
  .object({
    id: IdSchema,
    planId: IdSchema,
    version: z.number().int().min(1),
    engineVersion: z.string(),
    splitType: SplitTypeSchema,
    mesocycleWeeks: z.number().int(),
    objectiveScore: z.number(),
    sessionCount: z.number().int(),
    createdAt: DateTimeSchema,
  })
  .strict();
export type PlanVersionSummary = z.infer<typeof PlanVersionSummarySchema>;

export const PlanVersionResponseSchema = PlanVersionSummarySchema.extend({
  split: z.object({ type: SplitTypeSchema, rationale: z.array(z.string()) }).strict(),
  rationale: z.array(z.string()),
  warnings: z.array(EngineWarningSchema),
  weeklyVolume: z.array(GroupVolumeSchema),
  sessions: z.array(PlanSessionResponseSchema),
}).strict();
export type PlanVersionResponse = z.infer<typeof PlanVersionResponseSchema>;

export const PlanVersionListResponseSchema = paginatedSchema(PlanVersionSummarySchema);
export type PlanVersionListResponse = z.infer<typeof PlanVersionListResponseSchema>;
