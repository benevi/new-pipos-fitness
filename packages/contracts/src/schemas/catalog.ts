import { z } from 'zod';
import {
  BodyZoneSchema,
  MUSCLES,
  EquipmentSchema,
  LoadTypeSchema,
  LocaleSchema,
  MovementPatternSchema,
  MuscleRoleSchema,
  MuscleSchema,
  RiskLevelSchema,
  TrainingLevelSchema,
} from '../enums/index.js';
import {
  EXERCISE_MEDIA_MAX,
  MEDIA_IMAGE_FILE_REGEX,
  MediaImageLicenceSchema,
  YOUTUBE_VIDEO_ID_REGEX,
} from '../engine-v2/catalog.js';
import { ExerciseSlugSchema, IdSchema, PaginationQuerySchema, paginatedSchema } from './common.js';
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

/** `GET /exercises/:id` acepta el id (UUID) o el slug del ejercicio (ADR-0014). */
export const ExerciseIdOrSlugParamsSchema = z.object({ id: z.union([IdSchema, ExerciseSlugSchema]) }).strict();
export type ExerciseIdOrSlugParams = z.infer<typeof ExerciseIdOrSlugParamsSchema>;

/**
 * Medio de técnica revisado (ADR-0014, Fase 4): solo los del catálogo, aprobados por PR
 * (ADR-0005). Nunca un enlace a una búsqueda ni un medio sin revisar. El principal va primero.
 */
export const ExerciseMediaSchema = z.discriminatedUnion('kind', [
  z
    .object({
      kind: z.literal('youtube'),
      videoId: z.string().regex(YOUTUBE_VIDEO_ID_REGEX),
      /** Segundo de inicio (null = desde el principio). */
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
      /** Fichero del paquete del catálogo (`packages/catalog/media/`). */
      file: z.string().regex(MEDIA_IMAGE_FILE_REGEX),
      credit: z.string(),
      licence: MediaImageLicenceSchema,
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
  /** Vídeos e imágenes revisados (0-2, el principal primero); vacía si nadie ha aprobado ninguno. */
  media: z.array(ExerciseMediaSchema).max(EXERCISE_MEDIA_MAX).default([]),
}).strict();
export type ExerciseDetail = z.infer<typeof ExerciseDetailSchema>;

export const ExerciseListResponseSchema = paginatedSchema(ExerciseSummarySchema);
export type ExerciseListResponse = z.infer<typeof ExerciseListResponseSchema>;
