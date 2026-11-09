import { z } from 'zod';
import { MuscleSchema, VolumeGroupSchema } from '../enums/index.js';
import { CalendarDateSchema, IdSchema } from './common.js';

/** Lecturas de analítica: solo leen tablas resumen calculadas al escribir (ADR-0008). */
export const E1rmQuerySchema = z
  .object({
    exerciseId: IdSchema.optional(),
    from: CalendarDateSchema.optional(),
    to: CalendarDateSchema.optional(),
  })
  .strict();
export type E1rmQuery = z.infer<typeof E1rmQuerySchema>;

export const E1rmPointSchema = z
  .object({ date: CalendarDateSchema, e1rmKg: z.number(), workoutId: IdSchema })
  .strict();

export const E1rmSeriesSchema = z
  .object({
    exerciseId: IdSchema,
    slug: z.string(),
    nameEs: z.string(),
    latestE1rmKg: z.number(),
    points: z.array(E1rmPointSchema),
  })
  .strict();

export const E1rmResponseSchema = z
  .object({ formulaVersion: z.string(), series: z.array(E1rmSeriesSchema) })
  .strict();
export type E1rmResponse = z.infer<typeof E1rmResponseSchema>;

export const WeeksQuerySchema = z
  .object({ weeks: z.coerce.number().int().min(1).max(52).default(8) })
  .strict();
export type WeeksQuery = z.infer<typeof WeeksQuerySchema>;

export const VolumeWeekSchema = z
  .object({
    weekStart: CalendarDateSchema,
    muscles: z.array(
      z.object({ muscle: MuscleSchema, effectiveSets: z.number(), tonnageKg: z.number() }).strict(),
    ),
    groups: z.array(
      z
        .object({
          group: VolumeGroupSchema,
          effectiveSets: z.number(),
          /** Rango objetivo semanal del plan vigente (null si no hay plan). */
          targetMin: z.number().nullable(),
          targetMax: z.number().nullable(),
          status: z.enum(['below', 'within', 'above', 'no_target']),
        })
        .strict(),
    ),
  })
  .strict();

export const VolumeResponseSchema = z
  .object({ timezone: z.string(), weeks: z.array(VolumeWeekSchema) })
  .strict();
export type VolumeResponse = z.infer<typeof VolumeResponseSchema>;

export const AdherenceWeekSchema = z
  .object({
    weekStart: CalendarDateSchema,
    plannedSessions: z.number().int(),
    completedSessions: z.number().int(),
    plannedSets: z.number().int(),
    completedSets: z.number().int(),
    /** completedSessions / plannedSessions (0 si no hay nada planificado). */
    sessionRatio: z.number().min(0),
  })
  .strict();

export const AdherenceResponseSchema = z
  .object({
    timezone: z.string(),
    weeks: z.array(AdherenceWeekSchema),
    totals: z
      .object({ plannedSessions: z.number().int(), completedSessions: z.number().int(), sessionRatio: z.number() })
      .strict(),
  })
  .strict();
export type AdherenceResponse = z.infer<typeof AdherenceResponseSchema>;
