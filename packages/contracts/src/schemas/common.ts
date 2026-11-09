import { z } from 'zod';
import { SLUG_REGEX } from '../engine-v2/catalog.js';

/** Fecha de calendario ISO (YYYY-MM-DD), sin hora ni zona. */
export const CalendarDateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Expected a date YYYY-MM-DD')
  // Ida y vuelta: rechaza también fechas que Date.parse «corrige» (p. ej. 2026-11-31).
  .refine((v) => {
    const ms = Date.parse(`${v}T00:00:00Z`);
    return !Number.isNaN(ms) && new Date(ms).toISOString().slice(0, 10) === v;
  }, 'Invalid date');

/** Instante ISO 8601 con zona (lo que emite `Date.prototype.toISOString`). */
export const DateTimeSchema = z.string().datetime({ offset: true });

export const IdSchema = z.string().uuid();

export const ExerciseSlugSchema = z.string().min(2).max(96).regex(SLUG_REGEX, 'Invalid exercise slug');

/** Paginación por página (1-based). `pageSize` acotado para que ninguna lectura sea ilimitada. */
export const PaginationQuerySchema = z
  .object({
    page: z.coerce.number().int().min(1).max(10_000).default(1),
    pageSize: z.coerce.number().int().min(1).max(100).default(20),
  })
  .strict();
export type PaginationQuery = z.infer<typeof PaginationQuerySchema>;

export function paginatedSchema<T extends z.ZodTypeAny>(item: T) {
  return z
    .object({
      items: z.array(item),
      page: z.number().int().min(1),
      pageSize: z.number().int().min(1),
      total: z.number().int().min(0),
    })
    .strict();
}

export const FieldIssueSchema = z.object({ path: z.string(), message: z.string() }).strict();
export type FieldIssue = z.infer<typeof FieldIssueSchema>;

/**
 * Códigos de error estables (el móvil decide por `code`, nunca por `message`).
 */
export const ERROR_CODES = [
  'VALIDATION_FAILED',
  'UNAUTHORIZED',
  'FORBIDDEN',
  'NOT_FOUND',
  'CONFLICT',
  'RATE_LIMITED',
  'INTERNAL',
  'AUTH_INVALID_CREDENTIALS',
  'AUTH_EMAIL_TAKEN',
  'AUTH_REFRESH_INVALID',
  'AUTH_REFRESH_REUSED',
  'AUTH_REFRESH_RACE',
  'HEALTH_CONSENT_REQUIRED',
  'HEALTH_CONSENT_VERSION_MISMATCH',
  'PROFILE_REQUIRED',
  'PLAN_REQUIRED',
  'PLAN_GENERATION_FAILED',
  'PLAN_VERSION_CONFLICT',
  /** Misma `Idempotency-Key` con otra entrada (issue #11): usa una clave nueva. */
  'IDEMPOTENCY_KEY_REUSED',
  'UNKNOWN_EXERCISE',
  'WORKOUT_IN_PROGRESS',
  /** POST /workouts con una sesión de una versión del plan que ya no es la vigente (issue #10). */
  'PLAN_SESSION_OUTDATED',
  'WORKOUT_FINISHED',
  'CLIENT_ID_CONFLICT',
  'NUTRITION_INPUT_INCOMPLETE',
] as const;
export const ErrorCodeSchema = z.enum(ERROR_CODES);
export type ErrorCode = z.infer<typeof ErrorCodeSchema>;

export const ErrorResponseSchema = z
  .object({
    statusCode: z.number().int(),
    code: z.string(),
    message: z.string(),
    issues: z.array(FieldIssueSchema).optional(),
    requestId: z.string().optional(),
  })
  .strict();
export type ErrorResponse = z.infer<typeof ErrorResponseSchema>;

/**
 * Cabecera opcional `Idempotency-Key` (issue #11): identificador único por intento lógico que
 * genera el cliente (se recomienda un UUID v4) y reenvía igual en cada reintento. Las cabeceras
 * HTTP no distinguen mayúsculas; Node las entrega en minúsculas.
 */
export const IdempotencyKeyHeadersSchema = z.object({
  'idempotency-key': z
    .string()
    .regex(/^[\x21-\x7E]{1,128}$/, 'Idempotency-Key must be 1-128 visible ASCII characters')
    .optional(),
});
export type IdempotencyKeyHeaders = z.infer<typeof IdempotencyKeyHeadersSchema>;

export const OkResponseSchema = z.object({ ok: z.literal(true) }).strict();
export type OkResponse = z.infer<typeof OkResponseSchema>;
