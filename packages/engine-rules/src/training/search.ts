/**
 * Búsqueda local acotada (PLAN §3, paso 7; ADR-0006): mejor mejora por iteración entre
 * intercambios de ejercicio, ±1 serie y eliminación de accesorios. Determinista: el orden de
 * exploración es fijo y el desempate es estricto (solo se acepta una mejora > EPS).
 * Límite operativo: iteraciones y evaluaciones; el tiempo es solo una red de seguridad.
 */
import type { engineV2 } from '@pipos/contracts';
import { CORE_PATTERNS, type Ex } from './model.js';
import { maxSetsFor } from './prescription.js';
import {
  aggregateSession,
  groupSessionCount,
  scorePlan,
  weeklyGroups,
  sessionFeasible,
  weeklyFeasible,
  type Ctx,
  type DraftItem,
  type DraftSession,
  type SessionAgg,
} from './state.js';
import { replaceItem, staticQuality } from './construct.js';

const EPS = 1e-9;

export interface SearchResult {
  sessions: DraftSession[];
  meta: engineV2.LocalSearchMeta;
}

export interface SearchOptions {
  /** Reloj inyectable (ms). Por defecto `performance.now`. */
  now?: () => number;
  enabled?: boolean;
}

/** Candidatos de intercambio: mismo hueco (o mismo grupo primario) y calidad estática no peor. */
function candidatesFor(item: DraftItem, ctx: Ctx): readonly Ex[] {
  const base = item.slot
    ? ctx.eligible.filter((e) => item.slot!.patterns.includes(e.pattern))
    : ctx.eligible.filter(
        (e) =>
          e.pattern === item.ex.pattern ||
          [...item.ex.groups].some(([g, f]) => f >= 1 && (e.groups.get(g) ?? 0) >= 1 && !CORE_PATTERNS.has(e.pattern)),
      );
  const q = staticQuality(item.ex, item.slot, item.role, ctx);
  return base.filter((e) => staticQuality(e, item.slot, item.role, ctx) >= q - 1e-9);
}

/**
 * La búsqueda nunca empeora un suelo ya cumplido (volumen ≥ mínimo y frecuencia ≥ 2): el
 * balance tirón/empuje o la variedad no justifican dejar un grupo por debajo del mínimo (I4, I8).
 */
function keepsFloors(before: readonly SessionAgg[], after: readonly SessionAgg[], ctx: Ctx): boolean {
  const wb = weeklyGroups(before);
  const wa = weeklyGroups(after);
  const minFreq = ctx.config.frequency.minPerGroup.value;
  for (const g of ctx.groups) {
    const floor = ctx.floors.get(g) ?? 0;
    const vb = wb.get(g) ?? 0;
    const va = wa.get(g) ?? 0;
    if (va < floor - 1e-9 && va < vb - 1e-9) return false;
    const fa = groupSessionCount(after, g, ctx);
    if (fa < minFreq && fa < groupSessionCount(before, g, ctx)) return false;
  }
  return true;
}

export function localSearch(initial: readonly DraftSession[], ctx: Ctx, opts: SearchOptions = {}): SearchResult {
  const ls = ctx.config.localSearch;
  const now = opts.now ?? (() => performance.now());
  let sessions = initial.slice();
  let aggs: SessionAgg[] = sessions.map((s) => aggregateSession(s, ctx));
  const initialScore = scorePlan(aggs, ctx).total;
  let score = initialScore;
  if (opts.enabled === false) {
    return {
      sessions,
      meta: { iterations: 0, evaluations: 0, acceptedMoves: 0, initialScore, finalScore: score, stoppedBy: 'disabled' },
    };
  }
  const start = now();
  const maxSets = (it: DraftItem) => maxSetsFor(ctx.profile, ctx.config, it.role);
  const minSets = ctx.config.prescription.sets.min.value;
  const candCache = new Map<DraftItem, readonly Ex[]>();
  let evaluations = 0;
  let iterations = 0;
  let accepted = 0;
  let stoppedBy: engineV2.LocalSearchMeta['stoppedBy'] = 'converged';

  outer: for (;;) {
    if (iterations >= ls.maxIterations.value) {
      stoppedBy = 'iterations';
      break;
    }
    iterations += 1;
    let bestScore = score;
    let bestMove: { si: number; session: DraftSession; agg: SessionAgg } | null = null;

    const tryMove = (si: number, cand: DraftSession): boolean => {
      evaluations += 1;
      const agg = aggregateSession(cand, ctx);
      if (sessionFeasible(agg, ctx)) {
        const all = aggs.slice();
        all[si] = agg;
        if (weeklyFeasible(all, ctx) && keepsFloors(aggs, all, ctx)) {
          const sc = scorePlan(all, ctx).total;
          if (sc > bestScore + EPS) {
            bestScore = sc;
            bestMove = { si, session: cand, agg };
          }
        }
      }
      return evaluations >= ls.maxEvaluations.value;
    };

    for (let si = 0; si < sessions.length; si++) {
      const s = sessions[si];
      const inSession = new Set(s.items.map((i) => i.ex.slug));
      for (let i = 0; i < s.items.length; i++) {
        const it = s.items[i];
        // ±1 serie.
        if (it.sets < maxSets(it) && tryMove(si, replaceItem(s, i, { ...it, sets: it.sets + 1 }))) {
          stoppedBy = 'evaluations';
          break outer;
        }
        if (it.sets > minSets && tryMove(si, replaceItem(s, i, { ...it, sets: it.sets - 1 }))) {
          stoppedBy = 'evaluations';
          break outer;
        }
        // Quitar un accesorio de relleno.
        if (!it.slot && it.role !== 'main' && tryMove(si, { ...s, items: s.items.filter((_, j) => j !== i) })) {
          stoppedBy = 'evaluations';
          break outer;
        }
        // Intercambiar por otro candidato del mismo hueco.
        let cands = candCache.get(it);
        if (!cands) {
          cands = candidatesFor(it, ctx);
          candCache.set(it, cands);
        }
        for (const ex of cands) {
          if (inSession.has(ex.slug)) continue;
          if (tryMove(si, replaceItem(s, i, { ...it, ex }))) {
            stoppedBy = 'evaluations';
            break outer;
          }
        }
      }
      if (now() - start > ls.maxMs.value) {
        stoppedBy = 'time';
        break outer;
      }
    }

    const move = bestMove as { si: number; session: DraftSession; agg: SessionAgg } | null;
    if (!move) {
      stoppedBy = 'converged';
      break;
    }
    sessions = sessions.slice();
    sessions[move.si] = move.session;
    aggs = aggs.slice();
    aggs[move.si] = move.agg;
    score = bestScore;
    accepted += 1;
  }
  return {
    sessions,
    meta: { iterations, evaluations, acceptedMoves: accepted, initialScore, finalScore: score, stoppedBy },
  };
}
