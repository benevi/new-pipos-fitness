import { randomBytes } from 'crypto';

/**
 * Entorno propio de los e2e. No existe ningún secreto por defecto en el código:
 * cada ejecución genera su propio JWT_ACCESS_SECRET aleatorio.
 * El rate limiting se desactiva salvo en la suite que lo prueba explícitamente.
 */
process.env.NODE_ENV = 'test';
process.env.JWT_ACCESS_SECRET = randomBytes(48).toString('base64');
process.env.JWT_ACCESS_EXPIRES_IN = '900';
process.env.REFRESH_TOKEN_TTL_DAYS = '30';
process.env.CORS_ORIGINS = 'https://app.pipos.test';
process.env.THROTTLE_ENABLED = 'false';
process.env.LOG_LEVEL = 'error';
delete process.env.SENTRY_DSN;
