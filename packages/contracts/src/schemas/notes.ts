import { z } from 'zod';
import { DateTimeSchema, IdSchema } from './common.js';

/** Longitud máxima de la nota fija por ejercicio (idea 2, ADR-0013). */
export const EXERCISE_NOTE_MAX = 280;

/**
 * PUT /exercises/:id/note — nota fija del usuario para un ejercicio (ajustes de máquina, agarre,
 * altura del asiento…). Idempotente; gana la última escritura por `clientUpdatedAt` (ADR-0007):
 * si llega una edición más antigua que la guardada, responde 200 con la nota vigente.
 * Texto libre: el usuario podría escribir datos de salud; se exporta, se borra con la cuenta y
 * nunca se registra en logs (docs/SECURITY.md).
 */
export const ExerciseNoteRequestSchema = z
  .object({
    text: z.string().trim().min(1).max(EXERCISE_NOTE_MAX),
    clientUpdatedAt: DateTimeSchema,
  })
  .strict();
export type ExerciseNoteRequest = z.infer<typeof ExerciseNoteRequestSchema>;

export const ExerciseNoteResponseSchema = z
  .object({
    exerciseId: IdSchema,
    slug: z.string(),
    text: z.string(),
    clientUpdatedAt: DateTimeSchema,
    updatedAt: DateTimeSchema,
  })
  .strict();
export type ExerciseNoteResponse = z.infer<typeof ExerciseNoteResponseSchema>;

/** GET /me/exercise-notes: todas las notas del usuario (como mucho una por ejercicio del catálogo). */
export const ExerciseNoteListResponseSchema = z.object({ items: z.array(ExerciseNoteResponseSchema) }).strict();
export type ExerciseNoteListResponse = z.infer<typeof ExerciseNoteListResponseSchema>;
