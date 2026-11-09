/**
 * Solución inicial por reglas (PLAN §3, paso 5): huecos de la plantilla (multiarticulares →
 * accesorios → core), músculo prioritario, relleno por déficit de volumen y ajuste al tiempo.
 * Elección por afinidad (favoritos, prioridad, nivel, cobertura, variedad); desempate por slug.
 */
import { LEVEL_RANK, cmpStr, CORE_PATTERNS, type Ex, type ExerciseRole, type VolumeGroup } from './model.js';
import { maxSetsFor, setsFor } from './prescription.js';
import type { SlotSpec } from './split.js';
import {
  aggregateSession,
  trainsPriority,
  sessionFeasible,
  weeklyFeasible,
  weeklyGroups,
  type Ctx,
  type DraftItem,
  type DraftSession,
  type SessionAgg,
} from './state.js';

export interface PickContext {
  readonly sessionGroups: ReadonlySet<VolumeGroup>;
  readonly inSession: ReadonlySet<string>;
  readonly subGroupsInSession: ReadonlySet<string>;
  readonly usedThisWeek: ReadonlyMap<string, number>;
  readonly deficits: ReadonlyMap<VolumeGroup, number>;
}

const PATTERN_TARGET: Partial<Record<Ex['pattern'], VolumeGroup>> = {
  squat: 'quads',
  lunge: 'quads',
  hinge: 'hamstrings',
  horizontal_push: 'chest',
  vertical_push: 'shoulders',
  horizontal_pull: 'back',
  vertical_pull: 'back',
  knee_flexion: 'hamstrings',
  knee_extension: 'quads',
  hip_isolation: 'glutes',
};

/**
 * Calidad estática de un ejercicio para un hueco: no depende del resto del plan. La búsqueda local
 * solo acepta intercambios que no la empeoran, para no cambiar un peso muerto por una variante
 * más floja solo por ganar variedad.
 */
export function staticQuality(ex: Ex, slot: SlotSpec | null, role: ExerciseRole, ctx: Ctx): number {
  let s = 0;
  if (slot) {
    const idx = slot.patterns.indexOf(ex.pattern);
    s += idx === 0 ? 1.5 : idx > 0 ? 1 - idx * 0.25 : 0;
    if (slot.prefer && ex.primaryMuscles.has(slot.prefer)) s += 1.5;
  }
  if (ctx.favourites.has(ex.slug)) s += 3;
  // Continuidad: un ejercicio con historial permite cargas reales desde el primer día.
  if (ctx.historySlugs.has(ex.slug)) s += 1;
  for (const m of ex.primaryMuscles) if (ctx.priorityMuscles.has(m)) s += 2;
  // El músculo «natural» del patrón como primario (p. ej. pecho en empuje horizontal).
  const natural = PATTERN_TARGET[ex.pattern];
  if (natural && (ex.groups.get(natural) ?? 0) >= 1) s += 1;
  const trained = LEVEL_RANK[ctx.profile.level] > 0;
  if (role === 'main') {
    if (ex.weighted) s += 1;
    if (!ex.src.isUnilateral) s += 0.5;
    if (ex.src.isCompound) s += 1;
    // La barra permite progresar con incrementos pequeños en entrenados.
    if (trained && ex.src.equipment.some((e) => e === 'barbell' || e === 'trap_bar')) s += 0.5;
  } else {
    if (ex.weighted) s += trained ? 0.75 : 0.25;
    if (role === 'secondary' && ex.src.isCompound) s += 0.5;
    if (role === 'accessory' && !ex.src.isCompound) s += 0.75;
    if (ex.src.isUnilateral) s -= 0.25;
  }
  if (ex.cautionZones.size > 0) s -= 1.5 * ex.cautionZones.size;
  return s;
}

/** Afinidad de un candidato para un hueco = calidad estática + encaje con el plan. Más alto = mejor. */
export function affinity(ex: Ex, slot: SlotSpec | null, role: ExerciseRole, pc: PickContext, ctx: Ctx): number {
  let s = staticQuality(ex, slot, role, ctx);
  const used = pc.usedThisWeek.get(ex.slug) ?? 0;
  s -= used * 0.75;
  if (pc.subGroupsInSession.has(ex.src.substitutionGroup)) s -= 1.5;
  let cover = 0;
  for (const [g, f] of ex.groups) {
    const d = pc.deficits.get(g) ?? 0;
    if (pc.sessionGroups.has(g) && d > 0) cover += f * Math.min(1, d / 3);
    else if (!pc.sessionGroups.has(g) && f >= 1) cover -= 0.25;
  }
  s += cover;
  return s;
}

