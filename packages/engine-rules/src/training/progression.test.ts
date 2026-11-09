import fc from 'fast-check';
import { engineV2 } from '@pipos/contracts';
import { describe, expect, it } from 'vitest';
import { daysBetween, nextPendingSession, nextPrescription } from './progression.js';

const squat: engineV2.CurrentPrescription = {
  exerciseId: 'sentadilla-trasera-barra',
  movementPattern: 'squat',
  loadType: 'weighted',
  sets: 3,
  repMin: 8,
  repMax: 12,
  targetRir: 2,
  loadKg: 100,
};
const bench: engineV2.CurrentPrescription = { ...squat, exerciseId: 'press-banca-barra', movementPattern: 'horizontal_push', loadKg: 60 };

function log(date: string, reps: number[], loadKg: number, rir?: number, exerciseId = squat.exerciseId): engineV2.ExerciseSessionLog {
  return {
    date,
    exerciseId,
    sets: [{ reps: 5, loadKg: loadKg / 2, isWarmup: true }, ...reps.map((r) => ({ reps: r, loadKg, ...(rir === undefined ? {} : { rir }) }))],
  };
}

function next(input: Partial<engineV2.NextPrescriptionInput>) {
  const r = nextPrescription({ prescription: squat, history: [], today: '2026-11-09', weeksSinceDeload: 1, ...input });
  if (!r.ok) throw new Error(JSON.stringify(r.error));
  return r.next;
}

