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
import { ExerciseMusclesSchema } from './catalog.js';
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

/** Referencia corta a un ejercicio (misma forma que ExerciseRefSchema de workouts). */
export const PlanExerciseRefSchema = z.object({ id: IdSchema, slug: z.string(), nameEs: z.string() }).strict();
export type PlanExerciseRef = z.infer<typeof PlanExerciseRefSchema>;

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
    /** Ejercicio que el usuario ha fijado para este hueco (idea 3); null = el del plan. */
    pinned: PlanExerciseRefSchema.nullable().default(null),
    warmupSets: z.array(WarmupSetResponseSchema),
    estimatedMinutes: z.number(),
    rationale: z.array(z.string()),
    /**
     * Músculos del ejercicio que se hace en este hueco (el fijado si lo hay): principales
     * primero (ADR-0014, Fase 1). Vacío si el ejercicio ya no está en el catálogo activo.
     */
    muscles: ExerciseMusclesSchema,
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

/**
 * PUT /plans/current/exercises/:planExerciseId/override — «usar siempre este ejercicio en este
 * plan» (idea 3, ADR-0013). Debe ser una alternativa válida del original para tu perfil (la misma
 * validación que el cambio puntual). Se aplica a todos los huecos de la versión vigente con el
 * mismo ejercicio original y se hereda en las versiones siguientes mientras siga siendo válido.
 */
export const PlanExerciseOverrideRequestSchema = z.object({ exerciseId: IdSchema }).strict();
export type PlanExerciseOverrideRequest = z.infer<typeof PlanExerciseOverrideRequestSchema>;

export const PlanExerciseOverrideResponseSchema = z
  .object({
    planVersionId: IdSchema,
    /** Huecos de la versión vigente afectados (todos los del mismo ejercicio original). */
    planExerciseIds: z.array(IdSchema).min(1),
    original: PlanExerciseRefSchema,
    /** Ejercicio fijado; null tras volver al original (DELETE). */
    pinned: PlanExerciseRefSchema.nullable(),
  })
  .strict();
export type PlanExerciseOverrideResponse = z.infer<typeof PlanExerciseOverrideResponseSchema>;