/** Mejor candidato (o null). Desempate estable por slug. */
export function bestCandidate(
  candidates: readonly Ex[],
  slot: SlotSpec | null,
  role: ExerciseRole,
  pc: PickContext,
  ctx: Ctx,
): Ex | null {
  let best: Ex | null = null;
  let bestScore = -Infinity;
  for (const ex of candidates) {
    if (pc.inSession.has(ex.slug)) continue;
    if (pc.subGroupsInSession.has(ex.src.substitutionGroup) && !trainsPriority(ex, ctx)) continue;
    const sc = affinity(ex, slot, role, pc, ctx);
    if (sc > bestScore + 1e-12 || (Math.abs(sc - bestScore) <= 1e-12 && best && cmpStr(ex.slug, best.slug) < 0)) {
      best = ex;
      bestScore = sc;
    }
  }
  return best;
}

export function candidatesForSlot(slot: SlotSpec, ctx: Ctx): Ex[] {
  return ctx.eligible.filter((e) => slot.patterns.includes(e.pattern));
}

function usedMap(sessions: readonly DraftSession[]): Map<string, number> {
  const m = new Map<string, number>();
  for (const s of sessions) for (const it of s.items) m.set(it.ex.slug, (m.get(it.ex.slug) ?? 0) + 1);
  return m;
}

function sessionDeficits(
  session: DraftSession,
  agg: SessionAgg,
  ctx: Ctx,
  weekly?: ReadonlyMap<VolumeGroup, number>,
): Map<VolumeGroup, number> {
  const d = new Map<VolumeGroup, number>();
  for (const g of session.template.groups) {
    const perSession = (ctx.targets.get(g) ?? 0) / Math.max(1, ctx.sessionsIncluding.get(g) ?? 1);
    let need = perSession - (agg.group.get(g) ?? 0);
    if (weekly) need = Math.max(need, (ctx.targets.get(g) ?? 0) - (weekly.get(g) ?? 0));
    d.set(g, need);
  }
  return d;
}

function pickContext(
  session: DraftSession,
  agg: SessionAgg,
  others: readonly DraftSession[],
  ctx: Ctx,
  weekly?: ReadonlyMap<VolumeGroup, number>,
): PickContext {
  return {
    sessionGroups: new Set(session.template.groups),
    inSession: new Set(session.items.map((i) => i.ex.slug)),
    subGroupsInSession: new Set(session.items.map((i) => i.ex.src.substitutionGroup)),
    usedThisWeek: usedMap(others),
    deficits: sessionDeficits(session, agg, ctx, weekly),
  };
}

export interface UnfilledSlot {
  readonly sessionName: string;
  readonly slot: SlotSpec;
}

/** Recorta series y accesorios hasta que la sesión cabe en el presupuesto. */
export function fitToBudget(session: DraftSession, ctx: Ctx): DraftSession {
  let cur = session;
  const min = ctx.config.prescription.sets.min.value;
  const reduceOrder: ExerciseRole[] = ['accessory', 'core', 'secondary', 'main'];
  for (let guard = 0; guard < 200; guard++) {
    const agg = aggregateSession(cur, ctx);
    if (agg.minutes <= ctx.budgetMinutes + 1e-9) return cur;
    let changed = false;
    for (const role of reduceOrder) {
      // El ejercicio con más series de ese rol (el último en caso de empate) pierde una.
      let idx = -1;
      for (let i = cur.items.length - 1; i >= 0; i--) {
        const it = cur.items[i];
        if (it.role === role && it.sets > min && (idx < 0 || it.sets > cur.items[idx].sets)) idx = i;
      }
      if (idx >= 0) {
        cur = replaceItem(cur, idx, { ...cur.items[idx], sets: cur.items[idx].sets - 1 });
        changed = true;
        break;
      }
    }
    if (changed) continue;
    // Todo en el mínimo: quitar el último accesorio de relleno, luego accesorios y core de plantilla.
    const removable = [...cur.items.keys()]
      .filter((i) => cur.items[i].role === 'accessory' || cur.items[i].role === 'core')
      .sort((a, b) => (cur.items[a].slot ? 1 : 0) - (cur.items[b].slot ? 1 : 0) || b - a);
    if (removable.length > 0) {
      cur = { ...cur, items: cur.items.filter((_, i) => i !== removable[0]) };
      continue;
    }
    const secondaries = [...cur.items.keys()].filter((i) => cur.items[i].role === 'secondary');
    if (secondaries.length > 0) {
      cur = { ...cur, items: cur.items.filter((_, i) => i !== secondaries[secondaries.length - 1]) };
      continue;
    }
    return cur;
  }
  return cur;
}

