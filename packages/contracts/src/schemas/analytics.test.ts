import { describe, it, expect } from 'vitest';
import { ProgressResponseSchema, VolumeResponseSchema } from './analytics.js';

describe('ProgressResponseSchema', () => {
  it('accepts minimal valid response', () => {
    expect(
      ProgressResponseSchema.safeParse({
        exercises: [],
        adherenceScore: null,
        fatigueDetected: false,
      }).success,
    ).toBe(true);
  });
  it('accepts full progress', () => {
    expect(
      ProgressResponseSchema.safeParse({
        exercises: [
          {
            exerciseId: 'ex-1',
            estimated1RM: 100,
            volumeLastWeek: 5000,
            volumeTrend: 'up',
            fatigueScore: 0,
            lastUpdated: '2025-01-01T00:00:00.000Z',
          },
        ],
        adherenceScore: 0.85,
        fatigueDetected: false,
      }).success,
    ).toBe(true);
  });
});

describe('VolumeResponseSchema', () => {
  it('accepts empty volume', () => {
    expect(
      VolumeResponseSchema.safeParse({
        byExercise: [],
        byMuscle: [],
      }).success,
    ).toBe(true);
  });
});
