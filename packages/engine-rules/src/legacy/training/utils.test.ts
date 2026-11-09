import { describe, it, expect } from 'vitest';
import { sortPlanExercises, stableSortByExerciseId } from './utils.js';

describe('sortPlanExercises', () => {
  it('sorts by exerciseId lexicographically', () => {
    const exercises = [
      { exerciseId: 'e3', sets: 3, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 },
      { exerciseId: 'e1', sets: 3, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 },
      { exerciseId: 'e2', sets: 3, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 },
    ];
    const sorted = sortPlanExercises(exercises);
    expect(sorted.map((e) => e.exerciseId)).toEqual(['e1', 'e2', 'e3']);
  });
});

describe('stableSortByExerciseId', () => {
  it('sorts by exerciseId', () => {
    const items = [{ exerciseId: 'b' }, { exerciseId: 'a' }];
    expect(stableSortByExerciseId(items).map((x) => x.exerciseId)).toEqual(['a', 'b']);
  });
});