export function replaceItem(session: DraftSession, idx: number, item: DraftItem): DraftSession {
  const items = session.items.slice();
  items[idx] = item;
  return { ...session, items };
}

/** Construye cada sesión: huecos → prioridad → relleno por déficit → ajuste al tiempo. */
export function buildInitial(
  sessions: readonly DraftSession[],
  ctx: Ctx,
): { sessions: DraftSession[]; unfilled: UnfilledSlot[] } {
  const out: DraftSession[] = sessions.map((s) => ({ ...s, items: [] }));
  const unfilled: UnfilledSlot[] = [];
  for (let si = 0; si < out.length; si++) {
    let session = out[si];
    const others = () => out.filter((_, i) => i !== si);
    session.template.slots.forEach((slot, slotIndex) => {
      const agg = aggregateSession(session, ctx);
      const pc = pickContext(session, agg, others(), ctx);
      const ex = bestCandidate(candidatesForSlot(slot, ctx), slot, slot.role, pc, ctx);
      if (!ex) {
        unfilled.push({ sessionName: session.template.name, slot });
        return;
      }
      const item: DraftItem = { ex, sets: setsFor(slot.role, ctx.profile, ctx.config), role: slot.role, slot, slotIndex };
      session = { ...session, items: [...session.items, item] };
    });
    // Músculos prioritarios sin trabajo directo en esta sesión.
    for (const m of [...ctx.priorityMuscles].sort(cmpStr)) {
      const g = ctx.config.volume.groupOfMuscle.value[m];
      if (g && !session.template.groups.includes(g)) continue;
      if (!g && session.template.kind !== 'full_body') continue;
      if (session.items.some((it) => it.ex.primaryMuscles.has(m))) continue;
      const agg = aggregateSession(session, ctx);
      const pc = pickContext(session, agg, others(), ctx);
      const cands = ctx.eligible.filter((e) => e.primaryMuscles.has(m) && !CORE_PATTERNS.has(e.pattern));
      const ex = bestCandidate(cands, null, 'accessory', pc, ctx);
      if (ex) {
        session = {
          ...session,
          items: [...session.items, { ex, sets: setsFor('accessory', ctx.profile, ctx.config), role: 'accessory', slot: null, slotIndex: 100 }],
        };
      }
    }
    session = fillDeficits(session, others(), ctx, false);
    session = fitToBudget(session, ctx);
    out[si] = session;
  }
  let result = repairCeilings(out, ctx);
  result = repairFrequency(result, ctx);
  result = fillWeekly(result, ctx);
  return { sessions: result, unfilled };
}

/**
 * Añade accesorios a la sesión para los grupos con déficit mientras quepan en el tiempo y no
 * superen techos. `weekly = true` usa el déficit semanal (segunda pasada).
 */
