import { z } from 'zod';

/** GET /health: liveness (no toca dependencias). */
export const HealthResponseSchema = z.object({ status: z.literal('ok') }).strict();
export type HealthResponse = z.infer<typeof HealthResponseSchema>;

/** GET /health/ready: readiness (comprueba Postgres). 503 si alguna comprobación falla. */
export const ReadinessResponseSchema = z
  .object({
    status: z.enum(['ok', 'error']),
    checks: z.object({ database: z.enum(['ok', 'error']) }).strict(),
  })
  .strict();
export type ReadinessResponse = z.infer<typeof ReadinessResponseSchema>;
