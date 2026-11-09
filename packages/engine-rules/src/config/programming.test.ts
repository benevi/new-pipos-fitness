import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { ENGINE_VERSION, PROGRAMMING, schemeGoal, type Constant } from './programming.js';

const DOC = readFileSync(resolve(__dirname, '../../../../docs/engine/PROGRAMACION.md'), 'utf8');

/** Recorre el objeto y devuelve [ruta, nodo] de todas las hojas con forma de constante. */
function leaves(node: unknown, path: string[] = []): [string, Record<string, unknown>][] {
  if (node === null || typeof node !== 'object' || Array.isArray(node)) return [];
  const obj = node as Record<string, unknown>;
  if ('value' in obj) return [[path.join('.'), obj]];
  return Object.entries(obj).flatMap(([k, v]) => leaves(v, [...path, k]));
}

/** Nodos del árbol que NO son constantes (para detectar valores sueltos sin fuente). */
function looseValues(node: unknown, path: string[] = []): string[] {
  if (node === null || typeof node !== 'object' || Array.isArray(node)) return [path.join('.')];
  const obj = node as Record<string, unknown>;
  if ('value' in obj) return [];
  return Object.entries(obj).flatMap(([k, v]) => looseValues(v, [...path, k]));
}

describe('config/programming', () => {
  const all = leaves(PROGRAMMING);

  it('tiene un único ENGINE_VERSION 2.0.0', () => {
    expect(ENGINE_VERSION).toBe('2.0.0');
  });

  it('contiene un número razonable de constantes', () => {
    expect(all.length).toBeGreaterThan(80);
  });

  it('no hay valores sueltos: todo cuelga de una constante con fuente', () => {
    expect(looseValues(PROGRAMMING)).toEqual([]);
  });

  it.each(all)('%s tiene fuente PROGRAMACION.md §N y confianza', (_path, c) => {
    expect(c.source).toMatch(/^PROGRAMACION\.md §\d+(\.\d+)?$/);
    expect(['alta', 'media-alta', 'media', 'baja-media', 'baja']).toContain(c.confidence);
  });

  it('cada sección citada existe en PROGRAMACION.md', () => {
    const sections = new Set(all.map(([, c]) => String(c.source).replace('PROGRAMACION.md §', '')));
    for (const s of sections) {
      const heading = s.includes('.') ? new RegExp(`^### ${s.replace('.', '\\.')}\\b`, 'm') : new RegExp(`^## ${s}\\.`, 'm');
      expect(DOC, `sección §${s}`).toMatch(heading);
    }
  });

  it('las constantes que el documento marca como heurística conservan la etiqueta', () => {
    const P = PROGRAMMING;
    const heuristic: Constant<unknown>[] = [
      P.time.secondsPerRep,
      P.time.generalWarmupMin,
      P.time.warmupSetSeconds,
      P.time.transitionSeconds,
      P.prescription.warmup.heavyCompoundSets,
      P.progression.deloadEveryWeeks,
      P.progression.deloadVolumeReductionPct,
      P.progression.stagnationSessions,
      P.progression.minIncrementKg,
      P.balance.pullPushRatioMin,
      P.balance.pullPushRatioMax,
      P.nutrition.fatGPerKgGuard,
      P.frequency.split.twoToThreeDays,
      P.e1rm.useRirAsExtraReps,
    ];
    for (const c of heuristic) expect(c.heuristic).toBe(true);
  });

  it('toda constante de §16 (heurísticas de diseño) va marcada como heurística o es convención citada', () => {
    for (const [path, c] of all) {
      if (String(c.source).includes('§16') && c.confidence === 'baja') expect(c.heuristic, path).toBe(true);
    }
  });

  it('los valores por defecto caen dentro del rango citado', () => {
    for (const [path, c] of all) {
      const range = c.range as readonly [number, number] | undefined;
      if (range && typeof c.value === 'number') {
        expect(c.value, path).toBeGreaterThanOrEqual(range[0]);
        expect(c.value, path).toBeLessThanOrEqual(range[1]);
      }
    }
  });

  it('el conteo fraccional es 1 y 0,5 y el volumen crece con el nivel', () => {
    expect(PROGRAMMING.volume.indirectSetWeight.value).toBe(0.5);
    const { weeklyMin, weeklyMax } = PROGRAMMING.volume;
    expect(weeklyMin.beginner.value).toBeLessThan(weeklyMin.intermediate.value);
    expect(weeklyMin.intermediate.value).toBeLessThan(weeklyMin.advanced.value);
    for (const l of ['beginner', 'intermediate', 'advanced'] as const) {
      expect(weeklyMin[l].value).toBeLessThan(weeklyMax[l].value);
    }
  });

  it('los pesos del scoring suman 1', () => {
    const w = PROGRAMMING.scoring.weights.value;
    const sum = Object.values(w).reduce((a, b) => a + b, 0);
    expect(sum).toBeCloseTo(1, 10);
  });

  it('pérdida de grasa usa el esquema de hipertrofia', () => {
    expect(schemeGoal('fat_loss')).toBe('hypertrophy');
    expect(schemeGoal('strength')).toBe('strength');
  });
});