describe('CUJ-3: progresión semanal', () => {
  it('techo de reps con RIR objetivo → sube la carga 5 % en tren inferior y lo explica', () => {
    const n = next({ history: [log('2026-11-05', [12, 12, 12], 100, 2)] });
    expect(n.action).toBe('increase_load');
    expect(n.loadKg).toBe(105);
    expect(n.rationale[0]).toMatch(/subimos 5 kg/);
  });

  it('tren superior sube 2,5 % con un mínimo de 1 kg, redondeado a kg', () => {
    const n = nextPrescription({
      prescription: bench,
      history: [log('2026-11-05', [12, 12, 12], 60, 3, bench.exerciseId)],
      today: '2026-11-09',
      weeksSinceDeload: 1,
    });
    expect(n.ok && n.next.loadKg).toBe(62); // 60 × 2,5 % = 1,5 → 2 kg
    const light = nextPrescription({
      prescription: { ...bench, loadKg: 10 },
      history: [log('2026-11-05', [12, 12, 12], 10, 2, bench.exerciseId)],
      today: '2026-11-09',
      weeksSinceDeload: 1,
    });
    expect(light.ok && light.next.loadKg).toBe(11);
  });

  it('techo de reps pero con menos RIR del objetivo → no sube, mantiene y pide reps', () => {
    const n = next({ history: [log('2026-11-05', [12, 12, 12], 100, 1)] });
    expect(n.action).toBe('increase_reps');
    expect(n.loadKg).toBe(100);
  });

  it('dentro del rango → mantiene la carga e intenta +1 rep', () => {
    expect(next({ history: [log('2026-11-05', [10, 9, 9], 100, 2)] }).action).toBe('increase_reps');
  });

  it('sin RIR registrado se decide solo por reps', () => {
    expect(next({ history: [log('2026-11-05', [12, 12, 12], 100)] }).action).toBe('increase_load');
  });

  it('una sesión floja → mantiene; dos seguidas por debajo del rango → baja 5 %', () => {
    const one = next({ history: [log('2026-10-30', [10, 10, 10], 100, 2), log('2026-11-05', [7, 7, 6], 100, 2)] });
    expect(one.action).toBe('hold');
    const two = next({
      history: [log('2026-10-27', [9, 9, 9], 100, 2), log('2026-10-30', [7, 7, 7], 100, 1), log('2026-11-05', [7, 8, 7], 100, 1)],
    });
    expect(two.action).toBe('decrease_load');
    expect(two.loadKg).toBe(95);
  });

  it('reps o RIR caen dos sesiones seguidas → deload reactivo con menos series y más RIR', () => {
    const n = next({
      history: [log('2026-10-26', [11, 11, 10], 100, 2), log('2026-10-30', [10, 10, 9], 100, 2), log('2026-11-05', [10, 9, 9], 100, 1)],
    });
    expect(n.action).toBe('deload');
    expect(n.isDeload).toBe(true);
    expect(n.sets).toBe(2);
    expect(n.targetRir).toBe(4);
    expect(n.loadKg).toBe(100);
    expect(n.rationale[0]).toMatch(/2 sesiones seguidas/);
  });

  it('subir la carga NO dispara un deload reactivo (60×12 → 62×8 no es una regresión)', () => {
    const n = nextPrescription({
      prescription: { ...bench, loadKg: 62 },
      history: [
        log('2026-10-26', [12, 12, 12], 60, 2, bench.exerciseId),
        log('2026-10-30', [8, 8, 8], 62, 2, bench.exerciseId),
        log('2026-11-05', [8, 8, 7], 62, 1, bench.exerciseId),
      ],
      today: '2026-11-09',
      weeksSinceDeload: 1,
    });
    expect(n.ok && n.next.action).not.toBe('deload');
  });

  it('estancamiento a la misma carga N sesiones → deload reactivo', () => {
    const n = next({
      history: [log('2026-10-26', [10, 9, 9], 100, 2), log('2026-10-30', [10, 9, 9], 100, 2), log('2026-11-05', [10, 9, 9], 100, 2)],
    });
    expect(n.action).toBe('deload');
  });

  it('bajar la carga y aun así rendir menos (e1RM) cuenta como regresión', () => {
    const n = next({
      history: [log('2026-10-26', [10, 10, 10], 100, 2), log('2026-10-30', [9, 9, 9], 100, 2), log('2026-11-05', [9, 9, 9], 95, 1)],
    });
    expect(n.action).toBe('deload');
    const ok = next({
      history: [log('2026-10-26', [10, 10, 10], 100, 2), log('2026-10-30', [9, 9, 9], 100, 2), log('2026-11-05', [12, 12, 12], 95, 2)],
    });
    expect(ok.action).not.toBe('deload');
  });

  it('deload programado tras 6 semanas', () => {
    const n = next({ history: [log('2026-11-05', [10, 10, 10], 100, 2)], weeksSinceDeload: 6 });
    expect(n.action).toBe('deload');
    expect(n.rationale[0]).toMatch(/6 semanas/);
  });

  it('peso corporal en el techo → propone variante más difícil, sin inventar carga', () => {
    const pu: engineV2.CurrentPrescription = {
      ...squat,
      exerciseId: 'flexiones',
      movementPattern: 'horizontal_push',
      loadType: 'unweighted',
      loadKg: null,
    };
    const r = nextPrescription({
      prescription: pu,
      history: [log('2026-11-05', [12, 12, 12], 0, 2, 'flexiones')],
      today: '2026-11-09',
      weeksSinceDeload: 0,
    });
    expect(r.ok && r.next.action).toBe('progress_variant');
    expect(r.ok && r.next.loadKg).toBeNull();
  });

  it('primera vez: start y pide elegir carga si no la hay', () => {
    expect(next({}).action).toBe('start');
    const r = next({ prescription: { ...squat, loadKg: null } });
    expect(r.rationale[0]).toMatch(/elige un peso/);
  });

  it('sin carga prescrita usa la de la última sesión', () => {
    const n = next({ prescription: { ...squat, loadKg: null }, history: [log('2026-11-05', [12, 12, 12], 80, 2)] });
    expect(n.loadKg).toBe(84);
  });

  it('ignora sesiones futuras, de otros ejercicios y solo de calentamiento; ordena por fecha', () => {
    const n = next({
      history: [
        log('2026-11-05', [12, 12, 12], 100, 2),
        log('2026-12-01', [3, 3, 3], 100, 0),
        log('2026-11-01', [3, 3], 100, 0, 'otro'),
        { date: '2026-11-06', exerciseId: squat.exerciseId, sets: [{ reps: 5, loadKg: 50, isWarmup: true }] },
        log('2026-10-01', [8, 8, 8], 95, 2),
      ],
    });
    expect(n.action).toBe('increase_load');
  });

  it('entrada inválida → error tipado', () => {
    const r = nextPrescription({ prescription: { ...squat, repMin: 15 }, history: [], today: '2026-11-09', weeksSinceDeload: 0 });
    expect(r.ok).toBe(false);
    expect(nextPrescription({ prescription: squat, history: [], today: '9/11/2026', weeksSinceDeload: 0 }).ok).toBe(false);
  });
});

