/**
 * Límites de rate limiting (ventana de 60 s, por IP de cliente).
 * El almacenamiento es en memoria por instancia: con varias réplicas hará falta Redis (pendiente).
 */
const MINUTE_MS = 60_000;

export const THROTTLE_LIMITS = {
  /** Límite global por defecto para cualquier ruta. */
  DEFAULT: { ttl: MINUTE_MS, limit: 100 },
  /** Login y registro: frena fuerza bruta y enumeración. */
  AUTH_CREDENTIALS: { ttl: MINUTE_MS, limit: 5 },
  /** Rotación de refresh tokens. */
  AUTH_REFRESH: { ttl: MINUTE_MS, limit: 10 },
  /** Generación de planes (CPU intensiva). */
  PLAN_GENERATION: { ttl: MINUTE_MS, limit: 10 },
} as const;
