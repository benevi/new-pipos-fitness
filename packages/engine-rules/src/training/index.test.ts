import { describe, it, expect } from 'vitest';
import { getTrainingEngineVersion } from './index.js';

describe('training engine', () => {
  it('returns version string', () => {
    expect(getTrainingEngineVersion()).toBe('0.0.1');
  });
});