describe('CUJ-5: faltar y volver', () => {
  it('≥ 14 días sin entrenar → baja la carga un 10 % y lo explica', () => {
    const n = next({ history: [log('2026-10-20', [12, 12, 12], 100, 2)], today: '2026-11-09' });
    expect(n.action).toBe('return_after_break');
    expect(n.loadKg).toBe(90);
    expect(n.rationale[0]).toMatch(/20 días/);
  });

  it('13 días no cuenta como pausa', () => {
    expect(next({ history: [log('2026-10-27', [12, 12, 12], 100, 2)] }).action).toBe('increase_load');
  });

  it('tras una pausa en peso corporal no inventa carga', () => {
    const r = nextPrescription({
      prescription: { ...squat, loadType: 'unweighted', loadKg: null },
      history: [log('2026-09-01', [10, 10, 10], 0, 2)],
      today: '2026-11-09',
      weeksSinceDeload: 0,
    });
    expect(r.ok && r.next.loadKg).toBeNull();
    expect(r.ok && r.next.rationale[0]).toMatch(/parte baja del rango/);
  });

  it('las sesiones saltadas no rompen el orden: sigue la siguiente pendiente', () => {
    expect(nextPendingSession(4, [])).toBe(0);
    expect(nextPendingSession(4, [0, 1])).toBe(2);
    expect(nextPendingSession(4, [0, 1, 2, 3])).toBe(0);
    expect(nextPendingSession(0, [1])).toBe(0);
  });

  it('daysBetween cuenta días naturales en UTC', () => {
    expect(daysBetween('2026-10-31', '2026-11-01')).toBe(1);
    expect(daysBetween('2026-03-28', '2026-03-30')).toBe(2);
  });
});

describe('propiedades de la progresión (I12)', () => {
  it('con cargas estrictamente crecientes nunca hay deload reactivo', () => {
    fc.assert(
      fc.property(
        fc.array(fc.record({ inc: fc.integer({ min: 1, max: 10 }), reps: fc.integer({ min: 1, max: 15 }), rir: fc.integer({ min: 0, max: 4 }) }), {
          minLength: 3,
          maxLength: 6,
        }),
        (steps) => {
          let load = 40;
          const history = steps.map((st, i) => {
            load += st.inc;
            return log(`2026-10-${String(10 + i * 2).padStart(2, '0')}`, [st.reps, st.reps], load, st.rir);
          });
          const n = next({ history, today: '2026-10-25' });
          expect(n.action).not.toBe('deload');
        },
      ),
      { numRuns: 300, seed: 7 },
    );
  });


  it('nunca sube más del incremento, nunca carga negativa y el deload deja ≥ 1 serie', () => {
    const setArb = fc.record({ reps: fc.integer({ min: 0, max: 20 }), loadKg: fc.integer({ min: 0, max: 200 }), rir: fc.integer({ min: 0, max: 5 }) });
    const logArb = fc.record({
      date: fc.integer({ min: 1, max: 28 }).map((d) => `2026-10-${String(d).padStart(2, '0')}`),
      exerciseId: fc.constant(squat.exerciseId),
      sets: fc.array(setArb, { minLength: 1, maxLength: 5 }),
    });
    fc.assert(
      fc.property(
        fc.array(logArb, { maxLength: 6 }),
        fc.integer({ min: 1, max: 10 }),
        fc.integer({ min: 20, max: 200 }),
        fc.integer({ min: 0, max: 8 }),
        (history, sets, load, weeks) => {
          const r = nextPrescription({ prescription: { ...squat, sets, loadKg: load }, history, today: '2026-11-01', weeksSinceDeload: weeks });
          if (!r.ok) throw new Error('inválido');
          const n = r.next;
          expect(n.sets).toBeGreaterThanOrEqual(1);
          expect(n.loadKg ?? 0).toBeGreaterThanOrEqual(0);
          expect(n.loadKg ?? 0).toBeLessThanOrEqual(load + Math.max(1, Math.ceil(load * 0.05)));
          expect(n.rationale.length).toBeGreaterThan(0);
        },
      ),
      { numRuns: 300, seed: 11 },
    );
  });
});
