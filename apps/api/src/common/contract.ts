import { applyDecorators, HttpCode, SetMetadata } from '@nestjs/common';
import type { ZodTypeAny } from 'zod';

export const CONTRACT_KEY = 'pipos:contract';

/**
 * Contrato de un endpoint: TODA entrada (params, query, body) y la salida se validan con
 * esquemas Zod de @pipos/contracts (ContractInterceptor). Es también la fuente del
 * documento OpenAPI (scripts/openapi.ts): no hay decoradores de Swagger a mano.
 */
export interface ContractSpec {
  summary: string;
  tag: string;
  /** Requiere access token (por defecto true). */
  auth?: boolean;
  params?: ZodTypeAny;
  query?: ZodTypeAny;
  /** Cabeceras propias del endpoint (objeto Zod con nombres en minúsculas; las demás se ignoran). */
  headers?: ZodTypeAny;
  body?: ZodTypeAny;
  /** Esquema de la respuesta con éxito; null = sin cuerpo. */
  response: ZodTypeAny | null;
  /** Estado HTTP de éxito (por defecto 200; 201 en creaciones). */
  status?: number;
  /** Otros estados de éxito posibles (p. ej. 200 al reenviar un POST idempotente). */
  alternateStatuses?: number[];
  /** Estados de error documentados (además de 400/401/429/500 comunes). */
  errors?: number[];
  description?: string;
}

export function Contract(spec: ContractSpec): MethodDecorator {
  return applyDecorators(SetMetadata(CONTRACT_KEY, spec), HttpCode(spec.status ?? 200));
}
