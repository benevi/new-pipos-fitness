/**
 * Tipos internos y utilidades puras del motor v2.
 */
import type { engineV2 } from '@pipos/contracts';
import type { ProgrammingConfig } from '../config/programming.js';
import { loadImplement } from './load.js';

export type CatalogExercise = engineV2.CatalogExercise;
export type Profile = engineV2.EngineProfile;
export type VolumeGroup = engineV2.VolumeGroup;
export type Muscle = engineV2.Muscle;
export type MovementPattern = engineV2.MovementPattern;
export type ExerciseRole = engineV2.ExerciseRole;
export type SessionKind = engineV2.SessionKind;
export type BodyZone = engineV2.BodyZone;
export type Equipment = engineV2.Equipment;

export const LEVEL_RANK: Record<engineV2.TrainingLevel, number> = { beginner: 0, intermediate: 1, advanced: 2 };

export const PUSH_PATTERNS: ReadonlySet<MovementPattern> = new Set(['horizontal_push', 'vertical_push']);
export const PULL_PATTERNS: ReadonlySet<MovementPattern> = new Set(['horizontal_pull', 'vertical_pull']);
export const CORE_PATTERNS: ReadonlySet<MovementPattern> = new Set([
  'core_anti_extension',
  'core_anti_rotation',
  'core_flexion',
]);

/** Ejercicio del catálogo enriquecido con datos derivados que el motor usa a menudo. */
export interface Ex {
  readonly src: CatalogExercise;
  readonly slug: string;
  readonly pattern: MovementPattern;
  readonly weighted: boolean;
  /** Material que fija el paso de carga (§16.16); null si no se carga en kg. */
  readonly implement: engineV2.LoadImplement | null;
  /** Fracción por grupo de volumen = máxima fracción de sus músculos (PROGRAMACION.md §16.1). */
  readonly groups: ReadonlyMap<VolumeGroup, number>;
  readonly muscles: ReadonlyMap<Muscle, number>;
  readonly primaryMuscles: ReadonlySet<Muscle>;
  /** Zonas con riesgo «caution» (las «avoid» ya se filtraron si aplican). */
  readonly cautionZones: ReadonlySet<BodyZone>;
}

/**
 * Series efectivas que UNA serie de un ejercicio aporta a cada grupo de volumen: la máxima
 * fracción de sus músculos de ese grupo, no la suma (PROGRAMACION.md §16.1). Es la regla con
 * la que el motor cuenta el volumen; la analítica de /progress la reutiliza.
 */
export function groupFractions(
  muscles: readonly { muscle: Muscle; fraction: number }[],
  config: ProgrammingConfig,
): Map<VolumeGroup, number> {
  const map = config.volume.groupOfMuscle.value;
  const groups = new Map<VolumeGroup, number>();
  for (const m of muscles) {
    const g = map[m.muscle];
    if (g) groups.set(g, Math.max(groups.get(g) ?? 0, m.fraction));
  }
  return groups;
}

export function enrich(src: CatalogExercise, config: ProgrammingConfig): Ex {
  const groups = groupFractions(src.muscles, config);
  const muscles = new Map<Muscle, number>();
  const primary = new Set<Muscle>();
  for (const m of src.muscles) {
    muscles.set(m.muscle, m.fraction);
    if (m.role === 'primary') primary.add(m.muscle);
  }
  return {
    src,
    slug: src.slug,
    pattern: src.movementPattern,
    weighted: src.loadType === 'weighted',
    implement: loadImplement(src),
    groups,
    muscles,
    primaryMuscles: primary,
    cautionZones: new Set(src.riskTags.filter((r) => r.level === 'caution').map((r) => r.zone)),
  };
}

/** Comparación estable por código de carácter (no depende del locale). */
export function cmpStr(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}

export function round1(n: number): number {
  return Math.round(n * 10) / 10;
}

export function groupOf(muscle: Muscle, config: ProgrammingConfig): VolumeGroup | null {
  return config.volume.groupOfMuscle.value[muscle];
}
