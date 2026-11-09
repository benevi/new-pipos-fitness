import { z } from 'zod';
import {
  ConsentActionSchema,
  ConsentPurposeSchema,
  LocaleSchema,
  MuscleSchema,
  PlanStatusSchema,
  RoleSchema,
} from '../enums/index.js';
import { CalendarDateSchema, DateTimeSchema, IdSchema } from './common.js';
import { PlanVersionResponseSchema } from './plans.js';
import { ProfileResponseSchema } from './profile.js';
import { WorkoutResponseSchema } from './workouts.js';
import { TEXT_LIMITS } from './limits.js';
import { ExerciseNoteResponseSchema } from './notes.js';

export const MeResponseSchema = z
  .object({
    id: IdSchema,
    email: z.string(),
    role: RoleSchema,
    locale: LocaleSchema,
    createdAt: DateTimeSchema,
  })
  .strict();
export type MeResponse = z.infer<typeof MeResponseSchema>;

/** DELETE /me exige reautenticación con la contraseña (docs/MODELO_DATOS.md §5.4). */
export const DeleteAccountRequestSchema = z
  .object({ password: z.string().min(1).max(TEXT_LIMITS.LOGIN_PASSWORD_MAX_CHARS) })
  .strict();
export type DeleteAccountRequest = z.infer<typeof DeleteAccountRequestSchema>;

/**
 * GET /me/export (RGPD art. 15 y 20): todos los datos del usuario en JSON. Excluye
 * passwordHash y los hashes de refresh tokens. Los ejercicios se identifican por id y slug.
 */
export const AccountExportSchema = z
  .object({
    formatVersion: z.literal(1),
    exportedAt: DateTimeSchema,
    user: MeResponseSchema,
    profile: ProfileResponseSchema.nullable(),
    consentEvents: z.array(
      z
        .object({
          purpose: ConsentPurposeSchema,
          action: ConsentActionSchema,
          policyVersion: z.string(),
          textHash: z.string(),
          locale: LocaleSchema,
          occurredAt: DateTimeSchema,
        })
        .strict(),
    ),
    plans: z.array(
      z
        .object({
          id: IdSchema,
          status: PlanStatusSchema,
          createdAt: DateTimeSchema,
          versions: z.array(
            PlanVersionResponseSchema.extend({ inputSnapshot: z.record(z.unknown()) }).strict(),
          ),
        })
        .strict(),
    ),
    workouts: z.array(WorkoutResponseSchema),
    // ── Datos añadidos en ADR-0013. El servidor siempre los envía; el `default` solo mantiene
    //    válidas las exportaciones y fixtures anteriores.
    /** Notas fijas por ejercicio (texto libre del usuario). */
    exerciseNotes: z.array(ExerciseNoteResponseSchema).default([]),
    analytics: z
      .object({
        e1rm: z.array(
          z
            .object({
              exerciseId: IdSchema,
              slug: z.string(),
              workoutId: IdSchema,
              performedOn: CalendarDateSchema,
              e1rmKg: z.number(),
              formulaVersion: z.string(),
            })
            .strict(),
        ),
        weeklyMuscleVolume: z.array(
          z
            .object({
              weekStart: CalendarDateSchema,
              muscle: MuscleSchema,
              effectiveSets: z.number(),
              tonnageKg: z.number(),
            })
            .strict(),
        ),
        weeklyAdherence: z.array(
          z
            .object({
              weekStart: CalendarDateSchema,
              plannedSessions: z.number().int(),
              completedSessions: z.number().int(),
              plannedSets: z.number().int(),
              completedSets: z.number().int(),
            })
            .strict(),
        ),
      })
      .strict(),
  })
  .strict();
export type AccountExport = z.infer<typeof AccountExportSchema>;