export function fillDeficits(
  session: DraftSession,
  others: readonly DraftSession[],
  ctx: Ctx,
  weekly: boolean,
): DraftSession {
  let cur = session;
  const blocked = new Set<VolumeGroup>();
  for (let guard = 0; guard < 12; guard++) {
    const agg = aggregateSession(cur, ctx);
    const weeklyVol = weekly ? weeklyGroups([...others, cur].map((s) => aggregateSession(s, ctx))) : undefined;
    const deficits = sessionDeficits(cur, agg, ctx, weeklyVol);
    const target = [...deficits]
      .filter(([g, d]) => d > 0.25 && !blocked.has(g))
      .sort((a, b) => b[1] - a[1] || cmpStr(a[0], b[0]))[0];
    if (!target) return cur;
    const [g] = target;
    const pc = pickContext(cur, agg, others, ctx, weeklyVol);
    const cands = ctx.eligible.filter(
      (e) => (e.groups.get(g) ?? 0) >= 1 && !ctx.config.balance.autoGenerationExcludedPatterns.value.includes(e.pattern),
    );
    const role: ExerciseRole = 'accessory';
    const ex = bestCandidate(cands, null, role, pc, ctx);
    if (!ex) {
      blocked.add(g);
      continue;
    }
    let placed = false;
    for (const sets of [setsFor(role, ctx.profile, ctx.config), ctx.config.prescription.sets.min.value]) {
      const next: DraftSession = {
        ...cur,
        items: [...cur.items, { ex, sets, role: CORE_PATTERNS.has(ex.pattern) ? 'core' : role, slot: null, slotIndex: 200 + guard }],
      };
      const nAgg = aggregateSession(next, ctx);
      const all = [...others.map((s) => aggregateSession(s, ctx)), nAgg];
      if (nAgg.minutes <= ctx.budgetMinutes + 1e-9 && sessionFeasible(nAgg, ctx) && weeklyFeasible(all, ctx)) {
        cur = next;
        placed = true;
        break;
      }
    }
    if (!placed) blocked.add(g);
  }
  return cur;
}

/** Si algún grupo supera su techo semanal, quita series empezando por accesorios. */
export function repairCeilings(sessions: DraftSession[], ctx: Ctx): DraftSession[] {
  const cur = sessions.slice();
  const min = ctx.config.prescription.sets.min.value;
  for (let guard = 0; guard < 300; guard++) {
    const weekly = weeklyGroups(cur.map((s) => aggregateSession(s, ctx)));
    const over = [...weekly]
      .filter(([g, v]) => v > (ctx.ceilings.get(g) ?? Infinity) + 1e-9)
      .sort((a, b) => cmpStr(a[0], b[0]))[0];
    if (!over) return cur;
    if (!reduceOne(cur, over[0], min, false, ctx) && !reduceOne(cur, over[0], min, true, ctx)) return cur;
  }
  return cur;
}

/**
 * Quita una serie (o un accesorio ya en el mínimo) que aporte al grupo, de accesorios a principales.
 * Con `touchKept = false` no toca favoritos ni el trabajo directo de un músculo prioritario.
 */
function reduceOne(cur: DraftSession[], g: VolumeGroup, min: number, touchKept: boolean, ctx: Ctx): boolean {
  for (const role of ['accessory', 'core', 'secondary', 'main'] as ExerciseRole[]) {
    for (let si = cur.length - 1; si >= 0; si--) {
      const items = cur[si].items;
      for (let i = items.length - 1; i >= 0; i--) {
        const it = items[i];
        if (it.role !== role || (it.ex.groups.get(g) ?? 0) === 0) continue;
        if (!touchKept && (ctx.favourites.has(it.ex.slug) || trainsPriority(it.ex, ctx))) continue;
        if (it.sets > min) {
          cur[si] = replaceItem(cur[si], i, { ...it, sets: it.sets - 1 });
          return true;
        }
        if (role === 'accessory' || role === 'core') {
          cur[si] = { ...cur[si], items: items.filter((_, j) => j !== i) };
          return true;
        }
      }
    }
  }
  return false;
}

/**
 * Segunda pasada semanal: primero sube a suelo los grupos que no llegan (añadiendo series o
 * accesorios donde quede tiempo); después usa el tiempo sobrante hasta el techo.
 */
