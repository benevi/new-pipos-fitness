import { z } from 'zod';
import {
  BodyZoneSchema,
  EquipmentSchema,
  MovementPatternSchema,
  MuscleRoleSchema,
  MuscleSchema,
  RiskLevelSchema,
  TrainingLevelSchema,
} from './enums.js';

export const SLUG_REGEX = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

/** Límites del contenido de la ficha del ejercicio (ADR-0014, PLAN_GUIA_EJERCICIOS §Fase 2). */
export const EXERCISE_DESCRIPTION_MAX = 400;
export const EXERCISE_MISTAKE_MAX = 120;

/** Medios por ejercicio (ADR-0014, PLAN_GUIA_EJERCICIOS §Fase 4): como mucho 2, uno principal. */
export const EXERCISE_MEDIA_MAX = 2;

/** Identificador de vídeo de YouTube: 11 caracteres de [A-Za-z0-9_-]. */
export const YOUTUBE_VIDEO_ID_REGEX = /^[A-Za-z0-9_-]{11}$/;

/** Nombre de fichero de una imagen del paquete (`packages/catalog/media/`): minúsculas y WebP/PNG/JPG. */
export const MEDIA_IMAGE_FILE_REGEX = /^[a-z0-9]+(?:-[a-z0-9]+)*\.(?:webp|png|jpg)$/;

/**
 * Licencias aceptadas para imágenes del catálogo. Una imagen sin licencia declarada (o con otra)
 * no pasa la validación: se amplía la lista por PR si hace falta.
 */
export const MEDIA_IMAGE_LICENCES = ['own-work', 'CC0-1.0', 'CC-BY-4.0', 'CC-BY-SA-4.0'] as const;
export const MediaImageLicenceSchema = z.enum(MEDIA_IMAGE_LICENCES);

/** Idiomas de un vídeo (los mismos que la app). */
export const MediaLocaleSchema = z.enum(['es', 'en']);

export const CatalogMuscleSchema = z
  .object({
    muscle: MuscleSchema,
    role: MuscleRoleSchema,
    /** Fracción de serie efectiva: 1 directa, 0,5 indirecta (PROGRAMACION.md §1). */
    fraction: z.number().gt(0).lte(1),
  })
  .strict();
export type CatalogMuscle = z.infer<typeof CatalogMuscleSchema>;

export const CatalogRiskTagSchema = z
  .object({
    zone: BodyZoneSchema,
    level: RiskLevelSchema,
  })
  .strict();
export type CatalogRiskTag = z.infer<typeof CatalogRiskTagSchema>;

/**
 * Vídeo de YouTube concreto, elegido y aprobado por una persona según los criterios de ADR-0014
 * (la revisión es el PR, ADR-0005). Nunca un enlace a una búsqueda.
 */
export const CatalogYoutubeMediaSchema = z
  .object({
    kind: z.literal('youtube'),
    videoId: z.string().regex(YOUTUBE_VIDEO_ID_REGEX, 'videoId de YouTube inválido (11 caracteres)'),
    /** Segundo en que empieza la parte útil del vídeo (0 si se omite). */
    startSeconds: z.number().int().nonnegative().optional(),
    /** Segundo en que acaba la parte útil; mayor que `startSeconds`. */
    endSeconds: z.number().int().positive().optional(),
    channelName: z.string().trim().min(2).max(100),
    locale: MediaLocaleSchema,
    isPrimary: z.boolean(),
  })
  .strict();
export type CatalogYoutubeMedia = z.infer<typeof CatalogYoutubeMediaSchema>;

/**
 * Imagen propia incluida en el paquete del catálogo (`packages/catalog/media/<file>`), con crédito
 * y licencia declarados. Que el fichero exista lo comprueba `@pipos/catalog` (necesita disco).
 */
export const CatalogImageMediaSchema = z
  .object({
    kind: z.literal('image'),
    file: z.string().max(96).regex(MEDIA_IMAGE_FILE_REGEX, 'nombre de imagen inválido'),
    credit: z.string().trim().min(2).max(120),
    licence: MediaImageLicenceSchema,
    isPrimary: z.boolean(),
  })
  .strict();
export type CatalogImageMedia = z.infer<typeof CatalogImageMediaSchema>;

export const CatalogMediaSchema = z
  .discriminatedUnion('kind', [CatalogYoutubeMediaSchema, CatalogImageMediaSchema])
  .superRefine((m, ctx) => {
    if (m.kind === 'youtube' && m.endSeconds !== undefined && m.endSeconds <= (m.startSeconds ?? 0)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'endSeconds debe ser mayor que startSeconds',
        path: ['endSeconds'],
      });
    }
  });
