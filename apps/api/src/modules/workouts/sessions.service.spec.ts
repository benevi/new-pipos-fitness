import { describe, expect, it } from 'vitest';
import { platesFor } from './sessions.service';

describe('platesFor (idea 1)', () => {
  it('solo desglosa barras con carga conocida y ≥ barra', () => {
    expect(platesFor('barbell', 62.5)).toEqual({ barKg: 20, perSide: [20, 1.25], remainderKg: 0 });
    expect(platesFor('ez_bar', 25)).toEqual({ barKg: 10, perSide: [5, 2.5], remainderKg: 0 });
    expect(platesFor('barbell', 15)).toBeNull();
    expect(platesFor('barbell', null)).toBeNull();
    expect(platesFor('dumbbell', 20)).toBeNull();
    expect(platesFor('smith_machine', 60)).toBeNull();
    expect(platesFor(null, 60)).toBeNull();
  });
});
