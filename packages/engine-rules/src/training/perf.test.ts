import { describe, expect, it } from 'vitest';
import { CATALOG, profile } from '../test-support/fixtures.js';
import { generatePlan } from './generate.js';

describe('rendimiento', () => {
  it('generatePlan < 200 ms (mediana de 20 ejecuciones, 6 días, 90 min, gimnasio completo)', () => {
    const p = profile({ daysPerWeek: 6, minutesPerSession: 90, level: 'advanced', goal: 'hypertrophy' });
    generatePlan(p, CATALOG); // calentamiento del JIT
    const times: number[] = [];
    for (let i = 0; i < 20; i++) {
      const t0 = performance.now();
      const r = generatePlan(p, CATALOG);
      times.push(performance.now() - t0);
      expect(r.ok).toBe(true);
    }
    times.sort((a, b) => a - b);
    const median = (times[9] + times[10]) / 2;
    console.log(`generatePlan 6×90 gimnasio: mediana ${median.toFixed(1)} ms, máx ${times[19].toFixed(1)} ms`);
    expect(median).toBeLessThan(200);
  });
});
