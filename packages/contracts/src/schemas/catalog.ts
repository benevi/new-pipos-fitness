import { z } from 'zod';
import {
  BodyZoneSchema,
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
