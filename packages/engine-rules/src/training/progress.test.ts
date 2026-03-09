import { describe, it, expect } from 'vitest';
import {
  computeE1RM,
  getBestE1RMPerExercise,
  computeVolumePerExercise,
  computeAdherence,
  detectFatigue,
  fatigueScorePerExercise,
  volumeTrend,
} from './progress.js';

describe('computeE1RM', () => {
  it('returns weight * (1 + reps/30)', () => {
    expect(computeE1RM(100, 0)).toBeNull();
    expect(computeE1RM(0, 10)).toBeNull();
    expect(computeE1RM(null, 10)).toBeNull();
    expect(computeE1RM(100, null)).toBeNull();
    expect(computeE1RM(60, 10)).toBe(60 * (1 + 10 / 30));
    expect(computeE1RM(100, 30)).toBe(100 * 2);
  });
});

describe('getBestE1RMPerExercise', () => {
  it('returns best e1RM per exercise', () => {
    const sets = new Map<string, Array<{ weightKg: number | null; reps: number | null }>>([
      ['ex1', [{ weightKg: 80, reps: 5 }, { weightKg: 70, reps: 12 }]],
      ['ex2', [{ weightKg: 60, reps: 8 }]],
    ]);
    const out = getBestE1RMPerExercise(sets);
    expect(out.get('ex1')).toBeCloseTo(70 * (1 + 12 / 30));
    expect(out.get('ex2')).toBe(60 * (1 + 8 / 30));
  });
});

describe('computeVolumePerExercise', () => {
  it('sums weightKg * reps for completed sets', () => {
    const sets = new Map([
      ['ex1', [
        { weightKg: 80, reps: 10, completed: true },
        { weightKg: 80, reps: 8, completed: false },
      ]],
    ]);
    const out = computeVolumePerExercise(sets);
    expect(out.get('ex1')).toBe(80 * 10);
  });
});

describe('computeAdherence', () => {
  it('returns completed/planned clamped to [0,1]', () => {
    expect(computeAdherence(0, 0)).toBeNull();
    expect(computeAdherence(10, 10)).toBe(1);
    expect(computeAdherence(5, 10)).toBe(0.5);
    expect(computeAdherence(15, 10)).toBe(1);
    expect(computeAdherence(0, 10)).toBe(0);
  });
});

describe('detectFatigue', () => {
  it('returns true when rir <= 0', () => {
    expect(detectFatigue([{ reps: 10, rir: 0, completed: true }])).toBe(true);
    expect(detectFatigue([{ reps: 10, rir: -1, completed: true }])).toBe(true);
  });
  it('returns true when reps drop > 20%', () => {
    expect(detectFatigue([
      { reps: 10, rir: 2, completed: true },
      { reps: 7, rir: 2, completed: true },
    ])).toBe(true);
    expect(detectFatigue([
      { reps: 10, rir: 2, completed: true },
      { reps: 8, rir: 2, completed: true },
    ])).toBe(false);
  });
  it('returns false for single set or no drop', () => {
    expect(detectFatigue([{ reps: 10, rir: 2, completed: true }])).toBe(false);
  });
});

describe('volumeTrend', () => {
  it('returns up/down/stable', () => {
    expect(volumeTrend(110, 100)).toBe('up');
    expect(volumeTrend(90, 100)).toBe('down');
    expect(volumeTrend(100, 100)).toBe('stable');
    expect(volumeTrend(10, 0)).toBe('up');
  });
});
