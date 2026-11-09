import fc from 'fast-check';
import { engineV2 } from '@pipos/contracts';
import { describe, expect, it } from 'vitest';
import { nextPrescription } from './progression.js';
import {
  activeBreak,
  breakDaysInRange,
  daysAwayExcludingBreaks,
  isoWeekday,
  isScheduledDay,
  plannedSessionsForWeek,
} from './schedule.js';

const MONDAY = '2026-08-03';

describe('plannedSessionsForWeek (§16.18)', () => {
  it('sin pausa: las sesiones del plan', () => {
    expect(plannedSessionsForWeek(4, MONDAY, [])).toEqual({ planned: 4, breakDays: 0 });
  });
  it('semana completa en pausa: 0', () => {
    expect(plannedSessionsForWeek(4, MONDAY, [{ startsOn: '2026-08-01', endsOn: '2026-08-15' }])).toEqual({ planned: 0, breakDays: 7 });
  });
  it('pausa parcial sin días elegidos: proporcional', () => {
    // 4 × 4/7 = 2,29 → 2
    expect(plannedSessionsForWeek(4, MONDAY, [{ startsOn: '2026-08-03', endsOn: '2026-08-05' }])).toEqual({ planned: 2, breakDays: 3 });
  });
  it('pausa parcial con días elegidos: cuenta los días elegidos fuera de pausa', () => {
    // L, M, J, V; pausa de lunes a miércoles → quedan J y V.
    expect(plannedSessionsForWeek(4, MONDAY, [{ startsOn: '2026-08-03', endsOn: '2026-08-05' }], [1, 2, 4, 5])).toEqual({ planned: 2, breakDays: 3 });
  });
  it('pausas solapadas no cuentan dos veces', () => {
    const breaks = [
      { startsOn: '2026-08-03', endsOn: '2026-08-05' },
      { startsOn: '2026-08-04', endsOn: '2026-08-06' },
    ];
    expect(plannedSessionsForWeek(3, MONDAY, breaks).breakDays).toBe(4);
  });
  it('propiedad: nunca más sesiones que las del plan ni menos de 0', () => {
    fc.assert(
      fc.property(fc.integer({ min: 2, max: 6 }), fc.integer({ min: -10, max: 10 }), fc.integer({ min: 0, max: 20 }), (n, off, len) => {
        const start = new Date(Date.UTC(2026, 7, 3) + off * 86_400_000).toISOString().slice(0, 10);
        const end = new Date(Date.UTC(2026, 7, 3) + (off + len) * 86_400_000).toISOString().slice(0, 10);
        const r = plannedSessionsForWeek(n, MONDAY, [{ startsOn: start, endsOn: end }]);
        expect(r.planned).toBeGreaterThanOrEqual(0);
        expect(r.planned).toBeLessThanOrEqual(n);
      }),
      { numRuns: 300, seed: 16018 },
    );
  });
});

describe('ausencia sin contar las pausas', () => {
  it('días entre la última sesión y hoy menos los de pausa', () => {
    expect(daysAwayExcludingBreaks('2026-07-30', '2026-08-20', [])).toBe(21);
    expect(daysAwayExcludingBreaks('2026-07-30', '2026-08-20', [{ startsOn: '2026-08-01', endsOn: '2026-08-15' }])).toBe(6);
    expect(breakDaysInRange('2026-07-31', '2026-08-20', [{ startsOn: '2026-08-01', endsOn: '2026-08-15' }])).toBe(15);
  });

  it('progresión: 21 días con 15 de pausa planificada → no baja la carga; sin pausa sí', () => {
    const p: engineV2.CurrentPrescription = {
      exerciseId: 'x', movementPattern: 'squat', loadType: 'weighted', sets: 3, repMin: 8, repMax: 12, targetRir: 2, loadKg: 100,
    };
    const history = [{ date: '2026-07-30', exerciseId: 'x', sets: [10, 10, 10].map((reps) => ({ reps, loadKg: 100, rir: 2 })) }];
    const withBreak = nextPrescription({ prescription: p, history, today: '2026-08-20', weeksSinceDeload: 1, breaks: [{ startsOn: '2026-08-01', endsOn: '2026-08-15' }] });
    expect(withBreak.ok && withBreak.next.action).toBe('increase_reps');
    const without = nextPrescription({ prescription: p, history, today: '2026-08-20', weeksSinceDeload: 1 });
    expect(without.ok && without.next.action).toBe('return_after_break');
  });

  it('una pausa con endsOn < startsOn es una entrada inválida', () => {
    const r = nextPrescription({
      prescription: { exerciseId: 'x', movementPattern: 'squat', loadType: 'weighted', sets: 3, repMin: 8, repMax: 12, targetRir: 2, loadKg: 100 },
      history: [],
      today: '2026-08-20',
      weeksSinceDeload: 1,
      breaks: [{ startsOn: '2026-08-15', endsOn: '2026-08-01' }],
    });
    expect(r.ok).toBe(false);
  });
});

describe('días de entreno', () => {
  it('isoWeekday: lunes 1 … domingo 7', () => {
    expect(isoWeekday('2026-08-03')).toBe(1);
    expect(isoWeekday('2026-08-09')).toBe(7);
  });
  it('isScheduledDay: días elegidos, o los del plan por defecto; nunca en pausa', () => {
    expect(isScheduledDay('2026-08-03', [1, 3, 5], [2, 4])).toBe(true);
    expect(isScheduledDay('2026-08-04', [1, 3, 5], [2, 4])).toBe(false);
    expect(isScheduledDay('2026-08-04', [], [2, 4])).toBe(true);
    expect(isScheduledDay('2026-08-03', [1], [1], [{ startsOn: '2026-08-01', endsOn: '2026-08-05' }])).toBe(false);
  });
  it('activeBreak devuelve la pausa que cubre la fecha', () => {
    const b = [{ startsOn: '2026-08-01', endsOn: '2026-08-05', id: 'a' }];
    expect(activeBreak('2026-08-03', b)?.id).toBe('a');
    expect(activeBreak('2026-08-06', b)).toBeNull();
  });
});
