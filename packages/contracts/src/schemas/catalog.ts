import { z } from 'zod';
import {
  BodyZoneSchema,
  EquipmentSchema,
  LoadTypeSchema,
  LocaleSchema,
  MovementPatternSchema,
  MuscleRoleSchema,
  MuscleSchema,
  RiskLevelSchema,
  TrainingLevelSchema,
} from '../enums/index.js';
import { ExerciseSlugSchema, IdSchema, PaginationQuerySchema, paginatedSchema } from './common.js';
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

/** `GET /exercises/:id` acepta el id (UUID) o el slug del ejercicio (ADR-0014). */
export const ExerciseIdOrSlugParamsSchema = z.object({ id: z.union([IdSchema, ExerciseSlugSchema]) }).strict();
export type ExerciseIdOrSlugParams = z.infer<typeof ExerciseIdOrSlugParamsSchema>;

/**
 * Medio de técnica revisado (ADR-0014, Fase 4). Hasta la Fase 4 la lista llega siempre vacía:
 * nunca se envía un enlace a una búsqueda ni un medio sin revisar.
 */
export const ExerciseMediaSchema = z.discriminatedUnion('kind', [
  z
    .object({
      kind: z.literal('youtube'),
      videoId: z.string().regex(/^[A-Za-z0-9_-]{11}$/),
      startSeconds: z.number().int().nonnegative().nullable(),
      endSeconds: z.number().int().positive().nullable(),
      channelName: z.string(),
      locale: LocaleSchema,
      isPrimary: z.boolean(),
    })
    .strict(),
  z
    .object({
      kind: z.literal('image'),
      url: z.string().url(),
      credit: z.string(),
      licence: z.string(),
      isPrimary: z.boolean(),
    })
    .strict(),
]);
export type ExerciseMedia = z.infer<typeof ExerciseMediaSchema>;

export const ExerciseDetailSchema = ExerciseSummarySchema.extend({
  muscles: z.array(z.object({ muscle: MuscleSchema, role: MuscleRoleSchema, fraction: z.number() }).strict()),
  riskTags: z.array(z.object({ zone: BodyZoneSchema, level: RiskLevelSchema }).strict()),
  substitutionGroup: z.string().nullable(),
  cuesEs: z.array(z.string()),
  /** Qué es el movimiento y qué trabaja (ficha, ADR-0014). null si aún no está escrita. */
  descriptionEs: z.string().nullable().default(null),
  /** Errores comunes (0-3). */
  mistakesEs: z.array(z.string()).default([]),
  /** Vídeos e imágenes revisados; lista vacía hasta la Fase 4. */
  media: z.array(ExerciseMediaSchema).default([]),
}).strict();
export type ExerciseDetail = z.infer<typeof ExerciseDetailSchema>;

export const ExerciseListResponseSchema = paginatedSchema(ExerciseSummarySchema);
export type ExerciseListResponse = z.infer<typeof ExerciseListResponseSchema>;