export type CatalogMedia = z.infer<typeof CatalogMediaSchema>;

/** Clave que identifica un medio dentro de su ejercicio (el seed la usa para conservar filas). */
export function catalogMediaKey(m: CatalogMedia): string {
  return m.kind === 'youtube' ? `youtube:${m.videoId}` : `image:${m.file}`;
}

/**
 * Ejercicio del catálogo tal como lo consume el motor. El identificador estable es `slug`:
 * los `bannedExerciseIds`, `favouriteExerciseIds` y `exerciseId` del historial son slugs.
 */
export const CatalogExerciseSchema = z
  .object({
    slug: z.string().min(2).max(96).regex(SLUG_REGEX),
    nameEs: z.string().min(2),
    nameEn: z.string().min(2),
    movementPattern: MovementPatternSchema,
    isCompound: z.boolean(),
    isUnilateral: z.boolean(),
    minLevel: TrainingLevelSchema,
    /** TODO el material es obligatorio (el motor usa `.every`). Sin material: ['bodyweight']. */
    equipment: z.array(EquipmentSchema).min(1),
    /** 'weighted' si la carga se mide y progresa en kg; 'unweighted' para peso corporal, bandas o asistencia. */
    loadType: z.enum(['weighted', 'unweighted']),
    muscles: z.array(CatalogMuscleSchema).min(1),
    riskTags: z.array(CatalogRiskTagSchema),
    substitutionGroup: z
      .string()
      .min(2)
      .max(64)
      .regex(/^[a-z0-9_]+$/),
    cuesEs: z.array(z.string().min(3).max(120)).min(2).max(3),
    /**
     * Qué es el movimiento y qué trabaja, en 1-3 frases (ADR-0014). Sin promesas de efectos sin
     * fuente. Contenido pendiente de revisión por un entrenador titulado antes del lanzamiento.
     */
    descriptionEs: z.string().min(20).max(EXERCISE_DESCRIPTION_MAX),
    /** Errores comunes (0-3), cada uno ≤ 120 caracteres (ADR-0014). */
    mistakesEs: z.array(z.string().min(3).max(EXERCISE_MISTAKE_MAX)).max(3),
    /**
     * Vídeos e imágenes revisados (ADR-0014, Fase 4): 0-2, y si hay alguno, exactamente uno
     * principal. Vacía mientras nadie haya elegido y aprobado un medio por PR.
     */
    media: z.array(CatalogMediaSchema).max(EXERCISE_MEDIA_MAX),
  })
  .strict()
  .superRefine((ex, ctx) => {
    const muscles = ex.muscles.map((m) => m.muscle);
    if (new Set(muscles).size !== muscles.length) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'músculo repetido', path: ['muscles'] });
    }
    if (!ex.muscles.some((m) => m.role === 'primary')) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'falta músculo primario', path: ['muscles'] });
    }
    for (const m of ex.muscles) {
      if (m.role === 'primary' && m.fraction !== 1) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'el primario cuenta 1', path: ['muscles'] });
      }
      if (m.role === 'secondary' && m.fraction >= 1) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'el secundario cuenta < 1', path: ['muscles'] });
      }
    }
    const zones = ex.riskTags.map((r) => r.zone);
    if (new Set(zones).size !== zones.length) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'zona de riesgo repetida', path: ['riskTags'] });
    }
    if (new Set(ex.equipment).size !== ex.equipment.length) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'material repetido', path: ['equipment'] });
    }
    if (ex.media.length > 0 && ex.media.filter((m) => m.isPrimary).length !== 1) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'un medio y solo uno es el principal', path: ['media'] });
    }
    const mediaKeys = ex.media.map(catalogMediaKey);
    if (new Set(mediaKeys).size !== mediaKeys.length) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'medio repetido', path: ['media'] });
    }
    if (ex.equipment.includes('bodyweight') && ex.equipment.length > 1) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "'bodyweight' solo se usa cuando no hay otro material",
        path: ['equipment'],
      });
    }
  });
export type CatalogExercise = z.infer<typeof CatalogExerciseSchema>;

export const CatalogSchema = z.array(CatalogExerciseSchema).superRefine((list, ctx) => {
  const seen = new Set<string>();
  for (const ex of list) {
    if (seen.has(ex.slug)) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: `slug duplicado: ${ex.slug}` });
    }
    seen.add(ex.slug);
  }
});
export type Catalog = z.infer<typeof CatalogSchema>;
