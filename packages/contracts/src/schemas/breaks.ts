import { z } from 'zod';
import { CalendarDateSchema, DateTimeSchema, IdSchema } from './common.js';

/** Duración máxima de una pausa planificada, ambos extremos incluidos (PROGRAMACION.md §16.18). */
export const TRAINING_BREAK_MAX_DAYS = 60;

function spanDays(startsOn: string, endsOn: string): number {
  return Math.round((Date.parse(`${endsOn}T00:00:00Z`) - Date.parse(`${startsOn}T00:00:00Z`)) / 86_400_000) + 1;
}

/**
 * POST /me/breaks — pausa planificada (vacaciones…; idea 6, ADR-0013). Idempotente por
 * `clientId` (ADR-0007). Fechas locales del usuario, ambas incluidas, 1-60 días. No se pide ni
 * se guarda el motivo. Excluye esos días de la adherencia y de la ausencia que baja la carga.
 */
export const CreateTrainingBreakRequestSchema = z
  .object({
    clientId: IdSchema,
    startsOn: CalendarDateSchema,
    endsOn: CalendarDateSchema,
  })
  .strict()
  .superRefine((b, ctx) => {
    if (b.endsOn < b.startsOn) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['endsOn'], message: 'endsOn must be on or after startsOn' });
    } else if (spanDays(b.startsOn, b.endsOn) > TRAINING_BREAK_MAX_DAYS) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['endsOn'], message: `A break lasts at most ${TRAINING_BREAK_MAX_DAYS} days` });
    }
  });
export type CreateTrainingBreakRequest = z.infer<typeof CreateTrainingBreakRequestSchema>;

export const TrainingBreakResponseSchema = z
  .object({
    id: IdSchema,
    clientId: IdSchema,
    startsOn: CalendarDateSchema,
    endsOn: CalendarDateSchema,
    createdAt: DateTimeSchema,
  })
  .strict();
export type TrainingBreakResponse = z.infer<typeof TrainingBreakResponseSchema>;

/** GET /me/breaks?from=YYYY-MM-DD — pausas que terminan en `from` o después (todas si se omite). */
export const TrainingBreakListQuerySchema = z.object({ from: CalendarDateSchema.optional() }).strict();
export type TrainingBreakListQuery = z.infer<typeof TrainingBreakListQuerySchema>;

export const TrainingBreakListResponseSchema = z.object({ items: z.array(TrainingBreakResponseSchema).max(200) }).strict();
export type TrainingBreakListResponse = z.infer<typeof TrainingBreakListResponseSchema>;
