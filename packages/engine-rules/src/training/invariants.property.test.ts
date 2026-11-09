import fc from 'fast-check';
import { engineV2 } from '@pipos/contracts';
import { describe, expect, it } from 'vitest';
import { CATALOG } from '../test-support/fixtures.js';
import { assertPlanInvariants } from '../test-support/invariants.js';
import { generatePlan } from './generate.js';

const SLUGS = CATALOG.map((e) => e.slug);

const profileArb: fc.Arbitrary<engineV2.EngineProfileInput> = fc.record({
  goal: fc.constantFrom(...engineV2.TRAINING_GOALS),
  level: fc.constantFrom(...engineV2.TRAINING_LEVELS),
  daysPerWeek: fc.integer({ min: 2, max: 6 }),
  minutesPerSession: fc.integer({ min: 30, max: 90 }),
  equipment: fc.subarray([...engineV2.EQUIPMENT]),
  limitations: fc.subarray([...engineV2.BODY_ZONES], { maxLength: 3 }),
  priorityMuscles: fc.subarray([...engineV2.MUSCLES], { maxLength: 3 }),
  bannedExerciseIds: fc.subarray(SLUGS, { maxLength: 12 }),
  favouriteExerciseIds: fc.subarray(SLUGS, { maxLength: 3 }),
});

describe('invariantes del plan (fast-check)', () => {
  it('I1-I11 se cumplen para perfiles aleatorios válidos', () => {
    fc.assert(
      fc.property(profileArb, (p) => {
        const r = generatePlan(p, CATALOG);
        if (!r.ok) {
          expect(r.error.code).toBe('NO_EXERCISES');
          return;
        }
        assertPlanInvariants(p, r.plan);
      }),
      { numRuns: 200, seed: 20261109 },
    );
  });

  it('I9 determinismo: misma entrada → mismo plan, sin depender del orden del catálogo', () => {
    fc.assert(
      fc.property(profileArb, fc.integer({ min: 1, max: 1000 }), (p, rot) => {
        const a = generatePlan(p, CATALOG);
        const b = generatePlan(structuredClone(p), CATALOG);
        const k = rot % CATALOG.length;
        const shuffled = [...CATALOG.slice(k), ...CATALOG.slice(0, k)].reverse();
        const c = generatePlan(p, shuffled);
        expect(b).toEqual(a);
        expect(c).toEqual(a);
      }),
      { numRuns: 25, seed: 7 },
    );
  });

  it('I8 con 2+ días y gimnasio completo, todos los grupos se entrenan ≥ 2 veces', () => {
    fc.assert(
      fc.property(
        fc.integer({ min: 2, max: 6 }),
        fc.integer({ min: 45, max: 90 }),
        fc.constantFrom(...engineV2.TRAINING_GOALS),
        (days, minutes, goal) => {
          const r = generatePlan(
            { goal, level: 'intermediate', daysPerWeek: days, minutesPerSession: minutes, equipment: [...engineV2.EQUIPMENT] },
            CATALOG,
          );
          if (!r.ok) throw new Error('plan inválido');
          for (const v of r.plan.weeklyVolume) expect(v.sessions, `${v.group} ${days}d ${minutes}min`).toBeGreaterThanOrEqual(2);
        },
      ),
      { numRuns: 60, seed: 3 },
    );
  });
});
