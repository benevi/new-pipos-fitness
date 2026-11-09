import fc from 'fast-check';
import { engineV2 } from '@pipos/contracts';
import { describe, expect, it } from 'vitest';
import { CATALOG } from '../test-support/fixtures.js';
import { exclusionReason } from './filter.js';
import { generatePlan } from './generate.js';
import { substitutes } from './substitutes.js';

const GYM: engineV2.EngineProfileInput = {
  goal: 'hypertrophy',
  level: 'intermediate',
  daysPerWeek: 3,
  minutesPerSession: 60,
  equipment: ['barbell', 'dumbbell', 'bench', 'squat_rack', 'cable', 'machine', 'pull_up_bar'],
};

function plan(profile: engineV2.EngineProfileInput, pins: engineV2.PinnedSubstitutionInput[] = []) {
  const r = generatePlan(profile, CATALOG, { pinnedSubstitutions: pins });
  if (!r.ok) throw new Error(r.error.message);
  return r.plan;
}

/** Un ejercicio del plan y una alternativa válida (la primera de `substitutes`). */
function pickPin(profile: engineV2.EngineProfileInput) {
  const base = plan(profile);
  for (const s of base.sessions) {
    for (const e of s.exercises) {
      const subs = substitutes(e.exerciseId, profile, CATALOG, 3);
      if (subs.ok && subs.substitutes.length > 0) return { base, from: e.exerciseId, to: subs.substitutes[0].exerciseId };
    }
  }
  throw new Error('sin alternativas');
}

describe('cambios fijados (idea 3)', () => {
  it('sin cambios fijados el plan es idéntico (no regresión)', () => {
    const a = generatePlan(GYM, CATALOG);
    const b = generatePlan(GYM, CATALOG, { pinnedSubstitutions: [] });
    expect(b).toEqual(a);
    expect(a.ok && a.plan.pinnedSubstitutions).toEqual([]);
  });

  it('un cambio válido se aplica a todos los huecos del ejercicio original y no altera el plan', () => {
    const { base, from, to } = pickPin(GYM);
    const pinnedPlan = plan(GYM, [{ from, to }]);
    expect(pinnedPlan.sessions).toEqual(base.sessions);
    const slots = base.sessions.flatMap((s) => s.exercises.filter((e) => e.exerciseId === from).map((e) => ({ sessionOrder: s.order, exerciseOrder: e.order })));
    expect(pinnedPlan.pinnedSubstitutions).toEqual(slots.map((sl) => ({ ...sl, from, to })));
    expect(pinnedPlan.warnings.some((w) => w.code === 'PINNED_SUBSTITUTION_DROPPED')).toBe(false);
  });

  it('si falta el material del elegido, se descarta con aviso', () => {
    const { from, to } = pickPin(GYM);
    const toEx = CATALOG.find((e) => e.slug === to)!;
    const missing = toEx.equipment.find((e) => e !== 'bodyweight');
    if (!missing) return;
    const profile = { ...GYM, equipment: GYM.equipment.filter((e) => e !== missing) };
    const p = plan(profile, [{ from, to }]);
    expect(p.pinnedSubstitutions.some((x) => x.to === to)).toBe(false);
    const w = p.warnings.find((x) => x.code === 'PINNED_SUBSTITUTION_DROPPED');
    expect(w?.data?.to).toBe(to);
  });

  it('un ejercicio que no es alternativa (otro patrón y grupo) se descarta', () => {
    const { from } = pickPin(GYM);
    const fromEx = CATALOG.find((e) => e.slug === from)!;
    const other = CATALOG.find(
      (e) => e.movementPattern !== fromEx.movementPattern && e.substitutionGroup !== fromEx.substitutionGroup && !exclusionReason(e, { ...GYM, limitations: [], bannedExerciseIds: [] }),
    )!;
    const p = plan(GYM, [{ from, to: other.slug }]);
    expect(p.pinnedSubstitutions).toEqual([]);
    expect(p.warnings.find((x) => x.code === 'PINNED_SUBSTITUTION_DROPPED')?.data?.reason).toBe('not_similar');
  });

  it('ejercicio desconocido → unknown_exercise; original fuera del plan nuevo → not_in_plan', () => {
    const p = plan(GYM, [{ from: 'no-existe-en-el-plan', to: 'tampoco' }]);
    expect(p.warnings.find((x) => x.code === 'PINNED_SUBSTITUTION_DROPPED')?.data?.reason).toBe('unknown_exercise');
    const base = plan(GYM);
    const used = new Set(base.sessions.flatMap((s) => s.exercises.map((e) => e.exerciseId)));
    const absent = CATALOG.find((e) => {
      if (used.has(e.slug) || exclusionReason(e, { ...GYM, limitations: [], bannedExerciseIds: [] })) return false;
      const subs = substitutes(e.slug, GYM, CATALOG, 1);
      return subs.ok && subs.substitutes.length > 0;
    })!;
    const to = (substitutes(absent.slug, GYM, CATALOG, 1) as { ok: true; substitutes: { exerciseId: string }[] }).substitutes[0].exerciseId;
    const q = plan(GYM, [{ from: absent.slug, to }]);
    expect(q.warnings.find((x) => x.code === 'PINNED_SUBSTITUTION_DROPPED')?.data?.reason).toBe('not_in_plan');
  });

  it('propiedad: un cambio fijado aplicado nunca viola material, limitaciones, vetados ni nivel', () => {
    const slugs = CATALOG.map((e) => e.slug);
    fc.assert(
      fc.property(
        fc.record({
          goal: fc.constantFrom(...engineV2.TRAINING_GOALS),
          level: fc.constantFrom(...engineV2.TRAINING_LEVELS),
          daysPerWeek: fc.integer({ min: 2, max: 6 }),
          minutesPerSession: fc.integer({ min: 30, max: 90 }),
          equipment: fc.subarray([...engineV2.EQUIPMENT]),
          limitations: fc.subarray([...engineV2.BODY_ZONES], { maxLength: 3 }),
          bannedExerciseIds: fc.subarray(slugs, { maxLength: 8 }),
        }),
        fc.array(fc.record({ from: fc.constantFrom(...slugs), to: fc.constantFrom(...slugs) }), { maxLength: 6 }),
        (profile, pins) => {
          const r = generatePlan(profile, CATALOG, { pinnedSubstitutions: pins });
          if (!r.ok) return;
          const normalized = { ...profile, priorityMuscles: [], favouriteExerciseIds: [] };
          for (const pin of r.plan.pinnedSubstitutions) {
            const to = CATALOG.find((e) => e.slug === pin.to)!;
            const from = CATALOG.find((e) => e.slug === pin.from)!;
            expect(exclusionReason(to, normalized)).toBeNull();
            expect(to.substitutionGroup === from.substitutionGroup || to.movementPattern === from.movementPattern).toBe(true);
            expect(r.plan.sessions[pin.sessionOrder].exercises[pin.exerciseOrder].exerciseId).toBe(pin.from);
          }
        },
      ),
      { numRuns: 150, seed: 20261111 },
    );
  });
});
