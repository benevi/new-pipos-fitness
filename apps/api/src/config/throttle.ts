/**
 * Límites de rate limiting (ventana de 60 s, por IP de cliente).
 * El almacenamiento es en memoria por instancia: con varias réplicas hará falta un almacén
 * compartido (pendiente; v1 es un único proceso, ADR-0002).
 */
const MINUTE_MS = 60_000;

export const THROTTLE_LIMITS = {
  /** Límite global por defecto para cualquier ruta. */
  DEFAULT: { ttl: MINUTE_MS, limit: 100 },
  /** Login y registro: frena fuerza bruta y enumeración. */
  AUTH_CREDENTIALS: { ttl: MINUTE_MS, limit: 5 },
  /** Rotación de refresh tokens. */
  AUTH_REFRESH: { ttl: MINUTE_MS, limit: 10 },
  /** Generación de planes (CPU del motor). */
  PLAN_GENERATION: { ttl: MINUTE_MS, limit: 10 },
  /** Exportar o borrar la cuenta. */
  ACCOUNT_SENSITIVE: { ttl: MINUTE_MS, limit: 5 },
  /** /health y /health/ready: sondas del orquestador, no un vector de carga sobre la BD. */
  HEALTH: { ttl: MINUTE_MS, limit: 60 },
} as const;
