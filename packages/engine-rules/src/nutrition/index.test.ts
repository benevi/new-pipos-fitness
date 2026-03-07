import { describe, it, expect } from 'vitest';
import { getNutritionEngineVersion } from './index.js';

describe('nutrition engine', () => {
  it('returns version string', () => {
    expect(getNutritionEngineVersion()).toBe('0.0.1');
  });
});
