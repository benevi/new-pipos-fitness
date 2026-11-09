import { z } from 'zod';
import {
  BodyZoneSchema,
  MUSCLES,
  EquipmentSchema,
  LoadTypeSchema,
  MovementPatternSchema,
  MuscleRoleSchema,
  MuscleSchema,
  RiskLevelSchema,
  TrainingLevelSchema,
} from '../enums/index.js';
import { IdSchema, PaginationQuerySchema, paginatedSchema } from './common.js';
import { TEXT_LIMITS } from './limits.js';

/**
 * Músculo de un ejercicio tal y como se muestra en Hoy y en Plan (Fase 1 de la guía de
 * ejercicios, ADR-0014). Sin la fracción: es un detalle del motor.
 */
export const ExerciseMuscleRefSchema = z.object({ muscle: MuscleSchema, role: MuscleRoleSchema }).strict();
export type ExerciseMuscleRef = z.infer<typeof ExerciseMuscleRefSchema>;

const ROLE_ORDER = { primary: 0, secondary: 1 } as const;
const muscleRank = (m: ExerciseMuscleRef): number => ROLE_ORDER[m.role] * MUSCLES.length + MUSCLES.indexOf(m.muscle);

/** Orden de presentación: principales primero y, dentro de cada rol, en el orden del enum `MUSCLES`. */
export function sortExerciseMuscles<T extends ExerciseMuscleRef>(muscles: readonly T[]): ExerciseMuscleRef[] {
  return [...muscles].sort((a, b) => muscleRank(a) - muscleRank(b)).map((m) => ({ muscle: m.muscle, role: m.role }));
}

/**
 * ¿Lista en orden de presentación y sin músculos repetidos? La API la construye con
 * `sortExerciseMuscles`; los tests (contratos, e2e y fixtures) la comprueban con esto.
 * No es un `refine` del esquema para no perder el tipo en `openapi.json`.
 */
export function areExerciseMusclesOrdered(list: readonly ExerciseMuscleRef[]): boolean {
  const unique = new Set(list.map((m) => m.muscle)).size === list.length;
  return unique && list.every((m, i) => i === 0 || muscleRank(list[i - 1]) < muscleRank(m));
}

/**
 * Músculos de un ejercicio: principales primero y, dentro de cada rol, en el orden del enum
 * `MUSCLES` (ver `sortExerciseMuscles`). El `default` mantiene válidas las respuestas y fixtures
 * anteriores a la Fase 1 (ADR-0014).
 */
export const ExerciseMusclesSchema = z.array(ExerciseMuscleRefSchema).max(MUSCLES.length).default([]);

export const ExerciseListQuerySchema = PaginationQuerySchema.extend({
  movementPattern: MovementPatternSchema.optional(),
  /** Solo ejercicios realizables con este material (lista separada por comas). */
  equipment: z
    .string()
    .max(400)
    .transform((v) => v.split(',').map((s) => s.trim()).filter(Boolean))
    .pipe(z.array(EquipmentSchema).max(19))
    .optional(),
  level: TrainingLevelSchema.optional(),
  q: z.string().trim().min(1).max(TEXT_LIMITS.SEARCH).optional(),
}).strict();
export type ExerciseListQuery = z.infer<typeof ExerciseListQuerySchema>;

export const ExerciseSummarySchema = z
  .object({
    id: IdSchema,
    slug: z.string(),
    nameEs: z.string(),
    nameEn: z.string(),
    movementPattern: MovementPatternSchema,
    isCompound: z.boolean(),
    isUnilateral: z.boolean(),
    minLevel: TrainingLevelSchema,
    equipment: z.array(EquipmentSchema),
    loadType: LoadTypeSchema,
    primaryMuscles: z.array(MuscleSchema),
  })
  .strict();
export type ExerciseSummary = z.infer<typeof ExerciseSummarySchema>;

export const ExerciseDetailSchema = ExerciseSummarySchema.extend({
  muscles: z.array(z.object({ muscle: MuscleSchema, role: MuscleRoleSchema, fraction: z.number() }).strict()),
  riskTags: z.array(z.object({ zone: BodyZoneSchema, level: RiskLevelSchema }).strict()),
  substitutionGroup: z.string().nullable(),
  cuesEs: z.array(z.string()),
}).strict();
export type ExerciseDetail = z.infer<typeof ExerciseDetailSchema>;

export const ExerciseListResponseSchema = paginatedSchema(ExerciseSummarySchema);
export type ExerciseListResponse = z.infer<typeof ExerciseListResponseSchema>;
