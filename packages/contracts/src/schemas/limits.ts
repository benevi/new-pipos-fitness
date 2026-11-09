import { z } from 'zod';

/**
 * Límites de tamaño para entradas de texto libre. Evitan payloads abusivos
 * (DoS por memoria/CPU, almacenamiento) y documentan el contrato con el cliente.
 */
export const TEXT_LIMITS = {
  EMAIL: 254,
  /** bcrypt sólo usa los primeros 72 bytes: se rechaza cualquier contraseña más larga. */
  PASSWORD_MIN_BYTES: 8,
  PASSWORD_MAX_BYTES: 72,
  /** Login no impone el límite de bytes (usuarios antiguos), pero sí un tope razonable. */
  LOGIN_PASSWORD_MAX_CHARS: 256,
  REFRESH_TOKEN: 256,
  NOTES: 1000,
  CUSTOM_TEXT: 200,
  SEARCH: 100,
  NAME: 120,
  SLUG: 120,
  DESCRIPTION: 2000,
  CATALOG_ID: 64,
  MOVEMENT_PATTERN: 50,
  YOUTUBE_VIDEO_ID: 32,
  CHANNEL_NAME: 120,
} as const;

export function utf8ByteLength(value: string): number {
  return new TextEncoder().encode(value).length;
}

/** Identificador de catálogo con forma de slug (muscle-chest, eq-barbell, food-...). */
export const CatalogIdSchema = z
  .string()
  .min(1)
  .max(TEXT_LIMITS.CATALOG_ID)
  .regex(/^[A-Za-z0-9_-]+$/, 'Invalid catalog id');

export const UuidSchema = z.uuid();
