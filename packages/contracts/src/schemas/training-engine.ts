import { z } from 'zod';
import {
  MusclePriority,
  MuscleRole,
  GoalType,
  TrainingLevel,
  TrainingLocation,
} from '../enums/index.js';

/** Catalog exercise snapshot for engine input (no DB dependency). */
export const CatalogExerciseSnapshotSchema = z.object({
  id: z.string(),
  name: z.string(),
  difficulty: z.number().int().min(1).max(5),
  movementPattern: z.string().nullable(),
  place: z.nativeEnum(TrainingLocation),
  equipmentIds: z.array(z.string()),
  muscles: z.array(
    z.object({
      muscleId: z.string(),
      role: z.nativeEnum(MuscleRole),
    }),
  ),
});

export type CatalogExerciseSnapshot = z.infer<typeof CatalogExerciseSnapshotSchema>;

export const TrainingEngineUserSchema = z.object({
  trainingLevel: z.nativeEnum(TrainingLevel),
  sex: z.string().optional(),
  heightCm: z.number().positive().nullable().optional(),
  weightKg: z.number().positive().nullable().optional(),
  age: z.number().int().positive().nullable().optional(),
});

export type TrainingEngineUser = z.infer<typeof TrainingEngineUserSchema>;

export const TrainingEnginePreferencesSchema = z.object({
  daysPerWeek: z.number().int().min(1).max(7),
  minutesPerSession: z.number().int().min(20).max(120),
  trainingLocation: z.nativeEnum(TrainingLocation),
  availableEquipmentIds: z.array(z.string()),
  dislikedExerciseIds: z.array(z.string()).optional(),
});

export type TrainingEnginePreferences = z.infer<typeof TrainingEnginePreferencesSchema>;

export const TrainingEngineGoalItemSchema = z.object({
  type: z.nativeEnum(GoalType),
  priority: z.number().int().min(1).max(5),
});

export const TrainingEngineMuscleFocusItemSchema = z.object({
  muscleId: z.string(),
  priority: z.nativeEnum(MusclePriority),
});

export const TrainingEngineCatalogSnapshotSchema = z.object({
  exercises: z.array(CatalogExerciseSnapshotSchema),
});

export type TrainingEngineCatalogSnapshot = z.infer<typeof TrainingEngineCatalogSnapshotSchema>;

/** Per-exercise history for adaptive engine (from workout logs). */
export const ExerciseHistoryItemSchema = z.object({
  exerciseId: z.string(),
  estimated1RM: z.number().positive().nullable(),
  volumeLastWeek: z.number().min(0).nullable(),
  volumeTrend: z.enum(['up', 'down', 'stable']).nullable(),
  fatigueScore: z.number().min(0).max(1).nullable(),
});
export type ExerciseHistoryItem = z.infer<typeof ExerciseHistoryItemSchema>;

export const TrainingEngineProgressSchema = z.object({
  exerciseHistory: z.array(ExerciseHistoryItemSchema),
  weeklyVolume: z.record(z.string(), z.number().min(0)).optional(),
  adherenceScore: z.number().min(0).max(1).nullable().optional(),
  fatigueScore: z.number().min(0).max(1).nullable().optional(),
});
export type TrainingEngineProgress = z.infer<typeof TrainingEngineProgressSchema>;

export const TrainingEngineInputSchema = z.object({
  user: TrainingEngineUserSchema,
  preferences: TrainingEnginePreferencesSchema,
  goals: z.array(TrainingEngineGoalItemSchema).optional(),
  muscleFocus: z.array(TrainingEngineMuscleFocusItemSchema).optional(),
  catalog: TrainingEngineCatalogSnapshotSchema,
  progress: TrainingEngineProgressSchema.optional(),
});

export type TrainingEngineInput = z.infer<typeof TrainingEngineInputSchema>;

/** Plan exercise slot (per session). */
export const PlanExerciseSchema = z
  .object({
    exerciseId: z.string(),
    sets: z.number().int().min(1).max(10),
    repRangeMin: z.number().int().min(1).max(50),
    repRangeMax: z.number().int().min(1).max(50),
    restSeconds: z.number().int().min(0).max(300),
    rirTarget: z.number().int().min(0).max(3),
  })
  .refine((d: { repRangeMin: number; repRangeMax: number }) => d.repRangeMin <= d.repRangeMax, {
    message: 'repRangeMin must be <= repRangeMax',
    path: ['repRangeMax'],
  });

export type PlanExercise = z.infer<typeof PlanExerciseSchema>;

export const PlanSessionSchema = z.object({
  sessionIndex: z.number().int().min(0),
  name: z.string(),
  targetDurationMinutes: z.number().int().min(1),
  exercises: z.array(PlanExerciseSchema),
});

export type PlanSession = z.infer<typeof PlanSessionSchema>;

export const ConstraintViolationSchema = z.object({
  code: z.string(),
  message: z.string().optional(),
});

export type ConstraintViolation = z.infer<typeof ConstraintViolationSchema>;

export const TrainingEngineOutputMetadataSchema = z.object({
  engineVersion: z.string(),
  objectiveScore: z.number(),
  constraintViolations: z.array(ConstraintViolationSchema),
});

export const TrainingEngineOutputSchema = z.object({
  metadata: TrainingEngineOutputMetadataSchema,
  weekPlan: z.object({
    sessions: z.array(PlanSessionSchema),
  }),
});

export type TrainingEngineOutput = z.infer<typeof TrainingEngineOutputSchema>;

// --- API response shapes (Phase 5) ---

export const TrainingSessionExerciseSchema = z.object({
  id: z.string().uuid(),
  sessionId: z.string().uuid(),
  exerciseId: z.string(),
  sets: z.number().int().min(1).max(10),
  repRangeMin: z.number().int().min(1).max(50),
  repRangeMax: z.number().int().min(1).max(50),
  restSeconds: z.number().int().min(0).max(300),
  rirTarget: z.number().int().min(0).max(3),
});
export type TrainingSessionExercise = z.infer<typeof TrainingSessionExerciseSchema>;

export const TrainingSessionSchema = z.object({
  id: z.string().uuid(),
  planVersionId: z.string().uuid(),
  sessionIndex: z.number().int().min(0),
  name: z.string(),
  targetDurationMinutes: z.number().int().min(1),
  exercises: z.array(TrainingSessionExerciseSchema),
});
export type TrainingSession = z.infer<typeof TrainingSessionSchema>;

export const TrainingPlanVersionSchema = z.object({
  id: z.string().uuid(),
  planId: z.string().uuid(),
  version: z.number().int().min(1),
  createdAt: z.string().datetime(),
  engineVersion: z.string(),
  objectiveScore: z.number(),
  sessions: z.array(TrainingSessionSchema),
});
export type TrainingPlanVersion = z.infer<typeof TrainingPlanVersionSchema>;

export const GenerateTrainingPlanResponseSchema = z.object({
  plan: z.object({
    id: z.string().uuid(),
    userId: z.string().uuid(),
    createdAt: z.string().datetime(),
    currentVersionId: z.string().uuid().nullable(),
  }),
  version: TrainingPlanVersionSchema,
});
export type GenerateTrainingPlanResponse = z.infer<typeof GenerateTrainingPlanResponseSchema>;
