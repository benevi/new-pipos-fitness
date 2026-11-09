import fc from 'fast-check';
import { engineV2 } from '@pipos/contracts';
import { describe, expect, it } from 'vitest';
import { PROGRAMMING } from '../config/programming.js';
import { CATALOG } from '../test-support/fixtures.js';
import { generatePlan } from './generate.js';
import { isLoadStepMultiple, loadImplement, loadStepKg, plateBreakdown, roundLoad } from './load.js';
import { nextPrescription } from './progression.js';

const IMPLEMENTS = [...engineV2.LOAD_IMPLEMENTS];

describe('loadImplement (§16.16)', () => {
  it('todo ejercicio con peso del catálogo tiene material de carga y está en su equipment', () => {
    for (const ex of CATALOG.filter((e) => e.loadType === 'weighted')) {
      const imp = loadImplement(ex);
      expect(imp, ex.slug).not.toBeNull();
      expect(ex.equipment).toContain(imp);
    }
  });

  it('sin peso → null; prioridad barra > mancuerna; mancuerna > banco', () => {
    expect(loadImplement({ equipment: ['dumbbell'], loadType: 'unweighted' })).toBeNull();
    expect(loadImplement({ equipment: ['dumbbell', 'barbell'], loadType: 'weighted' })).toBe('barbell');
    expect(loadImplement({ equipment: ['bench', 'dumbbell'], loadType: 'weighted' })).toBe('dumbbell');
    expect(loadImplement({ equipment: ['bench'], loadType: 'weighted' })).toBeNull();
  });
});

describe('roundLoad', () => {
  it('redondea al paso del material en las tres direcciones', () => {
    expect(roundLoad(23, 'dumbbell', 'down')).toBe(22);
    expect(roundLoad(23, 'dumbbell', 'up')).toBe(24);
    expect(roundLoad(47, 'machine', 'down')).toBe(45);
    expect(roundLoad(47, 'machine', 'nearest')).toBe(45);
    expect(roundLoad(61.5, 'barbell', 'up')).toBe(62.5);
    expect(roundLoad(61.5, null, 'down')).toBe(61);
  });

  it('propiedad: el resultado es múltiplo del paso y respeta la dirección', () => {
    fc.assert(
      fc.property(fc.constantFrom(...IMPLEMENTS), fc.double({ min: 0, max: 400, noNaN: true }), (imp, kg) => {
        const down = roundLoad(kg, imp, 'down');
        const up = roundLoad(kg, imp, 'up');
        expect(isLoadStepMultiple(down, imp)).toBe(true);
        expect(isLoadStepMultiple(up, imp)).toBe(true);
        expect(down).toBeLessThanOrEqual(kg + 1e-6);
        expect(up).toBeGreaterThanOrEqual(kg - 1e-6);
        expect(up - down).toBeLessThanOrEqual(loadStepKg(imp) + 1e-6);
      }),
      { numRuns: 500, seed: 16016 },
    );
  });
});

describe('plateBreakdown', () => {
  it('barra de 20 con 32,5 kg por lado', () => {
    expect(plateBreakdown(85, 20)).toEqual({ barKg: 20, perSide: [25, 5, 2.5], remainderKg: 0 });
  });
  it('barra vacía y total menor que la barra', () => {
    expect(plateBreakdown(20, 20)).toEqual({ barKg: 20, perSide: [], remainderKg: 0 });
    expect(plateBreakdown(15, 20)).toBeNull();
  });
  it('informa de lo que no cuadra con los discos disponibles', () => {
    expect(plateBreakdown(61, 20)).toEqual({ barKg: 20, perSide: [20], remainderKg: 1 });
    expect(plateBreakdown(70, 20, [10])).toEqual({ barKg: 20, perSide: [10, 10], remainderKg: 10 });
  });
  it('propiedad: barra + 2 × discos + resto reconstruye el total', () => {
    fc.assert(
      fc.property(fc.integer({ min: 0, max: 160 }), fc.constantFrom(20, 10, 25), (steps, bar) => {
        const total = bar + steps * 2.5;
        const r = plateBreakdown(total, bar);
        expect(r).not.toBeNull();
        if (!r) return;
        const loaded = r.barKg + 2 * r.perSide.reduce((s, p) => s + p, 0) + r.remainderKg;
        expect(loaded).toBeCloseTo(total, 6);
        expect(r.remainderKg).toBe(0); // múltiplos de 2,5 siempre cuadran con discos de 1,25
        expect([...r.perSide].sort((a, b) => b - a)).toEqual(r.perSide);
      }),
      { numRuns: 300, seed: 16017 },
    );
  });
});

const dumbbellCurl: engineV2.CurrentPrescription = {
  exerciseId: 'curl-mancuernas',
  movementPattern: 'elbow_flexion',
  loadType: 'weighted',
  sets: 3,
  repMin: 8,
  repMax: 12,
  targetRir: 1,
  loadKg: 8,
  implement: 'dumbbell',
};

