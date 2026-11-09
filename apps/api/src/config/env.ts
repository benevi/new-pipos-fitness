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
    .string({
      error: (issue) => (issue.input === undefined ? 'JWT_ACCESS_SECRET is required' : undefined),
    })
    .min(32, 'JWT_ACCESS_SECRET must be at least 32 characters'),
  /** Vida del access token en segundos. */
  JWT_ACCESS_EXPIRES_IN: z.coerce.number().int().min(60).max(86_400).default(900),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().min(1).max(365).default(30),
  /**
   * Ventana (s) en la que reenviar un refresh token recién rotado se trata como carrera benigna
   * (dos peticiones a la vez del mismo cliente): 401 AUTH_REFRESH_RACE sin revocar la familia.
   * No recupera una respuesta perdida (solo se guarda el hash del token nuevo): ver SECURITY.md.
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
    .pipe(z.array(z.url('CORS_ORIGINS entries must be absolute URLs'))),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
  SENTRY_DSN: z
    .string()
    .optional()
    .transform((v) => (v && v.trim().length > 0 ? v.trim() : undefined))
    .pipe(z.url().optional()),
  /** Rate limiting global. Sólo se desactiva explícitamente (p. ej. en e2e). */
  THROTTLE_ENABLED: booleanFromEnv(true),
  /**
   * Saltos de proxy de confianza delante de la API (`app.set('trust proxy', n)`). Con 0 (por
   * defecto) se ignora `X-Forwarded-For` y la IP es la del socket. Detrás del balanceador del
   * hosting, el número de proxies que añaden su salto (normalmente 1). Un valor mayor del real
   * permite a un cliente falsificar su IP con la cabecera y saltarse el rate limiting.
   */
  TRUST_PROXY_HOPS: z.coerce.number().int().min(0).max(10).default(0),
  /**
   * Almacén de contadores del rate limiting: `postgres` (compartido entre réplicas) o `memory`
   * (por proceso). Sin definir: `postgres` en producción y `memory` en el resto.
   */
  THROTTLE_STORE: z.enum(['memory', 'postgres']).optional(),
});

export type Env = Omit<z.infer<typeof EnvSchema>, 'THROTTLE_STORE'> & { THROTTLE_STORE: 'memory' | 'postgres' };

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
      result.error.issues.map((i) => `${i.path.map(String).join('.') || '(root)'}: ${i.message}`),
    );
  }
  if (result.data.NODE_ENV === 'production' && !result.data.THROTTLE_ENABLED) {
    throw new InvalidEnvError(['THROTTLE_ENABLED: cannot be disabled in production']);
  }
  const data = result.data;
  return { ...data, THROTTLE_STORE: data.THROTTLE_STORE ?? (data.NODE_ENV === 'production' ? 'postgres' : 'memory') };
}
