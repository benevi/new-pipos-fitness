import { describe, it, expect } from 'vitest';
import { estimateSessionDurationMinutesSimple } from './duration.js';

describe('estimateSessionDurationMinutesSimple', () => {
  it('returns 0 for empty exercises', () => {
    expect(
      estimateSessionDurationMinutesSimple({
        sessionIndex: 0,
        name: 'Day 1',
        targetDurationMinutes: 45,
        exercises: [],
      }),
    ).toBe(0);
  });

  it('increases with more sets and rest', () => {
    const base = {
      sessionIndex: 0,
      name: 'Day 1',
      targetDurationMinutes: 45,
      exercises: [
        { exerciseId: 'e1', sets: 3, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 },
      ],
    };
    const a = estimateSessionDurationMinutesSimple(base);
    const more = {
      ...base,
      exercises: [
        { exerciseId: 'e1', sets: 5, repRangeMin: 8, repRangeMax: 12, restSeconds: 120, rirTarget: 2 },
      ],
    };
    const b = estimateSessionDurationMinutesSimple(more);
    expect(b).toBeGreaterThan(a);
  });
});
