import fc from 'fast-check';
import { engineV2 } from '@pipos/contracts';
import { describe, expect, it } from 'vitest';
import { CATALOG, FULL_GYM, HOME_DUMBBELLS, profile } from '../test-support/fixtures.js';
import { exclusionReason } from './filter.js';
import { muscleSimilarity, substitutes } from './substitutes.js';

const bySlug = new Map(CATALOG.map((e) => [e.slug, e]));

function subs(id: string, p: engineV2.EngineProfileInput) {
  const r = substitutes(id, p, CATALOG);
  if (!r.ok) throw new Error(r.error.message);
  return r.substitutes;
}

describe('CUJ-4: cambiar un ejercicio', () => {
  it('press de banca en gimnasio → 3 alternativas de press horizontal, la más parecida primero', () => {
    const s = subs('press-banca-barra', profile());
    expect(s).toHaveLength(3);
    for (const x of s) expect(bySlug.get(x.exerciseId)?.substitutionGroup).toBe('horizontal_press');
    expect(s[0].score).toBeGreaterThanOrEqual(s[1].score);
    expect(s[1].score).toBeGreaterThanOrEqual(s[2].score);
    expect(s[0].rationale.join(' ')).toMatch(/pecho/);
  });

  it('en casa con mancuernas, la sentadilla con barra se sustituye por variantes realizables', () => {
    const s = subs('sentadilla-trasera-barra', profile({ equipment: HOME_DUMBBELLS }));
    expect(s.length).toBeGreaterThan(0);
    for (const x of s) {
      const ex = bySlug.get(x.exerciseId)!;
      expect(ex.movementPattern).toBe('squat');
      expect(ex.equipment.every((e) => [...HOME_DUMBBELLS, 'bodyweight'].includes(e))).toBe(true);
    }
  });

  it('con lesión de hombro nunca propone ejercicios «avoid» de hombro', () => {
    const s = subs('press-hombros-sentado-mancuernas', profile({ limitations: ['shoulder'], level: 'advanced' }));
    const slugs = s.map((x) => x.exerciseId);
    expect(slugs).not.toContain('press-tras-nuca');
    expect(slugs).not.toContain('press-militar-barra');
    for (const x of s) expect(x.rationale.join(' ')).toMatch(/precaución|limitaciones/);
  });

  it('respeta vetados y nivel; el favorito sube en el orden', () => {
    const banned = subs('remo-barra', profile({ bannedExerciseIds: ['remo-sentado-polea'] })).map((x) => x.exerciseId);
    expect(banned).not.toContain('remo-sentado-polea');
    const fav = subs('remo-barra', profile({ favouriteExerciseIds: ['remo-trx'], equipment: [...FULL_GYM, 'suspension_trainer'] }));
    expect(fav[0].exerciseId).toBe('remo-trx');
    const beginner = subs('sentadilla-trasera-barra', profile({ level: 'beginner' })).map((x) => x.exerciseId);
    expect(beginner).not.toContain('sentadilla-frontal-barra');
  });

  it('errores tipados', () => {
    expect(substitutes('no-existe', profile(), CATALOG)).toMatchObject({ ok: false, error: { code: 'UNKNOWN_EXERCISE' } });
    expect(substitutes('flexiones', { goal: 'x' }, CATALOG)).toMatchObject({ ok: false, error: { code: 'INVALID_PROFILE' } });
    expect(substitutes('flexiones', profile(), [{}])).toMatchObject({ ok: false, error: { code: 'INVALID_CATALOG' } });
  });

  it('similitud muscular: 1 consigo mismo y simétrica', () => {
    const a = bySlug.get('press-banca-barra')!;
    const b = bySlug.get('flexiones')!;
    expect(muscleSimilarity(a, a)).toBeCloseTo(1);
    expect(muscleSimilarity(a, b)).toBeCloseTo(muscleSimilarity(b, a));
    expect(muscleSimilarity(a, bySlug.get('curl-biceps-mancuernas')!)).toBe(0);
  });

  it('propiedad (I13): todo sustituto cumple material, nivel, vetados y limitaciones y comparte grupo o patrón', () => {
    fc.assert(
      fc.property(
        fc.constantFrom(...CATALOG.map((e) => e.slug)),
        fc.subarray([...engineV2.EQUIPMENT]),
        fc.subarray([...engineV2.BODY_ZONES], { maxLength: 3 }),
        fc.constantFrom(...engineV2.TRAINING_LEVELS),
        (slug, equipment, limitations, level) => {
          const p = engineV2.EngineProfileSchema.parse(profile({ equipment, limitations, level }));
          const s = subs(slug, p);
          expect(s.length).toBeLessThanOrEqual(3);
          const orig = bySlug.get(slug)!;
          for (const x of s) {
            const ex = bySlug.get(x.exerciseId)!;
            expect(x.exerciseId).not.toBe(slug);
            expect(exclusionReason(ex, p)).toBeNull();
            expect(ex.substitutionGroup === orig.substitutionGroup || ex.movementPattern === orig.movementPattern).toBe(true);
          }
        },
      ),
      { numRuns: 300, seed: 5 },
    );
  });
});
