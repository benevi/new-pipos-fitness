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
    muscles: z.array(CatalogMuscleSchema).min(1),
    riskTags: z.array(CatalogRiskTagSchema),
    substitutionGroup: z
      .string()
      .min(2)
      .max(64)
      .regex(/^[a-z0-9_]+$/),
    cuesEs: z.array(z.string().min(3).max(120)).min(2).max(3),
    media: z.null(),
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
