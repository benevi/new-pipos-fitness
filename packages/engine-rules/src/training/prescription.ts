/**
 * Prescripción: reps, RIR y descanso por objetivo y tipo de ejercicio (PROGRAMACION.md §3-§5),
 * carga inicial desde el e1RM del historial (§9) y series de aproximación (§8, §16.5).
 */
import type { engineV2 } from '@pipos/contracts';
import { schemeGoal, type ProgrammingConfig, type RepScheme } from '../config/programming.js';
import type { Ex, ExerciseRole, Profile } from './model.js';

export interface Scheme extends RepScheme {
  readonly kind: 'strength_main' | 'compound' | 'isolation';
}

export function schemeFor(ex: Ex, role: ExerciseRole, profile: Profile, config: ProgrammingConfig): Scheme {
  const g = schemeGoal(profile.goal, config);
  const p = config.prescription;
  let base: RepScheme;
  let kind: Scheme['kind'];
  if (g === 'strength') {
    const sc = p.schemes.strength;
    if (role === 'main' && ex.src.isCompound && ex.weighted) {
      base = sc.main.value;
      kind = 'strength_main';
    } else if (ex.src.isCompound) {
      base = sc.compound.value;
      kind = 'compound';
    } else {
      base = sc.isolation.value;
      kind = 'isolation';
    }
  } else {
    const sc = p.schemes[g];
    base = ex.src.isCompound ? sc.compound.value : sc.isolation.value;
    kind = ex.src.isCompound ? 'compound' : 'isolation';
  }
  let { repMin, repMax, rir, restSeconds } = base;
  if (profile.level === 'beginner') {
    if (g !== 'muscular_endurance') {
      [repMin, repMax] = p.beginner.reps.value;
      if (kind === 'strength_main') {
        kind = 'compound';
        restSeconds = p.schemes.strength.compound.value.restSeconds;
      }
    }
    rir = Math.max(rir, ex.src.isCompound ? p.beginner.compoundRir.value : p.beginner.isolationRir.value);
  }
  if (ex.src.isCompound && p.neverFailureOnCompounds.value) rir = Math.max(rir, 1);
  restSeconds = Math.max(restSeconds, p.minRestSeconds.value);
  return { repMin, repMax, rir, restSeconds, kind };
}

export function setsFor(role: ExerciseRole, profile: Profile, config: ProgrammingConfig): number {
  const s = config.prescription.sets;
  let sets = role === 'main' && profile.goal === 'strength' ? s.strengthMain.value : s.default.value;
  if (profile.goal === 'general_health') sets = Math.min(sets, s.generalHealthMax.value);
  return sets;
}

export function maxSetsFor(profile: Profile, config: ProgrammingConfig, role?: ExerciseRole): number {
  const s = config.prescription.sets;
  if (profile.goal === 'general_health') return s.generalHealthMax.value;
  // SERIES_EJERCICIO_FUERZA 2-3 en el multiarticular principal (ACSM 2026).
  if (profile.goal === 'strength' && role === 'main') return s.strengthMain.range?.[1] ?? s.strengthMain.value;
  return s.max.value;
}

/** e1RM de Epley con reps efectivas = reps + RIR, solo si ≤ E1RM_REPS_MAX (§9). */
export function e1rmOfSet(set: engineV2.LoggedSet, config: ProgrammingConfig): number | null {
  if (set.isWarmup || set.reps < 1 || set.loadKg <= 0) return null;
  const eff = set.reps + (config.e1rm.useRirAsExtraReps.value ? (set.rir ?? 0) : 0);
  if (eff > config.e1rm.maxReps.value) return null;
  if (eff === 1) return set.loadKg;
  return set.loadKg * (1 + eff / config.e1rm.epleyDivisor.value);
}

/** e1RM de la sesión más reciente de ese ejercicio con series válidas (§16.10). */
export function latestE1rm(
  exerciseId: string,
  history: engineV2.TrainingHistory | undefined,
  config: ProgrammingConfig,
): { e1rm: number; date: string } | null {
  if (!history) return null;
  const entries = history.entries
    .filter((e) => e.exerciseId === exerciseId)
    .sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0));
  for (const entry of entries) {
    let best = 0;
    for (const set of entry.sets) best = Math.max(best, e1rmOfSet(set, config) ?? 0);
    if (best > 0) return { e1rm: best, date: entry.date };
  }
  return null;
}

export function roundDown(kg: number, step: number): number {
  return Math.floor(kg / step + 1e-9) * step;
}

export interface InitialLoad {
  loadKg: number | null;
  isEstimate: boolean;
  note: string;
}

export function initialLoad(
  ex: Ex,
  scheme: Scheme,
  profile: Profile,
  config: ProgrammingConfig,
): InitialLoad {
  if (!ex.weighted) {
    return {
      loadKg: null,
      isEstimate: false,
      note: ex.src.equipment.includes('resistance_band')
        ? `Elige una banda con la que termines cada serie con unas ${scheme.rir} repeticiones en reserva.`
        : 'Se hace con tu peso corporal; ajusta la dificultad con la variante o el tempo.',
    };
  }
  const best = latestE1rm(ex.slug, profile.history, config);
  if (!best) {
    return {
      loadKg: null,
      isEstimate: true,
      note: `Estimación inicial: sin historial de este ejercicio, elige un peso con el que hagas ${scheme.repMin} repeticiones dejando ${scheme.rir} en reserva.`,
    };
  }
  const eff = scheme.repMin + scheme.rir;
  if (eff > config.e1rm.maxReps.value) {
    return {
      loadKg: null,
      isEstimate: true,
      note: `Tu e1RM es ${Math.round(best.e1rm)} kg, pero para ${scheme.repMin}+ repeticiones la fórmula no es fiable: elige el peso que te deje ${scheme.rir} en reserva.`,
    };
  }
  const raw = best.e1rm / (1 + eff / config.e1rm.epleyDivisor.value);
  const load = roundDown(raw, config.e1rm.loadRoundingKg.value);
  const unreliable = config.e1rm.unreliablePatterns.value.includes(ex.pattern);
  return {
    loadKg: load,
    isEstimate: unreliable,
    note: unreliable
      ? `Carga ${load} kg calculada con tu e1RM de ${Math.round(best.e1rm)} kg (${best.date}); en bisagras la fórmula infraestima, tómala como punto de partida.`
      : `Carga ${load} kg calculada con tu e1RM de ${Math.round(best.e1rm)} kg (${best.date}) para ${scheme.repMin} reps a RIR ${scheme.rir}.`,
  };
}

export function warmupSets(
  count: number,
  workingLoad: number | null,
  config: ProgrammingConfig,
): engineV2.WarmupSet[] {
  const ramp = config.prescription.warmup.ramp.value.slice(0, count);
  return ramp.map((r) => ({
    reps: r.reps,
    loadPct: r.pct,
    loadKg: workingLoad === null ? null : roundDown((workingLoad * r.pct) / 100, config.e1rm.loadRoundingKg.value),
  }));
}
