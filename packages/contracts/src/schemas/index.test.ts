import { describe, it, expect } from 'vitest';
import { HealthResponseSchema } from './index.js';

describe('HealthResponseSchema', () => {
  it('accepts valid health response', () => {
    const result = HealthResponseSchema.safeParse({
      status: 'ok',
      timestamp: new Date().toISOString(),
    });
    expect(result.success).toBe(true);
  });

  it('rejects invalid status', () => {
    const result = HealthResponseSchema.safeParse({
      status: 'invalid',
      timestamp: new Date().toISOString(),
    });
    expect(result.success).toBe(false);
  });
});
