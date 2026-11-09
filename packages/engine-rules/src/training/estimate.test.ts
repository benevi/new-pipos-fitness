import { describe, expect, it } from 'vitest';
import { CATALOG, profile } from '../test-support/fixtures.js';
import { estimateSessionMinutes } from './estimate.js';
import { generatePlan } from './generate.js';
import { groupOf } from './model.js';
import { PROGRAMMING } from '../config/programming.js';

const bySlug = new Map(CATALOG.map((e) => [e.slug, e]));

describe('estimateSessionMinutes', () => {
  it('coincide con la estimación del generador para cada sesión', () => {
    const r = generatePlan(profile({ daysPerWeek: 5 }), CATALOG);
    if (!r.ok) throw new Error('plan');
    for (const s of r.plan.sessions) {
      const est = estimateSessionMinutes(
        s.exercises.map((e) => ({
          sets: e.sets,
          repMin: e.repMin,
          repMax: e.repMax,
          restSeconds: e.restSeconds,
          isUnilateral: bySlug.get(e.exerciseId)!.isUnilateral,
          warmupSets: e.warmupSets.length,
        })),
      );
      expect(est).toBeCloseTo(s.estimatedMinutes, 0);
    }
  });

  it('aplica la fórmula de PROGRAMACION.md §8', () => {
    // 5 min + 3 × (10 × 3,5 + 120) − 120 + 2 × 60 + 60 = 300 + 345 + 180 = 825 s
    const one = estimateSessionMinutes([{ sets: 3, repMin: 8, repMax: 12, restSeconds: 120, isUnilateral: false, warmupSets: 2 }]);
    expect(one).toBe(13.8);
    const uni = estimateSessionMinutes([{ sets: 3, repMin: 8, repMax: 12, restSeconds: 120, isUnilateral: true, warmupSets: 0 }]);
    expect(uni).toBeGreaterThan(estimateSessionMinutes([{ sets: 3, repMin: 8, repMax: 12, restSeconds: 120, isUnilateral: false, warmupSets: 0 }]));
    expect(estimateSessionMinutes([])).toBe(5);
  });

  it('el deltoides anterior y la zona lumbar no tienen grupo de volumen propio', () => {
    expect(groupOf('front_delts', PROGRAMMING)).toBeNull();
    expect(groupOf('lower_back', PROGRAMMING)).toBeNull();
    expect(groupOf('side_delts', PROGRAMMING)).toBe('shoulders');
  });
});
