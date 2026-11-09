import { describe, expect, it } from 'vitest';
import { toRecord } from './postgres-throttler.storage';

describe('toRecord (almacén Postgres del throttler)', () => {
  it('sin bloqueo: segundos hasta caducar redondeados hacia arriba', () => {
    expect(toRecord({ hits: 3, expires_in_ms: 1_200, blocked_for_ms: null })).toEqual({
      totalHits: 3,
      timeToExpire: 2,
      isBlocked: false,
      timeToBlockExpire: 0,
    });
  });

  it('bloqueado: isBlocked y segundos de bloqueo restantes', () => {
    expect(toRecord({ hits: 6, expires_in_ms: 30_000, blocked_for_ms: 59_001 })).toEqual({
      totalHits: 6,
      timeToExpire: 30,
      isBlocked: true,
      timeToBlockExpire: 60,
    });
  });

  it('un bloqueo ya terminado no cuenta y nunca hay tiempos negativos', () => {
    expect(toRecord({ hits: 1, expires_in_ms: -5, blocked_for_ms: -10 })).toEqual({
      totalHits: 1,
      timeToExpire: 0,
      isBlocked: false,
      timeToBlockExpire: 0,
    });
  });
});
