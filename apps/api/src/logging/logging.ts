import { currentRequestId } from '../common/request-context';

export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const LEVEL_ORDER: Record<LogLevel, number> = { debug: 10, info: 20, warn: 30, error: 40 };

/**
 * Claves que nunca se escriben en un log (PII, credenciales y datos de salud art. 9).
 * La comparación es por nombre de clave, insensible a mayúsculas, a cualquier profundidad.
 */
export const REDACTED_KEYS: ReadonlySet<string> = new Set(
  [
    'email',
    'emailNormalized',
    'password',
    'passwordHash',
    'accessToken',
    'refreshToken',
    'token',
    'tokenHash',
    'authorization',
    'cookie',
    'weightKg',
    'heightCm',
    'limitations',
    'birthYear',
    'sex',
    'inputSnapshot',
    'body',
    'ip',
    'userAgent',
  ].map((k) => k.toLowerCase()),
);

export const REDACTED = '[redacted]';

export function redact(value: unknown, depth = 0): unknown {
  if (depth > 6 || value === null || typeof value !== 'object') return value;
  if (Array.isArray(value)) return value.map((v) => redact(v, depth + 1));
  const out: Record<string, unknown> = {};
  for (const [key, v] of Object.entries(value as Record<string, unknown>)) {
    out[key] = REDACTED_KEYS.has(key.toLowerCase()) ? REDACTED : redact(v, depth + 1);
  }
  return out;
}

function minLevel(): LogLevel {
  const configured = process.env.LOG_LEVEL as LogLevel | undefined;
  return configured && configured in LEVEL_ORDER ? configured : 'info';
}

export type LogSink = (line: string) => void;

let sink: LogSink = (line) => console.log(line);

/** Solo para tests: redirige la salida de los logs. Devuelve la función que restaura la anterior. */
export function setLogSink(next: LogSink): () => void {
  const previous = sink;
  sink = next;
  return () => {
    sink = previous;
  };
}

/**
 * Log estructurado en JSON (una línea por evento) con el id de la petición en curso.
 * Los metadatos pasan por `redact`: nunca salen emails, tokens ni datos de salud.
 */
export function log(level: LogLevel, message: string, meta: Record<string, unknown> = {}): void {
  if (LEVEL_ORDER[level] < LEVEL_ORDER[minLevel()]) return;
  const requestId = currentRequestId();
  const payload = {
    timestamp: new Date().toISOString(),
    level,
    message,
    ...(requestId ? { requestId } : {}),
    ...(redact(meta) as Record<string, unknown>),
  };
  sink(JSON.stringify(payload));
}
