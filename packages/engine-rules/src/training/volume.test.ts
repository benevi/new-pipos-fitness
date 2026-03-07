import { describe, it, expect } from 'vitest';
import { computeWeeklySetsByMuscle } from './volume.js';
import { TrainingLocation, MuscleRole } from '@pipos/contracts';

describe('computeWeeklySetsByMuscle', () => {
  it('returns empty map for empty sessions', () => {
    const out = computeWeeklySetsByMuscle(
      { sessions: [] },
      new Map(),
    );
    expect(out.size).toBe(0);
  });

  it('aggregates weighted sets by muscle', () => {
    const catalog = new Map([
      [
        'e1',
        {
          id: 'e1',
          name: 'Squat',
          difficulty: 1,
          movementPattern: 'squat',
          place: TrainingLocation.GYM,
          equipmentIds: [],
          muscles: [
            { muscleId: 'm1', role: MuscleRole.PRIMARY },
            { muscleId: 'm2', role: MuscleRole.SECONDARY },
          ],
        },
      ],
    ]);
    const weekPlan = {
      sessions: [
        {
          sessionIndex: 0,
          name: 'Day 1',
          targetDurationMinutes: 45,
          exercises: [
            { exerciseId: 'e1', sets: 4, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 },
          ],
        },
      ],
    };
    const out = computeWeeklySetsByMuscle(weekPlan, catalog);
    expect(out.get('m1')).toBe(4);
    expect(out.get('m2')).toBe(2);
  });
});
