import { e1rmOfSet, groupFractions, PROGRAMMING } from '@pipos/engine-rules';
import type { engineV2 } from '@pipos/contracts';

/** Versiones de las fórmulas: si cambian, `pnpm analytics:rebuild` recalcula las proyecciones. */
export const E1RM_FORMULA_VERSION = 'epley-rir-v1';
export const VOLUME_FORMULA_VERSION = 'fraction-v1';
/** Volumen por grupo con la regla del motor (máxima fracción por ejercicio y grupo). */
export const GROUP_VOLUME_FORMULA_VERSION = 'group-max-v1';

export interface SetForCalc {
  id: string;
  reps: number;
  loadKg: number;
  rir: number | null;
  isWarmup: boolean;
}

/** Mejor e1RM (Epley con RIR, motor) de las series de trabajo de una sesión. */
export function bestE1rm(sets: readonly SetForCalc[]): { e1rmKg: number; setId: string } | null {
  let best: { e1rmKg: number; setId: string } | null = null;
  for (const s of sets) {
    const value = e1rmOfSet(
      { reps: s.reps, loadKg: s.loadKg, ...(s.rir !== null ? { rir: s.rir } : {}), isWarmup: s.isWarmup },
      PROGRAMMING,
    );
    if (value !== null && value > 0 && (!best || value > best.e1rmKg)) {
      best = { e1rmKg: Math.round(value * 100) / 100, setId: s.id };
    }
  }
  return best;
}

export interface VolumeSet {
  reps: number;
  loadKg: number;
  muscles: readonly { muscle: engineV2.Muscle; fraction: number }[];
}

/** Series efectivas (Σ fracción) y tonelaje (Σ reps × kg × fracción) por músculo. */
export function muscleVolume(sets: readonly VolumeSet[]): Map<engineV2.Muscle, { effectiveSets: number; tonnageKg: number }> {
  const out = new Map<engineV2.Muscle, { effectiveSets: number; tonnageKg: number }>();
  for (const s of sets) {
    for (const m of s.muscles) {
      const acc = out.get(m.muscle) ?? { effectiveSets: 0, tonnageKg: 0 };
      acc.effectiveSets += m.fraction;
      acc.tonnageKg += s.reps * s.loadKg * m.fraction;
      out.set(m.muscle, acc);
    }
  }
  for (const v of out.values()) {
    v.effectiveSets = Math.round(v.effectiveSets * 100) / 100;
    v.tonnageKg = Math.round(v.tonnageKg * 100) / 100;
  }
  return out;
}

/**
 * Series efectivas por grupo de volumen, contadas como el motor (PROGRAMACION.md §16.1):
 * cada serie aporta a un grupo la MÁXIMA fracción de sus músculos de ese grupo (un remo con
 * dorsal 1 y espalda alta 1 cuenta 1 serie de espalda, no 2). Reutiliza `groupFractions`.
 */
export function groupVolume(sets: readonly Pick<VolumeSet, 'muscles'>[]): Map<engineV2.VolumeGroup, number> {
  const out = new Map<engineV2.VolumeGroup, number>();
  for (const s of sets) {
    for (const [group, fraction] of groupFractions(s.muscles, PROGRAMMING)) out.set(group, (out.get(group) ?? 0) + fraction);
  }
  for (const [g, v] of out) out.set(g, Math.round(v * 100) / 100);
  return out;
}

/**
 * Versión del plan vigente en una semana (issue #14): la última creada antes del final de la
 * semana (`weekEnd`, exclusivo). null si el plan aún no existía. `versions` en cualquier orden.
 */
export function versionForWeek<T extends { createdAt: Date }>(versions: readonly T[], weekEnd: Date): T | null {
  let found: T | null = null;
  for (const v of versions) {
    if (v.createdAt < weekEnd && (!found || v.createdAt >= found.createdAt)) found = v;
  }
  return found;
}

/** Sesiones y series previstas por semana de una versión del plan. */
export function plannedOf(version: { sessions: { exercises: { sets: number }[] }[] } | null): { sessions: number; sets: number } {
  return {
    sessions: version?.sessions.length ?? 0,
    sets: version?.sessions.reduce((n, s) => n + s.exercises.reduce((m, e) => m + e.sets, 0), 0) ?? 0,
  };
}
