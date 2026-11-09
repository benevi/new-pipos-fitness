/**
 * Estimación de duración de una sesión ya prescrita (PROGRAMACION.md §8), p. ej. tras sustituir
 * un ejercicio en la API. Usa el mismo modelo que el generador.
 */
import { PROGRAMMING, type ProgrammingConfig } from '../config/programming.js';

export interface SessionEstimateItem {
  readonly sets: number;
  readonly repMin: number;
  readonly repMax: number;
  readonly restSeconds: number;
  readonly isUnilateral: boolean;
  readonly warmupSets: number;
}

export function estimateSessionMinutes(
  items: readonly SessionEstimateItem[],
  config: ProgrammingConfig = PROGRAMMING,
): number {
  const t = config.time;
  let seconds = t.generalWarmupMin.value * 60;
  for (const it of items) {
    const work = ((it.repMin + it.repMax) / 2) * t.secondsPerRep.value * (it.isUnilateral ? t.unilateralFactor.value : 1);
    seconds +=
      it.sets * (work + it.restSeconds) - it.restSeconds + it.warmupSets * t.warmupSetSeconds.value + t.transitionSeconds.value;
  }
  return Math.round((seconds / 60) * 10) / 10;
}
