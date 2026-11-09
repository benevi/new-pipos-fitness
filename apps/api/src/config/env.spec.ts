import { describe, it, expect } from 'vitest';
import { InvalidEnvError, parseEnv } from './env';

const SECRET = 'x'.repeat(32);
const base = {
  DATABASE_URL: 'postgresql://u:p@localhost:5432/db',
  JWT_ACCESS_SECRET: SECRET,
};

describe('parseEnv', () => {
  it('aplica valores por defecto no secretos', () => {
    const env = parseEnv({ ...base });
    expect(env).toMatchObject({
      NODE_ENV: 'development',
      PORT: 3000,
      JWT_ACCESS_EXPIRES_IN: 900,
      REFRESH_TOKEN_TTL_DAYS: 30,
      CORS_ORIGINS: [],
      LOG_LEVEL: 'info',
      THROTTLE_ENABLED: true,
    });
    expect(env.SENTRY_DSN).toBeUndefined();
  });

  it('falla si falta JWT_ACCESS_SECRET (no hay secreto por defecto)', () => {
    expect(() => parseEnv({ DATABASE_URL: base.DATABASE_URL })).toThrow(InvalidEnvError);
    expect(() => parseEnv({ DATABASE_URL: base.DATABASE_URL })).toThrow(/JWT_ACCESS_SECRET/);
  });

  it('falla si JWT_ACCESS_SECRET tiene menos de 32 caracteres', () => {
    expect(() => parseEnv({ ...base, JWT_ACCESS_SECRET: 'short' })).toThrow(/at least 32/);
  });

  it('no filtra el valor del secreto en el mensaje de error', () => {
    try {
      parseEnv({ ...base, JWT_ACCESS_SECRET: 'super-secret-but-short' });
      expect.unreachable();
    } catch (e) {
      expect((e as Error).message).not.toContain('super-secret-but-short');
    }
  });

  it('falla si falta DATABASE_URL o no es postgres', () => {
    expect(() => parseEnv({ JWT_ACCESS_SECRET: SECRET })).toThrow(/DATABASE_URL/);
    expect(() => parseEnv({ ...base, DATABASE_URL: 'mysql://x' })).toThrow(/postgres/);
  });

  it('parsea CORS_ORIGINS como lista y valida URLs', () => {
    expect(
      parseEnv({ ...base, CORS_ORIGINS: 'https://a.example.com, https://b.example.com' }).CORS_ORIGINS,
    ).toEqual(['https://a.example.com', 'https://b.example.com']);
    expect(() => parseEnv({ ...base, CORS_ORIGINS: '*' })).toThrow(/CORS_ORIGINS/);
  });

  it('coacciona números y booleanos', () => {
    const env = parseEnv({
      ...base,
      PORT: '8080',
      JWT_ACCESS_EXPIRES_IN: '600',
      REFRESH_TOKEN_TTL_DAYS: '7',
      THROTTLE_ENABLED: 'false',
    });
    expect(env.PORT).toBe(8080);
    expect(env.JWT_ACCESS_EXPIRES_IN).toBe(600);
    expect(env.REFRESH_TOKEN_TTL_DAYS).toBe(7);
    expect(env.THROTTLE_ENABLED).toBe(false);
  });

  it('SENTRY_DSN vacío se trata como ausente; inválido falla', () => {
    expect(parseEnv({ ...base, SENTRY_DSN: '' }).SENTRY_DSN).toBeUndefined();
    expect(() => parseEnv({ ...base, SENTRY_DSN: 'nope' })).toThrow(/SENTRY_DSN/);
  });

  it('no permite desactivar el rate limiting en producción', () => {
    expect(() =>
      parseEnv({ ...base, NODE_ENV: 'production', THROTTLE_ENABLED: 'false' }),
    ).toThrow(/THROTTLE_ENABLED/);
  });
});
