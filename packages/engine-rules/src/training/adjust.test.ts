import fc from 'fast-check';
import { engineV2 } from '@pipos/contracts';
import { describe, expect, it } from 'vitest';
import { adjustedPrescription, adjustSession, type AdjustItem } from './adjust.js';
import { estimateSessionMinutes } from './estimate.js';
import { nextPrescription } from './progression.js';

const item = (id: string, role: engineV2.ExerciseRole, order: number, sets = 3): AdjustItem => ({
  id,
  nameEs: `Ejercicio ${id}`,
  role,
  order,
  sets,
  repMin: 8,
  repMax: 12,
  targetRir: 2,
  restSeconds: role === 'main' ? 120 : 90,
  isUnilateral: false,
  warmupSets: role === 'main' ? 2 : 0,
});

const SESSION: AdjustItem[] = [
  item('a', 'main', 0),
  item('b', 'secondary', 1),
  item('c', 'secondary', 2),
  item('d', 'accessory', 3),
  item('e', 'accessory', 4),
  item('f', 'core', 5, 2),
];

describe('adjustSession: poco tiempo', () => {
  it('quita core, luego accesorios del último al primero, hasta caber', () => {
    const full = estimateSessionMinutes(SESSION);
    const r = adjustSession(SESSION, { availableMinutes: 30 });
    expect(full).toBeGreaterThan(30);
    expect(r.dropped[0]).toBe('f');
    expect(r.dropped.slice(1, 3)).toEqual(['e', 'd']);
    expect(r.kept.map((k) => k.id)).toContain('a');
    expect(r.estimatedMinutes).toBeLessThanOrEqual(30);
    expect(r.fits).toBe(true);
    expect(r.rationale.join(' ')).toMatch(/Quitamos .* para que la sesión dure unos/);
  });

  it('si ya cabe, no quita nada', () => {
    const r = adjustSession(SESSION, { availableMinutes: 90 });
    expect(r.dropped).toEqual([]);
    expect(r.kept).toHaveLength(SESSION.length);
    expect(r.rationale[0]).toMatch(/ya cabe/);
  });

  it('solo principales y no cabe: baja series hasta el mínimo y avisa', () => {
    const mains = [item('a', 'main', 0, 4), item('b', 'main', 1, 4)];
    const r = adjustSession(mains, { availableMinutes: 15 });
    expect(r.dropped).toEqual([]);
    expect(r.kept.every((k) => k.sets >= 2)).toBe(true);
    expect(r.kept.some((k) => k.sets < 4)).toBe(true);
    if (!r.fits) expect(r.rationale.join(' ')).toMatch(/Ni con solo los ejercicios principales/);
  });

  it('el tiempo se acota a 15-90', () => {
    const r = adjustSession(SESSION, { availableMinutes: 5 });
    expect(r.rationale.join(' ')).toMatch(/15 min/);
  });
});

describe('adjustSession: volumen reducido', () => {
  it('una serie menos (mínimo 2 en principal/secundario, 1 en el resto) y RIR + 1', () => {
    const r = adjustSession([item('a', 'main', 0, 3), item('b', 'secondary', 1, 2), item('d', 'accessory', 2, 2), item('f', 'core', 3, 1)], {
      reducedVolume: true,
    });
    expect(r.kept).toEqual([
      { id: 'a', sets: 2, targetRir: 3 },
      { id: 'b', sets: 2, targetRir: 3 },
      { id: 'd', sets: 1, targetRir: 3 },
      { id: 'f', sets: 1, targetRir: 3 },
    ]);
  });

  it('sin subida de carga ese día', () => {
    const next: engineV2.NextPrescription = {
      action: 'increase_load', sets: 3, repMin: 8, repMax: 12, targetRir: 2, loadKg: 62.5, isDeload: false, rationale: ['x'],
    };
    const held = adjustedPrescription(next, { id: 'a', sets: 2, targetRir: 3 }, true, 60);
    expect(held).toMatchObject({ action: 'hold', loadKg: 60, sets: 2, targetRir: 3 });
    const normal = adjustedPrescription(next, { id: 'a', sets: 2, targetRir: 3 }, false, 60);
    expect(normal).toMatchObject({ action: 'increase_load', loadKg: 62.5, sets: 2, targetRir: 2 });
  });
});

