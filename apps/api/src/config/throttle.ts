/**
 * Límites de rate limiting (ventana de 60 s, por IP de cliente).
 * La IP sale de `req.ip` (con `TRUST_PROXY_HOPS` saltos de proxy de confianza) y los contadores
 * van en Postgres (`THROTTLE_STORE=postgres`, compartidos entre réplicas) o en memoria por proceso.
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
