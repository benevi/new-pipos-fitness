/**
 * Restricciones duras (PLAN §3, paso 2): material con `.every`, limitaciones por zona,
 * vetados y nivel mínimo. Se aplican una sola vez, antes de todo lo demás.
 */
import type { ProgrammingConfig } from '../config/programming.js';
import {
  cmpStr,
  enrich,
  LEVEL_RANK,
  type CatalogExercise,
  type Equipment,
  type Ex,
  type Profile,
} from './model.js';

export type ExclusionReason = 'equipment' | 'limitation' | 'banned' | 'level';

export function availableEquipment(profile: Pick<Profile, 'equipment'>): ReadonlySet<Equipment> {
  return new Set<Equipment>([...profile.equipment, 'bodyweight']);
}

/** Motivo por el que un ejercicio queda fuera para este perfil, o null si es elegible. */
export function exclusionReason(
  ex: CatalogExercise,
  profile: Pick<Profile, 'equipment' | 'limitations' | 'bannedExerciseIds' | 'level'>,
  equipment: ReadonlySet<Equipment> = availableEquipment(profile),
): ExclusionReason | null {
  if (profile.bannedExerciseIds.includes(ex.slug)) return 'banned';
  const zones = new Set(profile.limitations);
  if (ex.riskTags.some((r) => r.level === 'avoid' && zones.has(r.zone))) return 'limitation';
  if (!ex.equipment.every((e) => equipment.has(e))) return 'equipment';
  if (LEVEL_RANK[ex.minLevel] > LEVEL_RANK[profile.level]) return 'level';
  return null;
}

export interface FilterResult {
  eligible: Ex[];
  excluded: Map<string, ExclusionReason>;
}

export function filterCatalog(
  catalog: readonly CatalogExercise[],
  profile: Profile,
  config: ProgrammingConfig,
): FilterResult {
  const equipment = availableEquipment(profile);
  const limited = new Set(profile.limitations);
  const eligible: Ex[] = [];
  const excluded = new Map<string, ExclusionReason>();
  const sorted = [...catalog].sort((a, b) => cmpStr(a.slug, b.slug));
  for (const ex of sorted) {
    const reason = exclusionReason(ex, profile, equipment);
    if (reason) {
      excluded.set(ex.slug, reason);
      continue;
    }
    const e = enrich(ex, config);
    // Solo nos importan las zonas «caution» que el usuario ha declarado.
    eligible.push({ ...e, cautionZones: new Set([...e.cautionZones].filter((z) => limited.has(z))) });
  }
  return { eligible, excluded };
}