export function fillWeekly(sessions: DraftSession[], ctx: Ctx): DraftSession[] {
  const cur = sessions.slice();
  const tolLow = ctx.budgetMinutes * (1 - ctx.config.time.tolerancePct.value / 100);
  for (let pass = 0; pass < 3; pass++) {
    for (let guard = 0; guard < 120; guard++) {
      const aggs = cur.map((s) => aggregateSession(s, ctx));
      const weekly = weeklyGroups(aggs);
      // Pasada 0: grupos bajo el suelo. Pasadas 1 y 2 (solo sesiones cortas): hasta la mitad del
      // rango y después hasta el techo, para repartir el tiempo sobrante entre todos los grupos.
      const ranked = ctx.groups
        .map((g) => {
          const v = weekly.get(g) ?? 0;
          const lo = ctx.floors.get(g) ?? 0;
          const hi = ctx.ceilings.get(g) ?? 0;
          const onlyFloor =
            !ctx.priorityGroups.has(g) && (ctx.config.prescription.fillOnlyToFloor.value as readonly string[]).includes(g);
          const prio = ctx.priorityGroups.has(g);
          // Los prioritarios van a la mitad alta del rango ya en la primera pasada.
          const goal = pass === 0 ? (prio ? (lo + hi) / 2 : lo) : onlyFloor ? lo : pass === 1 ? (lo + hi) / 2 : hi;
          return [g, goal - v] as const;
        })
        .filter(([, d]) => (pass === 0 ? d > 1e-9 : d >= 1 - 1e-9))
        .sort((a, b) => b[1] - a[1] || cmpStr(a[0], b[0]));
      let improved = false;
      for (const [g] of ranked) {
        // Sesiones que incluyen el grupo, la más holgada primero.
        const order = [...cur.keys()]
          .filter((i) => cur[i].template.groups.includes(g))
          .filter((i) => pass === 0 || aggs[i].minutes < tolLow)
          .sort((a, b) => aggs[a].minutes - aggs[b].minutes || a - b);
        for (const si of order) {
          const s = cur[si];
          // 1) +1 serie a un ejercicio que trabaje el grupo como primario (accesorios primero).
          const idxs = [...s.items.keys()]
            .filter((i) => (s.items[i].ex.groups.get(g) ?? 0) >= 1 && s.items[i].sets < maxSetsFor(ctx.profile, ctx.config, s.items[i].role))
            .sort((a, b) => roleRank(s.items[b].role) - roleRank(s.items[a].role) || s.items[a].sets - s.items[b].sets || a - b);
          let next: DraftSession | null = null;
          for (const i of idxs) {
            const cand = replaceItem(s, i, { ...s.items[i], sets: s.items[i].sets + 1 });
            if (accept(cand, si, cur, ctx)) {
              next = cand;
              break;
            }
          }
          // 2) Si no cabe, un accesorio nuevo.
          if (!next) {
            const filled = fillDeficitsFor(s, si, cur, g, ctx);
            if (filled) next = filled;
          }
          // 3) Solo para llegar al suelo: cambiar un accesorio de relleno de un grupo que ya va sobrado.
          if (!next && pass === 0) next = swapFillerFor(s, si, cur, g, weekly, ctx);
          if (next) {
            cur[si] = next;
            improved = true;
            break;
          }
        }
        if (improved) break;
      }
      if (!improved) break;
    }
  }
  return cur;
}

/**
 * Frecuencia ≥ 2 por grupo (PROGRAMACION.md §2): si un grupo incluido en varias sesiones solo
 * recibe estímulo en una, añade un ejercicio corto donde falte (recortando series si hace falta).
 */
export function repairFrequency(sessions: DraftSession[], ctx: Ctx): DraftSession[] {
  const cur = sessions.slice();
  const thr = ctx.config.frequency.minEffectiveSetsToCount.value;
  const need = ctx.config.frequency.minPerGroup.value;
  for (const g of ctx.groups) {
    for (let guard = 0; guard < cur.length; guard++) {
      const aggs = cur.map((s) => aggregateSession(s, ctx));
      const count = aggs.filter((a) => (a.group.get(g) ?? 0) >= thr - 1e-9).length;
      if (count >= need) break;
      const missing = [...cur.keys()]
        .filter((i) => cur[i].template.groups.includes(g) && (aggs[i].group.get(g) ?? 0) < thr - 1e-9)
        .sort((a, b) => aggs[a].minutes - aggs[b].minutes || a - b);
      let fixed = false;
      for (const si of missing) {
        const s = cur[si];
        const others = cur.filter((_, i) => i !== si);
        const pc = pickContext(s, aggs[si], others, ctx);
        const deficits = new Map(pc.deficits);
        deficits.set(g, 3);
        const cands = ctx.eligible.filter(
          (e) => (e.groups.get(g) ?? 0) >= 1 && !ctx.config.balance.autoGenerationExcludedPatterns.value.includes(e.pattern),
        );
        const ex = bestCandidate(cands, null, 'accessory', { ...pc, deficits }, ctx);
        if (!ex) continue;
        const role: ExerciseRole = CORE_PATTERNS.has(ex.pattern) ? 'core' : 'accessory';
        const added: DraftSession = {
          ...s,
          items: [...s.items, { ex, sets: ctx.config.prescription.sets.min.value, role, slot: null, slotIndex: 150 }],
        };
        const fitted = fitToBudget(added, ctx);
        const agg = aggregateSession(fitted, ctx);
        if ((agg.group.get(g) ?? 0) >= thr - 1e-9 && sessionFeasible(agg, ctx)) {
          const all = cur.map((x, i) => (i === si ? agg : aggregateSession(x, ctx)));
          if (weeklyFeasible(all, ctx)) {
            cur[si] = fitted;
            fixed = true;
            break;
          }
        }
      }
      if (!fixed) break;
    }
  }
  return cur;
}