describe('adjustSession: propiedades', () => {
  const roleArb = fc.constantFrom<engineV2.ExerciseRole>('main', 'secondary', 'accessory', 'core');
  const sessionArb = fc
    .array(fc.record({ role: roleArb, sets: fc.integer({ min: 1, max: 5 }), unilateral: fc.boolean() }), { minLength: 1, maxLength: 8 })
    .map((xs) => xs.map((x, i) => ({ ...item(`x${i}`, i === 0 ? 'main' : x.role, i, x.sets), isUnilateral: x.unilateral })));
  const adjArb = fc.record({
    availableMinutes: fc.option(fc.integer({ min: 0, max: 120 }), { nil: undefined }),
    reducedVolume: fc.boolean(),
  });

  it('nunca quita un principal, nunca aumenta el volumen, cabe o avisa y es determinista', () => {
    fc.assert(
      fc.property(sessionArb, adjArb, (session, adj) => {
        const r = adjustSession(session, adj);
        expect(r).toEqual(adjustSession(session, adj));
        const byId = new Map(session.map((s) => [s.id, s]));
        for (const m of session.filter((s) => s.role === 'main')) expect(r.dropped).not.toContain(m.id);
        expect(r.kept.length + r.dropped.length).toBe(session.length);
        for (const k of r.kept) {
          expect(k.sets).toBeLessThanOrEqual(byId.get(k.id)!.sets);
          expect(k.targetRir).toBeGreaterThanOrEqual(byId.get(k.id)!.targetRir);
        }
        if (adj.availableMinutes !== undefined) {
          const target = Math.min(90, Math.max(15, adj.availableMinutes));
          if (r.fits) expect(r.estimatedMinutes).toBeLessThanOrEqual(target);
          else expect(r.rationale.join(' ')).toMatch(/Ni con solo/);
        }
      }),
      { numRuns: 400, seed: 16017 },
    );
  });
});

describe('progresión: las sesiones ajustadas no disparan descarga ni bajada', () => {
  const p: engineV2.CurrentPrescription = {
    exerciseId: 'x', movementPattern: 'squat', loadType: 'weighted', sets: 3, repMin: 8, repMax: 12, targetRir: 2, loadKg: 100,
  };
  const log = (date: string, reps: number[], adjusted?: boolean): engineV2.ExerciseSessionLog => ({
    date,
    exerciseId: 'x',
    sets: reps.map((r) => ({ reps: r, loadKg: 100, rir: 2 })),
    ...(adjusted ? { adjusted: true } : {}),
  });

  it('dos sesiones flojas ajustadas → no baja la carga; sin ajustar sí', () => {
    const history = [log('2026-11-02', [6, 6, 6], true), log('2026-11-05', [6, 6, 6], true)];
    const r = nextPrescription({ prescription: p, history, today: '2026-11-09', weeksSinceDeload: 1 });
    expect(r.ok && r.next.action).not.toBe('decrease_load');
    expect(r.ok && r.next.action).not.toBe('deload');
    const plain = nextPrescription({ prescription: p, history: history.map((h) => ({ ...h, adjusted: false })), today: '2026-11-09', weeksSinceDeload: 1 });
    expect(plain.ok && plain.next.action).toBe('decrease_load');
  });

  it('estancamiento solo con sesiones ajustadas → no hay descarga reactiva', () => {
    const history = [log('2026-10-29', [10, 10, 10]), log('2026-11-02', [10, 10, 10], true), log('2026-11-05', [10, 10, 10], true)];
    const r = nextPrescription({ prescription: p, history, today: '2026-11-09', weeksSinceDeload: 1 });
    expect(r.ok && r.next.action).toBe('increase_reps');
  });
});
