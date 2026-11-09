import { z } from 'zod';
import { ExerciseRoleSchema, SessionKindSchema } from '../engine-v2/plan.js';
import { ProgressionActionSchema } from '../engine-v2/progression.js';
import { LoadTypeSchema, MovementPatternSchema, WorkoutStatusSchema } from '../enums/index.js';
import { DateTimeSchema, IdSchema } from './common.js';
import { WarmupSetResponseSchema } from './plans.js';

/**
 * Registro offline-first (ADR-0007). El móvil genera `clientId` (UUID v4) para cada
 * entrenamiento y cada serie: reenviar el mismo `clientId` devuelve la fila existente
 * (200) en lugar de crear otra.
 */
export const StartWorkoutRequestSchema = z
  .object({
    clientId: IdSchema,
    planSessionId: IdSchema,
    /** Reloj del cliente. */
    startedAt: DateTimeSchema,
  })
  .strict();
export type StartWorkoutRequest = z.infer<typeof StartWorkoutRequestSchema>;

export const UpsertSetRequestSchema = z
  .object({
    clientId: IdSchema,
    /** Hueco del plan; null/omitido = ejercicio añadido libremente. */
    planExerciseId: IdSchema.nullable().default(null),
    /** Ejercicio realmente hecho (puede ser un sustituto). */
    exerciseId: IdSchema,
    setIndex: z.number().int().min(0).max(50),
    reps: z.number().int().min(0).max(100),
    /** Peso corporal o banda = 0. */
    loadKg: z.number().min(0).max(1000),
    rir: z.number().int().min(0).max(10).nullable().default(null),
    isWarmup: z.boolean().default(false),
    completedAt: DateTimeSchema,
    /** Reloj del cliente de la última edición (por defecto = completedAt). */
    clientUpdatedAt: DateTimeSchema.optional(),
  })
  .strict();
export type UpsertSetRequest = z.input<typeof UpsertSetRequestSchema>;
export type UpsertSet = z.infer<typeof UpsertSetRequestSchema>;

/** Edición parcial; gana la última escritura según `clientUpdatedAt` (ADR-0007). */
export const PatchSetRequestSchema = z
  .object({
    reps: z.number().int().min(0).max(100).optional(),
    loadKg: z.number().min(0).max(1000).optional(),
    rir: z.number().int().min(0).max(10).nullable().optional(),
    isWarmup: z.boolean().optional(),
    clientUpdatedAt: DateTimeSchema,
  })
  .strict()
  .refine(
    (p) => p.reps !== undefined || p.loadKg !== undefined || p.rir !== undefined || p.isWarmup !== undefined,
    'At least one field to update is required',
  );
export type PatchSetRequest = z.infer<typeof PatchSetRequestSchema>;

export const SetLogResponseSchema = z
  .object({
    id: IdSchema,
    clientId: IdSchema,
    workoutId: IdSchema,
    planExerciseId: IdSchema.nullable(),
    exerciseId: IdSchema,
    setIndex: z.number().int(),
    reps: z.number().int(),
    loadKg: z.number(),
    rir: z.number().int().nullable(),
    isWarmup: z.boolean(),
    completedAt: DateTimeSchema,
    clientUpdatedAt: DateTimeSchema,
    deletedAt: DateTimeSchema.nullable(),
  })
  .strict();
export type SetLogResponse = z.infer<typeof SetLogResponseSchema>;

export const ExerciseRefSchema = z
  .object({ id: IdSchema, slug: z.string(), nameEs: z.string() })
  .strict();
export type ExerciseRef = z.infer<typeof ExerciseRefSchema>;

export const SubstitutionResponseSchema = z
  .object({
    workoutId: IdSchema,
    planExerciseId: IdSchema,
    exercise: ExerciseRefSchema,
    substitutedFrom: ExerciseRefSchema,
  })
  .strict();
export type SubstitutionResponse = z.infer<typeof SubstitutionResponseSchema>;

export const WorkoutResponseSchema = z
  .object({
    id: IdSchema,
    clientId: IdSchema,
    planSessionId: IdSchema,
    status: WorkoutStatusSchema,
    startedAt: DateTimeSchema,
    completedAt: DateTimeSchema.nullable(),
    sets: z.array(SetLogResponseSchema),
    substitutions: z.array(SubstitutionResponseSchema),
  })
  .strict();
export type WorkoutResponse = z.infer<typeof WorkoutResponseSchema>;

export const FinishWorkoutRequestSchema = z.object({ completedAt: DateTimeSchema }).strict();
export type FinishWorkoutRequest = z.infer<typeof FinishWorkoutRequestSchema>;

export const SubstituteExerciseRequestSchema = z.object({ exerciseId: IdSchema }).strict();
export type SubstituteExerciseRequest = z.infer<typeof SubstituteExerciseRequestSchema>;

export const SubstituteOptionSchema = z
  .object({
    exerciseId: IdSchema,
    slug: z.string(),
    nameEs: z.string(),
    score: z.number(),
    rationale: z.array(z.string()),
  })
  .strict();
export type SubstituteOption = z.infer<typeof SubstituteOptionSchema>;

export const SubstitutesResponseSchema = z
  .object({
    exercise: ExerciseRefSchema,
    substitutes: z.array(SubstituteOptionSchema).max(3),
  })
  .strict();
export type SubstitutesResponse = z.infer<typeof SubstitutesResponseSchema>;

// ── Sesión de hoy (CUJ-2) ──

export const TodayPrescriptionSchema = z
  .object({
    action: ProgressionActionSchema,
    sets: z.number().int(),
    repMin: z.number().int(),
    repMax: z.number().int(),
    targetRir: z.number().int(),
    /** Carga sugerida (null = sin carga conocida: elige un peso con el RIR objetivo). */
    loadKg: z.number().nullable(),
    isDeload: z.boolean(),
    rationale: z.array(z.string()),
  })
  .strict();
export type TodayPrescription = z.infer<typeof TodayPrescriptionSchema>;

export const TodayExerciseSchema = z
  .object({
    planExerciseId: IdSchema,
    order: z.number().int(),
    exercise: ExerciseRefSchema,
    /** Ejercicio original del plan si se ha sustituido en el entrenamiento en curso. */
    substitutedFrom: ExerciseRefSchema.nullable(),
    cuesEs: z.array(z.string()),
    movementPattern: MovementPatternSchema,
    loadType: LoadTypeSchema,
    role: ExerciseRoleSchema,
    restSeconds: z.number().int(),
    prescription: TodayPrescriptionSchema,
    warmupSets: z.array(WarmupSetResponseSchema),
    /** Series ya registradas en el entrenamiento en curso. */
    loggedSets: z.array(SetLogResponseSchema),
  })
  .strict();
export type TodayExercise = z.infer<typeof TodayExerciseSchema>;

export const TodaySessionResponseSchema = z
  .object({
    planVersionId: IdSchema,
    planSessionId: IdSchema,
    order: z.number().int(),
    dayIndex: z.number().int(),
    kind: SessionKindSchema,
    name: z.string(),
    targetMinutes: z.number().int(),
    estimatedMinutes: z.number(),
    generalWarmupMinutes: z.number(),
    rationale: z.array(z.string()),
    /** Fecha local del usuario (su zona horaria) usada para la progresión. */
    today: z.string(),
    workout: z
      .object({ id: IdSchema, clientId: IdSchema, status: WorkoutStatusSchema, startedAt: DateTimeSchema })
      .strict()
      .nullable(),
    exercises: z.array(TodayExerciseSchema),
  })
  .strict();
export type TodaySessionResponse = z.infer<typeof TodaySessionResponseSchema>;
