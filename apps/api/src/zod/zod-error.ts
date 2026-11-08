import { BadRequestException } from '@nestjs/common';
import type { ZodError, ZodType } from 'zod';

export function formatZodError(error: ZodError): string {
  return error.issues.map((e) => `${e.path.join('.')}: ${e.message}`).join('; ') || 'Validation failed';
}

/**
 * Valida `value` con `schema` y traduce un fallo a 400 directamente (BadRequestException).
 * No depende de `instanceof ZodError` en un filtro: el esquema puede venir de otra copia
 * de zod (p. ej. @pipos/contracts compilado a CJS frente a zod ESM en Vitest).
 */
export function parseOrBadRequest<T>(schema: ZodType<T>, value: unknown): T {
  const result = schema.safeParse(value);
  if (!result.success) {
    throw new BadRequestException({
      statusCode: 400,
      message: formatZodError(result.error),
      error: 'Bad Request',
    });
  }
  return result.data;
}
