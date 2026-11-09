import { e1rmOfSet, PROGRAMMING } from '@pipos/engine-rules';
import type { engineV2 } from '@pipos/contracts';

/** Versiones de las fórmulas: si cambian, `pnpm analytics:rebuild` recalcula las proyecciones. */
export const E1RM_FORMULA_VERSION = 'epley-rir-v1';
export const VOLUME_FORMULA_VERSION = 'fraction-v1';

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

/** Agrega el volumen por músculo en los grupos del motor (PROGRAMACION.md §16.1). */
export function groupVolume(
  muscles: ReadonlyMap<engineV2.Muscle, { effectiveSets: number }>,
): Map<engineV2.VolumeGroup, number> {
  const out = new Map<engineV2.VolumeGroup, number>();
  for (const [muscle, v] of muscles) {
    const group = PROGRAMMING.volume.groupOfMuscle.value[muscle];
    if (!group) continue;
    out.set(group, Math.round(((out.get(group) ?? 0) + v.effectiveSets) * 100) / 100);
  }
  return out;
}
