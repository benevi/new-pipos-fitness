import { z } from 'zod';
import { MovementPatternSchema, MuscleSchema, VolumeGroupSchema } from './enums.js';

export const SPLIT_TYPES = ['full_body', 'upper_lower', 'hybrid_ul_ppl', 'push_pull_legs'] as const;
export const SplitTypeSchema = z.enum(SPLIT_TYPES);
export type SplitType = z.infer<typeof SplitTypeSchema>;

export const SESSION_KINDS = ['full_body', 'upper', 'lower', 'push', 'pull', 'legs'] as const;
export const SessionKindSchema = z.enum(SESSION_KINDS);
export type SessionKind = z.infer<typeof SessionKindSchema>;

export const EXERCISE_ROLES = ['main', 'secondary', 'accessory', 'core'] as const;
export const ExerciseRoleSchema = z.enum(EXERCISE_ROLES);
export type ExerciseRole = z.infer<typeof ExerciseRoleSchema>;

export const WarmupSetSchema = z
  .object({
    reps: z.number().int().min(1).max(20),
    /** % de la carga de trabajo; null si no hay carga conocida. */
    loadPct: z.number().min(0).max(100).nullable(),
    loadKg: z.number().min(0).nullable(),
  })
  .strict();
export type WarmupSet = z.infer<typeof WarmupSetSchema>;

export const PlannedExerciseSchema = z
  .object({
    order: z.number().int().min(0),
    exerciseId: z.string(),
    nameEs: z.string(),
    movementPattern: MovementPatternSchema,
    isCompound: z.boolean(),
    role: ExerciseRoleSchema,
    sets: z.number().int().min(1).max(10),
    repMin: z.number().int().min(1).max(50),
    repMax: z.number().int().min(1).max(50),
    targetRir: z.number().int().min(0).max(5),
    restSeconds: z.number().int().min(15).max(600),
    loadType: z.enum(['weighted', 'unweighted']),
    initialLoadKg: z.number().min(0).nullable(),
    initialLoadIsEstimate: z.boolean(),
    warmupSets: z.array(WarmupSetSchema),
    estimatedMinutes: z.number().min(0),
    rationale: z.array(z.string()),
  })
  .strict();
export type PlannedExercise = z.infer<typeof PlannedExerciseSchema>;

export const PlannedSessionSchema = z
  .object({
    order: z.number().int().min(0),
    dayIndex: z.number().int().min(0).max(6),
    kind: SessionKindSchema,
    name: z.string(),
    targetMinutes: z.number().int(),
    estimatedMinutes: z.number().min(0),
    exercises: z.array(PlannedExerciseSchema),
    rationale: z.array(z.string()),
  })
  .strict();
export type PlannedSession = z.infer<typeof PlannedSessionSchema>;

export const GroupVolumeSchema = z
  .object({
    group: VolumeGroupSchema,
    effectiveSets: z.number().min(0),
    min: z.number().min(0),
    max: z.number().min(0),
    sessions: z.number().int().min(0),
    isPriority: z.boolean(),
    status: z.enum(['below', 'within', 'above']),
  })
  .strict();
export type GroupVolume = z.infer<typeof GroupVolumeSchema>;

export const MuscleVolumeSchema = z
  .object({ muscle: MuscleSchema, effectiveSets: z.number().min(0) })
  .strict();
export type MuscleVolume = z.infer<typeof MuscleVolumeSchema>;

export const WARNING_CODES = [
  'PATTERN_UNCOVERED',
  'VOLUME_BELOW_FLOOR',
  'FREQUENCY_BELOW_MIN',
  'TIME_UNDERUSED',
  'TIME_OVER_BUDGET',
  'PRIORITY_UNCOVERED',
  'PUSH_PULL_IMBALANCE',
  'DAYS_ABOVE_LEVEL_GUIDE',
  'FAVOURITE_EXCLUDED',
  'LOCAL_SEARCH_TIME_LIMIT',
] as const;
export const WarningCodeSchema = z.enum(WARNING_CODES);
export type WarningCode = z.infer<typeof WarningCodeSchema>;

export const EngineWarningSchema = z
  .object({
    code: WarningCodeSchema,
    message: z.string(),
    data: z.record(z.union([z.string(), z.number(), z.boolean(), z.array(z.string())])).optional(),
  })
  .strict();
export type EngineWarning = z.infer<typeof EngineWarningSchema>;

export const ScoreBreakdownSchema = z
  .object({
    total: z.number().min(0).max(1),
    coverage: z.number().min(0).max(1),
    volumeFit: z.number().min(0).max(1),
    timeFit: z.number().min(0).max(1),
    frequency: z.number().min(0).max(1),
    balance: z.number().min(0).max(1),
    variety: z.number().min(0).max(1),
    preferences: z.number().min(0).max(1),
  })
  .strict();
export type ScoreBreakdown = z.infer<typeof ScoreBreakdownSchema>;

export const LocalSearchMetaSchema = z
  .object({
    iterations: z.number().int().min(0),
    evaluations: z.number().int().min(0),
    acceptedMoves: z.number().int().min(0),
    initialScore: z.number(),
    finalScore: z.number(),
    stoppedBy: z.enum(['converged', 'iterations', 'evaluations', 'time', 'disabled']),
  })
  .strict();
export type LocalSearchMeta = z.infer<typeof LocalSearchMetaSchema>;

export const PlanDraftSchema = z
  .object({
    engineVersion: z.string(),
    split: z.object({ type: SplitTypeSchema, rationale: z.array(z.string()) }).strict(),
    mesocycleWeeks: z.number().int().min(1).max(16),
    sessions: z.array(PlannedSessionSchema),
    weeklyVolume: z.array(GroupVolumeSchema),
    muscleVolume: z.array(MuscleVolumeSchema),
    warnings: z.array(EngineWarningSchema),
    rationale: z.array(z.string()),
    score: ScoreBreakdownSchema,
    meta: z
      .object({
        localSearch: LocalSearchMetaSchema,
        catalogSize: z.number().int().min(0),
        eligibleExercises: z.number().int().min(0),
      })
      .strict(),
  })
  .strict();
export type PlanDraft = z.infer<typeof PlanDraftSchema>;

export const ENGINE_ERROR_CODES = ['INVALID_PROFILE', 'INVALID_CATALOG', 'NO_EXERCISES'] as const;
export const EngineErrorSchema = z
  .object({
    code: z.enum(ENGINE_ERROR_CODES),
    message: z.string(),
    issues: z.array(z.object({ path: z.string(), message: z.string() }).strict()),
  })
  .strict();
export type EngineError = z.infer<typeof EngineErrorSchema>;

export type GeneratePlanResult = { ok: true; plan: PlanDraft } | { ok: false; error: EngineError };
