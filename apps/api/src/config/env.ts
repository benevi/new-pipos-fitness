import { z } from 'zod';

/**
 * Configuración de entorno de la API, validada con Zod al arrancar.
 * No hay valores por defecto para secretos: si falta algo obligatorio, la API no arranca.
 */
const booleanFromEnv = (defaultValue: boolean) =>
  z
    .enum(['true', 'false', '1', '0'])
    .optional()
    .transform((v) => (v === undefined ? defaultValue : v === 'true' || v === '1'));

export const EnvSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  DATABASE_URL: z
    .string()
    .min(1, 'DATABASE_URL is required')
    .refine((v) => /^postgres(ql)?:\/\//.test(v), 'DATABASE_URL must be a postgres:// URL'),
  JWT_ACCESS_SECRET: z
    .string({ required_error: 'JWT_ACCESS_SECRET is required' })
    .min(32, 'JWT_ACCESS_SECRET must be at least 32 characters'),
  /** Vida del access token en segundos. */
  JWT_ACCESS_EXPIRES_IN: z.coerce.number().int().min(60).max(86_400).default(900),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().min(1).max(365).default(30),
  /**
   * Ventana (s) en la que reenviar un refresh token recién rotado se trata como carrera benigna
   * (respuesta perdida, dos peticiones a la vez): 401 AUTH_REFRESH_RACE sin revocar la familia.
   * Fuera de la ventana, la reutilización revoca todas las sesiones del usuario.
   */
  REFRESH_REUSE_GRACE_SECONDS: z.coerce.number().int().min(0).max(300).default(10),
  /** Lista separada por comas de orígenes permitidos para CORS. Vacío = ningún origen de navegador. */
  CORS_ORIGINS: z
    .string()
    .default('')
    .transform((v) =>
      v
        .split(',')
        .map((o) => o.trim())
        .filter((o) => o.length > 0),
    )
    .pipe(z.array(z.string().url('CORS_ORIGINS entries must be absolute URLs'))),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
  SENTRY_DSN: z
    .string()
    .optional()
    .transform((v) => (v && v.trim().length > 0 ? v.trim() : undefined))
    .pipe(z.string().url().optional()),
  /** Rate limiting global. Sólo se desactiva explícitamente (p. ej. en e2e). */
  THROTTLE_ENABLED: booleanFromEnv(true),
});

export type Env = z.infer<typeof EnvSchema>;

export const APP_ENV = Symbol('APP_ENV');

export class InvalidEnvError extends Error {
  constructor(public readonly issues: string[]) {
    super(`Invalid environment configuration:\n  - ${issues.join('\n  - ')}`);
    this.name = 'InvalidEnvError';
  }
}

/** Parsea y valida el entorno. Nunca incluye valores en el mensaje de error (pueden ser secretos). */
export function parseEnv(source: NodeJS.ProcessEnv = process.env): Env {
  const result = EnvSchema.safeParse(source);
  if (!result.success) {
    throw new InvalidEnvError(
      result.error.issues.map((i) => `${i.path.join('.') || '(root)'}: ${i.message}`),
    );
  }
  if (result.data.NODE_ENV === 'production' && !result.data.THROTTLE_ENABLED) {
    throw new InvalidEnvError(['THROTTLE_ENABLED: cannot be disabled in production']);
  }
  return result.data;
}