function swapFillerFor(
  s: DraftSession,
  si: number,
  all: readonly DraftSession[],
  g: VolumeGroup,
  weekly: ReadonlyMap<VolumeGroup, number>,
  ctx: Ctx,
): DraftSession | null {
  for (let i = s.items.length - 1; i >= 0; i--) {
    const it = s.items[i];
    if (it.slot || (it.ex.groups.get(g) ?? 0) > 0) continue;
    // Quitarlo no puede dejar otro grupo bajo su suelo.
    const safe = [...it.ex.groups].every(
      ([h, f]) => (weekly.get(h) ?? 0) - f * it.sets >= (ctx.floors.get(h) ?? 0) - 1e-9,
    );
    if (!safe) continue;
    const without: DraftSession = { ...s, items: s.items.filter((_, j) => j !== i) };
    const filled = fillDeficitsFor(without, si, all.map((x, j) => (j === si ? without : x)), g, ctx);
    if (filled) return filled;
  }
  return null;
}

function roleRank(r: ExerciseRole): number {
  return r === 'accessory' ? 3 : r === 'secondary' ? 2 : r === 'core' ? 1 : 0;
}

function accept(candidate: DraftSession, si: number, all: readonly DraftSession[], ctx: Ctx): boolean {
  const agg = aggregateSession(candidate, ctx);
  if (agg.minutes > ctx.budgetMinutes + 1e-9 || !sessionFeasible(agg, ctx)) return false;
  const aggs = all.map((s, i) => (i === si ? agg : aggregateSession(s, ctx)));
  return weeklyFeasible(aggs, ctx);
}

function fillDeficitsFor(
  s: DraftSession,
  si: number,
  all: readonly DraftSession[],
  g: VolumeGroup,
  ctx: Ctx,
): DraftSession | null {
  const others = all.filter((_, i) => i !== si);
  const agg = aggregateSession(s, ctx);
  const pc = pickContext(s, agg, others, ctx);
  const deficits = new Map(pc.deficits);
  deficits.set(g, Math.max(deficits.get(g) ?? 0, 3));
  const cands = ctx.eligible.filter(
    (e) =>
      (e.groups.get(g) ?? 0) >= 1 &&
      !pc.inSession.has(e.slug) &&
      !ctx.config.balance.autoGenerationExcludedPatterns.value.includes(e.pattern),
  );
  const sorted = cands
    .map((e) => [e, affinity(e, null, 'accessory', { ...pc, deficits }, ctx)] as const)
    .sort((a, b) => b[1] - a[1] || cmpStr(a[0].slug, b[0].slug));
  for (const [ex] of sorted.slice(0, 6)) {
    for (const sets of [ctx.config.prescription.sets.default.value, ctx.config.prescription.sets.min.value]) {
      const role: ExerciseRole = CORE_PATTERNS.has(ex.pattern) ? 'core' : 'accessory';
      const cand: DraftSession = { ...s, items: [...s.items, { ex, sets, role, slot: null, slotIndex: 300 + s.items.length }] };
      if (accept(cand, si, all, ctx)) return cand;
    }
  }
  return null;
}
