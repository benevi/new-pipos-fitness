import { z } from 'zod';
import { LoadImplementSchema } from '../engine-v2/enums.js';
import { PlateBreakdownSchema } from '../engine-v2/load.js';
import { ExerciseRoleSchema, SessionKindSchema } from '../engine-v2/plan.js';
import { ProgressionActionSchema } from '../engine-v2/progression.js';
import { LoadTypeSchema, MovementPatternSchema, MuscleSchema, WorkoutStatusSchema } from '../enums/index.js';
import { ExerciseMusclesSchema } from './catalog.js';
import { DateTimeSchema, IdSchema } from './common.js';
import { WarmupSetResponseSchema } from './plans.js';

/**
 * Registro offline-first (ADR-0007). El móvil genera `clientId` (UUID v4) para cada
 * entrenamiento y cada serie: reenviar el mismo `clientId` devuelve la fila existente
 * (200) en lugar de crear otra.
 */
/**
 * Ajuste de la sesión de hoy (idea 4, ADR-0013; PROGRAMACION.md §16.17): minutos disponibles
 * (15-90, incluye el calentamiento general; null = sin límite) y volumen reducido voluntario.
 * Solo se guarda el modo elegido, nunca el motivo.
 */
export const WorkoutAdjustmentSchema = z
  .object({
    availableMinutes: z.number().int().min(15).max(90).nullable().default(null),
    reducedVolume: z.boolean().default(false),
  })
  .strict();
export type WorkoutAdjustment = z.infer<typeof WorkoutAdjustmentSchema>;

export const StartWorkoutRequestSchema = z
  .object({
    clientId: IdSchema,
    planSessionId: IdSchema,
    /** Reloj del cliente. */
    startedAt: DateTimeSchema,
    /** Ajuste elegido antes de empezar; `GET /sessions/today` lo aplica mientras dure el entrenamiento. */
    adjustment: WorkoutAdjustmentSchema.optional(),
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
    /** Ajuste guardado al empezar (null = sesión completa). Siempre presente en el servidor. */
    adjustment: WorkoutAdjustmentSchema.nullable().default(null),
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
    /**
     * Músculos principales de la alternativa, en el orden del enum (ADR-0014, Fase 1). El
     * `default` mantiene válidas las respuestas guardadas en caché antes de la Fase 1.
     */
    primaryMuscles: z.array(MuscleSchema).default([]),
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
    // ── Campos añadidos (ADR-0013). El servidor siempre los envía; el `default` solo mantiene
    //    válidos los clientes y fixtures anteriores.
    /** Material que fija el paso de carga (PROGRAMACION.md §16.16); null sin carga en kg. */
    loadImplement: LoadImplementSchema.nullable().default(null),
    /** Paso real de carga del material (kg totales); null sin carga en kg. */
    loadStepKg: z.number().positive().nullable().default(null),
    /** Discos por lado para la carga sugerida (solo barras con peso conocido y carga ≥ barra). */
    plates: PlateBreakdownSchema.nullable().default(null),
    /** true si el ejercicio de hoy es un cambio fijado del plan (idea 3); `substitutedFrom` es el original. */
    pinned: z.boolean().default(false),
    /** Nota fija del usuario para el ejercicio realmente hecho (idea 2); null si no hay. */
    note: z.string().nullable().default(null),
    // ── Fase 1 de la guía de ejercicios (ADR-0014).
    /** Músculos del ejercicio realmente hecho (sustituto o fijado incluidos): principales primero. */
    muscles: ExerciseMusclesSchema,
  })
  .strict();
export type TodayExercise = z.infer<typeof TodayExerciseSchema>;

/**
 * GET /sessions/today?minutes=30&mode=reduced — vista ajustada de la sesión de hoy (solo lectura:
 * no guarda nada ni crea una versión del plan). Sin parámetros y con un entrenamiento en curso,
 * se aplica el ajuste guardado al empezarlo.
 */
export const TodaySessionQuerySchema = z
  .object({
    minutes: z.coerce.number().int().min(15).max(90).optional(),
    mode: z.enum(['normal', 'reduced']).optional(),
  })
  .strict();
export type TodaySessionQuery = z.infer<typeof TodaySessionQuerySchema>;

export const TodayAdjustmentSchema = z
  .object({
    /** De dónde sale el ajuste: parámetros de la petición o el entrenamiento en curso. */
    source: z.enum(['query', 'workout']),
    availableMinutes: z.number().int().nullable(),
    reducedVolume: z.boolean(),
    /** Estimación de la sesión ajustada (min, incluye el calentamiento general). */
    estimatedMinutes: z.number(),
    /** false si ni con solo los principales al mínimo cabe en el tiempo. */
    fits: z.boolean(),
    /** Ejercicios quitados hoy (no aparecen en `exercises`), en el orden en que se quitaron. */
    dropped: z.array(z.object({ planExerciseId: IdSchema, exercise: ExerciseRefSchema }).strict()),
    rationale: z.array(z.string()),
  })
  .strict();
export type TodayAdjustment = z.infer<typeof TodayAdjustmentSchema>;

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
    /**
     * ¿Hoy es uno de tus días de entreno? (idea 6; los días por defecto del plan si no has elegido;
     * false en pausa). Es informativo: puedes entrenar igualmente.
     */
    scheduledToday: z.boolean().default(true),
    /** Pausa planificada que cubre hoy, o null. */
    activeBreak: z
      .object({ id: IdSchema, startsOn: z.string(), endsOn: z.string() })
      .strict()
      .nullable()
      .default(null),
    /** Ajuste aplicado hoy (idea 4); null = sesión completa. Siempre presente en el servidor. */
    adjustment: TodayAdjustmentSchema.nullable().default(null),
  })
  .strict();
export type TodaySessionResponse = z.infer<typeof TodaySessionResponseSchema>;