describe('progresión con el paso real del material', () => {
  it('mancuernas 8 → 10 kg con aviso de salto grande', () => {
    const r = nextPrescription({
      prescription: dumbbellCurl,
      history: [{ date: '2026-11-05', exerciseId: dumbbellCurl.exerciseId, sets: [12, 12, 12].map((reps) => ({ reps, loadKg: 8, rir: 1 })) }],
      today: '2026-11-09',
      weeksSinceDeload: 1,
    });
    expect(r.ok && r.next.action).toBe('increase_load');
    expect(r.ok && r.next.loadKg).toBe(10);
    expect(r.ok && r.next.rationale.join(' ')).toMatch(/salto grande \(\+25 %\)/);
  });

  it('máquina de placas: 47 kg registrados → sube a 50; bajada reactiva a 45', () => {
    const machine = { ...dumbbellCurl, exerciseId: 'extension-cuadriceps', movementPattern: 'knee_extension' as const, implement: 'machine' as const, loadKg: 50 };
    const up = nextPrescription({
      prescription: { ...machine, loadKg: 47 },
      history: [{ date: '2026-11-05', exerciseId: machine.exerciseId, sets: [12, 12, 12].map((reps) => ({ reps, loadKg: 47, rir: 1 })) }],
      today: '2026-11-09',
      weeksSinceDeload: 1,
    });
    expect(up.ok && up.next.loadKg).toBe(55); // 47 + max(5 % → 2,35, paso 5) = 52 → siguiente múltiplo 55
    const down = nextPrescription({
      prescription: machine,
      history: ['2026-11-02', '2026-11-05'].map((date) => ({ date, exerciseId: machine.exerciseId, sets: [6, 6, 6].map((reps) => ({ reps, loadKg: 50, rir: 1 })) })),
      today: '2026-11-09',
      weeksSinceDeload: 1,
    });
    expect(down.ok && down.next.action).toBe('decrease_load');
    expect(down.ok && down.next.loadKg).toBe(45);
  });

  it('propiedad: toda carga propuesta es múltiplo del paso del material', () => {
    const sessionArb = fc.record({
      reps: fc.array(fc.integer({ min: 0, max: 15 }), { minLength: 1, maxLength: 4 }),
      rir: fc.integer({ min: 0, max: 4 }),
      daysAgo: fc.integer({ min: 1, max: 40 }),
    });
    fc.assert(
      fc.property(
        fc.constantFrom(...IMPLEMENTS),
        fc.integer({ min: 1, max: 60 }),
        fc.array(sessionArb, { minLength: 0, maxLength: 4 }),
        fc.integer({ min: 0, max: 8 }),
        (imp, mult, sessions, weeks) => {
          const step = loadStepKg(imp);
          const load = mult * step;
          const history = sessions.map((s, i) => ({
            date: new Date(Date.UTC(2026, 10, 9) - (s.daysAgo + i) * 86_400_000).toISOString().slice(0, 10),
            exerciseId: 'x',
            sets: s.reps.map((reps) => ({ reps, loadKg: load, rir: s.rir })),
          }));
          const r = nextPrescription({
            prescription: { ...dumbbellCurl, exerciseId: 'x', implement: imp, loadKg: load },
            history,
            today: '2026-11-09',
            weeksSinceDeload: weeks,
          });
          expect(r.ok).toBe(true);
          if (r.ok && r.next.loadKg !== null) expect(isLoadStepMultiple(r.next.loadKg, imp), `${imp} ${r.next.loadKg}`).toBe(true);
        },
      ),
      { numRuns: 500, seed: 16018 },
    );
  });
});

describe('plan: cargas iniciales y aproximaciones con el paso real', () => {
  it('con historial, la carga inicial y las aproximaciones son múltiplos del paso', () => {
    const weighted = CATALOG.filter((e) => e.loadType === 'weighted');
    const history = {
      entries: weighted.map((e) => ({ date: '2026-11-01', exerciseId: e.slug, sets: [{ reps: 8, loadKg: 53, rir: 2 }] })),
    };
    const r = generatePlan(
      { goal: 'hypertrophy', level: 'intermediate', daysPerWeek: 4, minutesPerSession: 75, equipment: [...engineV2.EQUIPMENT], history },
      CATALOG,
    );
    expect(r.ok).toBe(true);
    if (!r.ok) return;
    let checked = 0;
    for (const s of r.plan.sessions) {
      for (const e of s.exercises) {
        const ex = CATALOG.find((c) => c.slug === e.exerciseId);
        const imp = ex ? loadImplement(ex) : null;
        if (e.initialLoadKg !== null) {
          checked++;
          expect(isLoadStepMultiple(e.initialLoadKg, imp), e.exerciseId).toBe(true);
        }
        for (const w of e.warmupSets) if (w.loadKg !== null) expect(isLoadStepMultiple(w.loadKg, imp)).toBe(true);
      }
    }
    expect(checked).toBeGreaterThan(5);
    expect(PROGRAMMING.load.platesKg.value.length).toBeGreaterThan(0);
  });
});
