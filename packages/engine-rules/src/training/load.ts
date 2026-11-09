/**
 * Carga real según el material (PROGRAMACION.md §16.16; idea 1 de docs/IDEAS_EL_PLAN.md).
 * El motor solo propone pesos que existen: múltiplos del paso del material (2,5 kg en barra,
 * 2 kg en mancuernas, 5 kg en máquinas de placas…) y el desglose de discos de una barra.
 * Funciones puras.
 */
import { engineV2 } from '@pipos/contracts';
import { PROGRAMMING, type ProgrammingConfig } from '../config/programming.js';

export type LoadImplement = engineV2.LoadImplement;
export type RoundDirection = 'down' | 'nearest' | 'up';

const EPS = 1e-9;

/** Redondeo a céntimos de kg para que 47,5 no salga como 47,50000001. */
function cents(n: number): number {
  return Math.round(n * 100) / 100;
}

/**
 * Material que fija el paso de carga de un ejercicio con peso. Prioridad fija (la de
 * `LOAD_IMPLEMENTS`): un press en banco con mancuernas usa el paso de las mancuernas.
 * null si el ejercicio no se carga en kg o no usa ningún material de carga.
 */
export function loadImplement(ex: Pick<engineV2.CatalogExercise, 'equipment' | 'loadType'>): LoadImplement | null {
  if (ex.loadType !== 'weighted') return null;
  return engineV2.LOAD_IMPLEMENTS.find((i) => ex.equipment.includes(i)) ?? null;
}

/** Paso de carga (kg totales) del material; sin material, el genérico de 1 kg (§16.10). */
export function loadStepKg(implement: LoadImplement | null | undefined, config: ProgrammingConfig = PROGRAMMING): number {
  if (!implement) return config.e1rm.loadRoundingKg.value;
  return config.load.stepKgByImplement.value[implement];
}

/** Redondea `kg` a un múltiplo del paso del material. */
export function roundLoad(
  kg: number,
  implement: LoadImplement | null | undefined,
  dir: RoundDirection,
  config: ProgrammingConfig = PROGRAMMING,
): number {
  const step = loadStepKg(implement, config);
  const q = kg / step;
  const n = dir === 'down' ? Math.floor(q + EPS) : dir === 'up' ? Math.ceil(q - EPS) : Math.round(q);
  return cents(n * step);
}

/** ¿`kg` es un múltiplo del paso del material? */
export function isLoadStepMultiple(
  kg: number,
  implement: LoadImplement | null | undefined,
  config: ProgrammingConfig = PROGRAMMING,
): boolean {
  const step = loadStepKg(implement, config);
  return Math.abs(kg / step - Math.round(kg / step)) < 1e-6;
}

/** Peso de la barra vacía si el material es una barra de discos; null en otro caso. */
export function barKgFor(implement: LoadImplement | null | undefined, config: ProgrammingConfig = PROGRAMMING): number | null {
  if (!implement) return null;
  return config.load.barKg.value[implement] ?? null;
}

/**
 * Discos por lado para montar `totalKg` en una barra de `barKg` con los discos disponibles
 * (cantidad ilimitada de cada uno). Voraz de mayor a menor: con la serie estándar de discos
 * da la solución con menos discos. `remainderKg` = kg totales que no se pueden formar.
 * null si el total es menor que la barra.
 */
export function plateBreakdown(
  totalKg: number,
  barKg: number,
  availablePlates: readonly number[] = PROGRAMMING.load.platesKg.value,
): engineV2.PlateBreakdown | null {
  if (!Number.isFinite(totalKg) || totalKg < barKg - EPS) return null;
  const plates = [...new Set(availablePlates.filter((p) => p > 0))].sort((a, b) => b - a);
  let side = (totalKg - barKg) / 2;
  const perSide: number[] = [];
  for (const p of plates) {
    while (side >= p - EPS) {
      perSide.push(p);
      side = cents(side - p);
    }
  }
  const loaded = barKg + 2 * perSide.reduce((s, p) => s + p, 0);
  return { barKg, perSide, remainderKg: Math.max(0, cents(totalKg - loaded)) };
}
