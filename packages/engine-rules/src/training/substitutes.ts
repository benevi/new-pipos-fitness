/**
 * Sustitución de ejercicios (CUJ-4): top 3 alternativas que comparten grupo de sustitución o
 * patrón, ordenadas por similitud muscular y respetando material, nivel, vetados y limitaciones.
 */
import { engineV2 } from '@pipos/contracts';
import { PROGRAMMING, type ProgrammingConfig } from '../config/programming.js';
import { exclusionReason } from './filter.js';
import { MUSCLE_ES, ZONE_ES, list } from './labels.js';
import { cmpStr, type CatalogExercise } from './model.js';

export interface Substitute {
  exerciseId: string;
  nameEs: string;
  score: number;
  rationale: string[];
}

export type SubstitutesResult =
  | { ok: true; substitutes: Substitute[] }
  | { ok: false; error: { code: 'INVALID_PROFILE' | 'INVALID_CATALOG' | 'UNKNOWN_EXERCISE'; message: string } };

/** Similitud coseno entre vectores de fracciones musculares. */
export function muscleSimilarity(a: CatalogExercise, b: CatalogExercise): number {
  const va = new Map(a.muscles.map((m) => [m.muscle, m.fraction]));
  const vb = new Map(b.muscles.map((m) => [m.muscle, m.fraction]));
  let dot = 0;
  for (const [m, f] of va) dot += f * (vb.get(m) ?? 0);
  const na = Math.sqrt([...va.values()].reduce((s, f) => s + f * f, 0));
  const nb = Math.sqrt([...vb.values()].reduce((s, f) => s + f * f, 0));
  return na && nb ? dot / (na * nb) : 0;
}

export function substitutes(
  exerciseId: string,
  profileInput: unknown,
  catalogInput: unknown,
  limit = 3,
  config: ProgrammingConfig = PROGRAMMING,
): SubstitutesResult {
  const pp = engineV2.EngineProfileSchema.safeParse(profileInput);
  if (!pp.success) return { ok: false, error: { code: 'INVALID_PROFILE', message: pp.error.message } };
  const cp = engineV2.CatalogSchema.safeParse(catalogInput);
  if (!cp.success) return { ok: false, error: { code: 'INVALID_CATALOG', message: cp.error.message } };
  const profile = pp.data;
  const original = cp.data.find((e) => e.slug === exerciseId);
  if (!original) return { ok: false, error: { code: 'UNKNOWN_EXERCISE', message: `No existe «${exerciseId}»` } };
  const limited = new Set(profile.limitations);
  const fav = new Set(profile.favouriteExerciseIds);
  const penalty = config.scoring.cautionPenalty.value;

  const scored: Substitute[] = [];
  for (const ex of cp.data) {
    if (ex.slug === original.slug) continue;
    const sameGroup = ex.substitutionGroup === original.substitutionGroup;
    const samePattern = ex.movementPattern === original.movementPattern;
    if (!sameGroup && !samePattern) continue;
    if (exclusionReason(ex, profile)) continue;
    const sim = muscleSimilarity(original, ex);
    const caution = ex.riskTags.filter((r) => r.level === 'caution' && limited.has(r.zone)).map((r) => r.zone);
    let score = (sameGroup ? 2 : 0) + (samePattern ? 1 : 0) + 2 * sim;
    if (fav.has(ex.slug)) score += 0.5;
    if (ex.isCompound === original.isCompound) score += 0.25;
    score -= penalty * caution.length;
    const shared = ex.muscles
      .filter((m) => m.role === 'primary' && original.muscles.some((o) => o.muscle === m.muscle && o.role === 'primary'))
      .map((m) => MUSCLE_ES[m.muscle]);
    const rationale = [
      sameGroup ? 'Mismo tipo de ejercicio.' : 'Mismo patrón de movimiento.',
      shared.length ? `Trabaja también ${list(shared)} como músculo principal.` : 'Trabaja músculos parecidos.',
      'Cumple tu material, tu nivel y tus limitaciones.',
    ];
    if (caution.length) rationale.push(`Con precaución por tu ${list(caution.map((z) => ZONE_ES[z]))}.`);
    scored.push({ exerciseId: ex.slug, nameEs: ex.nameEs, score: Math.round(score * 1000) / 1000, rationale });
  }
  scored.sort((a, b) => b.score - a.score || cmpStr(a.exerciseId, b.exerciseId));
  return { ok: true, substitutes: scored.slice(0, Math.max(0, limit)) };
}
