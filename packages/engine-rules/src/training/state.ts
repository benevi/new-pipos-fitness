/**
 * Estado del plan en construcción, orden de ejercicios, modelo de tiempo y agregados por sesión.
 * Todo es puro y determinista.
 */
import type { engineV2 } from '@pipos/contracts';
import type { ProgrammingConfig } from '../config/programming.js';
import {
  cmpStr,
  CORE_PATTERNS,
  PULL_PATTERNS,
  PUSH_PATTERNS,
  type Ex,
  type ExerciseRole,
  type MovementPattern,
  type Muscle,
  type Profile,
  type VolumeGroup,
} from './model.js';
import { schemeFor, type Scheme } from './prescription.js';
import type { SessionTemplate, SlotSpec } from './split.js';

export interface DraftItem {
  readonly ex: Ex;
  readonly sets: number;
  readonly role: ExerciseRole;
  /** Hueco de la plantilla al que pertenece, o null si lo añadió el relleno. */
  readonly slot: SlotSpec | null;
  readonly slotIndex: number;
}

export interface DraftSession {
  readonly template: SessionTemplate;
  readonly dayIndex: number;
  readonly items: readonly DraftItem[];
}

export interface Ctx {
  readonly profile: Profile;
  readonly config: ProgrammingConfig;
  readonly eligible: readonly Ex[];
  readonly bySlug: ReadonlyMap<string, Ex>;
  readonly floors: ReadonlyMap<VolumeGroup, number>;
  readonly ceilings: ReadonlyMap<VolumeGroup, number>;
  readonly targets: ReadonlyMap<VolumeGroup, number>;
  readonly priorityGroups: ReadonlySet<VolumeGroup>;
  readonly priorityMuscles: ReadonlySet<Muscle>;
  readonly favourites: ReadonlySet<string>;
  readonly historySlugs: ReadonlySet<string>;
  readonly sessionsIncluding: ReadonlyMap<VolumeGroup, number>;
  readonly groups: readonly VolumeGroup[];
  /** Patrones semanales exigibles con el catálogo elegible (los demás generan aviso). */
  readonly requiredPatterns: readonly MovementPattern[];
  readonly budgetMinutes: number;
  readonly hypertrophyLike: boolean;
}

const ROLE_RANK: Record<ExerciseRole, number> = { main: 0, secondary: 1, accessory: 2, core: 3 };

/** ¿El ejercicio trabaja como primario un músculo prioritario? */
export function trainsPriority(ex: Ex, ctx: Ctx): boolean {
  for (const m of ex.primaryMuscles) if (ctx.priorityMuscles.has(m)) return true;
  return false;
}

/**
 * Orden de la sesión (PROGRAMACION.md §6): prioritario → multiarticular → aislamiento → core.
 * El aislamiento de un músculo prioritario puede ir primero solo en hipertrofia (Nunes 2021).
 */
export function orderItems(items: readonly DraftItem[], ctx: Ctx): DraftItem[] {
  // Solo UN aislamiento prioritario puede adelantarse, y solo si la sesión no tiene ya un
  // multiarticular que trabaje ese músculo como primario.
  let leadIsolation: DraftItem | null = null;
  if (ctx.hypertrophyLike && !items.some((it) => it.ex.src.isCompound && trainsPriority(it.ex, ctx))) {
    for (const it of items) {
      if (it.ex.src.isCompound || CORE_PATTERNS.has(it.ex.pattern) || !trainsPriority(it.ex, ctx)) continue;
      if (!leadIsolation || it.slotIndex < leadIsolation.slotIndex || (it.slotIndex === leadIsolation.slotIndex && cmpStr(it.ex.slug, leadIsolation.ex.slug) < 0)) {
        leadIsolation = it;
      }
    }
  }
  const key = (it: DraftItem): number[] => {
    const prio = (it.ex.src.isCompound && trainsPriority(it.ex, ctx)) || it === leadIsolation ? 0 : 1;
    const isCore = it.role === 'core' || CORE_PATTERNS.has(it.ex.pattern) ? 1 : 0;
    return [isCore, prio, it.ex.src.isCompound ? 0 : 1, ROLE_RANK[it.role], it.slotIndex];
  };
  return [...items].sort((a, b) => {
    const ka = key(a);
    const kb = key(b);
    for (let i = 0; i < ka.length; i++) if (ka[i] !== kb[i]) return ka[i] - kb[i];
    return cmpStr(a.ex.slug, b.ex.slug);
  });
}

export function warmupCountFor(it: DraftItem, isFirstHeavy: boolean, scheme: Scheme, ctx: Ctx): number {
  const w = ctx.config.prescription.warmup;
  if (isFirstHeavy) return ctx.profile.goal === 'strength' ? w.strengthGoalSets.value : w.heavyCompoundSets.value;
  // Resto de multiarticulares pesados (3-6 reps con carga): una serie de aproximación (§8, 0-1).
  if (scheme.kind === 'strength_main') return w.otherHeavySets.value;
  return it.ex.src.isCompound ? w.otherSets.value : 0;
}

export function isHeavyCandidate(it: DraftItem): boolean {
  return it.ex.src.isCompound && it.ex.weighted && (it.role === 'main' || it.role === 'secondary');
}

/** Segundos de un ejercicio (PROGRAMACION.md §8). */
export function exerciseSeconds(it: DraftItem, scheme: Scheme, warmups: number, config: ProgrammingConfig): number {
  const t = config.time;
  const avgReps = (scheme.repMin + scheme.repMax) / 2;
  const work = avgReps * t.secondsPerRep.value * (it.ex.src.isUnilateral ? t.unilateralFactor.value : 1);
  return (
    it.sets * (work + scheme.restSeconds) - scheme.restSeconds + warmups * t.warmupSetSeconds.value + t.transitionSeconds.value
  );
}

export interface SessionAgg {
  readonly ordered: DraftItem[];
  readonly schemes: Scheme[];
  readonly warmups: number[];
  readonly exerciseMinutes: number[];
  readonly minutes: number;
  readonly group: Map<VolumeGroup, number>;
  readonly muscle: Map<Muscle, number>;
  readonly patterns: Set<MovementPattern>;
  readonly push: number;
  readonly pull: number;
  readonly slugs: Set<string>;
  readonly redundant: number;
  readonly coreCount: number;
  readonly caution: number;
  readonly count: number;
}

export function aggregateSession(session: DraftSession, ctx: Ctx): SessionAgg {
  const ordered = orderItems(session.items, ctx);
  const schemes: Scheme[] = [];
  const warmups: number[] = [];
  const exerciseMinutes: number[] = [];
  const group = new Map<VolumeGroup, number>();
  const muscle = new Map<Muscle, number>();
  const patterns = new Set<MovementPattern>();
  const slugs = new Set<string>();
  const subGroups = new Map<string, number>();
  let push = 0;
  let pull = 0;
  let caution = 0;
  let coreCount = 0;
  let seconds = ctx.config.time.generalWarmupMin.value * 60;
  let heavyAssigned = false;
  for (const it of ordered) {
    const sc = schemeFor(it.ex, it.role, ctx.profile, ctx.config);
    const first = !heavyAssigned && isHeavyCandidate(it);
    if (first) heavyAssigned = true;
    const w = warmupCountFor(it, first, sc, ctx);
    const sec = exerciseSeconds(it, sc, w, ctx.config);
    schemes.push(sc);
    warmups.push(w);
    exerciseMinutes.push(sec / 60);
    seconds += sec;
    for (const [g, f] of it.ex.groups) group.set(g, (group.get(g) ?? 0) + it.sets * f);
    for (const [m, f] of it.ex.muscles) muscle.set(m, (muscle.get(m) ?? 0) + it.sets * f);
    patterns.add(it.ex.pattern);
    slugs.add(it.ex.slug);
    // Dos ejercicios del mismo grupo de sustitución solo se permiten para un músculo prioritario
    // (y como mucho dos): cuenta media unidad por cada uno prioritario.
    const sg = it.ex.src.substitutionGroup;
    subGroups.set(sg, (subGroups.get(sg) ?? 0) + (trainsPriority(it.ex, ctx) ? 0.5 : 1));
    if (PUSH_PATTERNS.has(it.ex.pattern)) push += it.sets;
    if (PULL_PATTERNS.has(it.ex.pattern)) pull += it.sets;
    if (it.ex.cautionZones.size > 0) caution += 1;
    if (CORE_PATTERNS.has(it.ex.pattern) && !trainsPriority(it.ex, ctx)) coreCount += 1;
  }
  let redundant = 0;
  for (const n of subGroups.values()) if (n > 1) redundant += Math.ceil(n - 1);
  return {
    ordered,
    schemes,
    warmups,
    exerciseMinutes,
    minutes: seconds / 60,
    group,
    muscle,
    patterns,
    push,
    pull,
    slugs,
    redundant,
    coreCount,
    caution,
    count: ordered.length,
  };
}

/** Restricciones duras por sesión que la búsqueda nunca puede violar. */
export function sessionFeasible(agg: SessionAgg, ctx: Ctx): boolean {
  const maxMin = ctx.budgetMinutes * (1 + ctx.config.time.tolerancePct.value / 100);
  if (agg.minutes > maxMin + 1e-9) return false;
  if (agg.slugs.size !== agg.count) return false;
  if (agg.redundant > 0) return false;
  if (agg.count > ctx.config.prescription.maxExercisesPerSession.value) return false;
  if (agg.coreCount > ctx.config.prescription.maxCoreExercisesPerSession.value) return false;
  const cap = ctx.config.volume.sessionMaxPerMuscle.value;
  for (const v of agg.muscle.values()) if (v > cap + 1e-9) return false;
  return true;
}

export function weeklyGroups(aggs: readonly SessionAgg[]): Map<VolumeGroup, number> {
  const out = new Map<VolumeGroup, number>();
  for (const a of aggs) for (const [g, v] of a.group) out.set(g, (out.get(g) ?? 0) + v);
  return out;
}

export function weeklyFeasible(aggs: readonly SessionAgg[], ctx: Ctx): boolean {
  const w = weeklyGroups(aggs);
  for (const [g, v] of w) if (v > (ctx.ceilings.get(g) ?? Infinity) + 1e-9) return false;
  return true;
}

export function groupSessionCount(aggs: readonly SessionAgg[], g: VolumeGroup, ctx: Ctx): number {
  const thr = ctx.config.frequency.minEffectiveSetsToCount.value;
  let n = 0;
  for (const a of aggs) if ((a.group.get(g) ?? 0) >= thr - 1e-9) n += 1;
  return n;
}

export type ScoreBreakdown = engineV2.ScoreBreakdown;

function clamp01(x: number): number {
  return x < 0 ? 0 : x > 1 ? 1 : x;
}

/** Función objetivo (PROGRAMACION.md §16.7). Cada componente está en [0, 1]. */
export function scorePlan(aggs: readonly SessionAgg[], ctx: Ctx): ScoreBreakdown {
  const w = ctx.config.scoring.weights.value;
  const weekly = weeklyGroups(aggs);

  // Cobertura: grupos sobre el suelo y patrones semanales presentes.
  let groupCov = 0;
  let fit = 0;
  let freq = 0;
  for (const g of ctx.groups) {
    const v = weekly.get(g) ?? 0;
    const floor = ctx.floors.get(g) ?? 0;
    const ceil = ctx.ceilings.get(g) ?? Infinity;
    groupCov += floor > 0 ? Math.min(1, v / floor) : 1;
    if (v < floor) fit += floor > 0 ? (v / floor) * 0.5 : 1;
    else if (v > ceil) fit += ceil / v;
    else if (ctx.priorityGroups.has(g)) fit += 0.5 + 0.5 * (ceil > floor ? (v - floor) / (ceil - floor) : 1);
    else fit += 1;
    freq += Math.min(1, groupSessionCount(aggs, g, ctx) / ctx.config.frequency.minPerGroup.value);
  }
  const nG = Math.max(1, ctx.groups.length);
  const present = new Set<MovementPattern>();
  for (const a of aggs) for (const p of a.patterns) present.add(CORE_PATTERNS.has(p) ? 'core_anti_extension' : p);
  const req = ctx.requiredPatterns;
  const patCov = req.length === 0 ? 1 : req.filter((p) => present.has(p)).length / req.length;
  const coverage = 0.6 * (groupCov / nG) + 0.4 * patCov;
  const volumeFit = fit / nG;
  const frequency = freq / nG;

  // Tiempo: penaliza pasarse (fuerte) y quedarse corto (suave), con tolerancia.
  const tol = ctx.config.time.tolerancePct.value / 100;
  let time = 0;
  for (const a of aggs) {
    const r = a.minutes / ctx.budgetMinutes;
    if (r > 1) time += clamp01(1 - (r - 1) * 5);
    else if (r < 1 - tol) time += clamp01(1 - (1 - tol - r));
    else time += 1;
  }
  const timeFit = aggs.length ? time / aggs.length : 0;

  // Balance tirón/empuje.
  let push = 0;
  let pull = 0;
  for (const a of aggs) {
    push += a.push;
    pull += a.pull;
  }
  const bMin = ctx.config.balance.pullPushRatioMin.value;
  const bMax = ctx.config.balance.pullPushRatioMax.value;
  let balance = 1;
  if (push > 0) {
    const r = pull / push;
    // Si la espalda ya está en su techo no se puede tirar más: no se castiga empujar (no se
    // recorta volumen de pecho solo para cuadrar el ratio).
    const pullCapped = (weekly.get('back') ?? 0) >= (ctx.ceilings.get('back') ?? Infinity) - 1;
    balance = r < bMin ? (pullCapped ? 1 : r / bMin) : r > bMax ? bMax / r : 1;
  }

  // Variedad: castiga redundancia dentro de la sesión y repetir el mismo ejercicio en la semana.
  let total = 0;
  let redundant = 0;
  const seen = new Map<string, number>();
  for (const a of aggs) {
    total += a.count;
    redundant += a.redundant;
    for (const s of a.slugs) seen.set(s, (seen.get(s) ?? 0) + 1);
  }
  let repeats = 0;
  for (const n of seen.values()) if (n > 1) repeats += n - 1;
  const variety = total === 0 ? 0 : clamp01(1 - (redundant * 0.5 + repeats * 0.15) / total);

  // Preferencias: favoritos incluidos y pocos ejercicios con precaución en zonas limitadas.
  let caution = 0;
  for (const a of aggs) caution += a.caution;
  const favEligible = [...ctx.favourites].filter((f) => ctx.bySlug.has(f));
  const favIn = favEligible.filter((f) => seen.has(f)).length;
  const favScore = favEligible.length === 0 ? 1 : favIn / favEligible.length;
  const cautionScore = total === 0 ? 1 : clamp01(1 - (caution / total) * ctx.config.scoring.cautionPenalty.value * 2);
  const preferences = 0.6 * favScore + 0.4 * cautionScore;

  const totalScore =
    w.coverage * coverage +
    w.volumeFit * volumeFit +
    w.timeFit * timeFit +
    w.frequency * frequency +
    w.balance * balance +
    w.variety * variety +
    w.preferences * preferences;
  return {
    total: clamp01(totalScore),
    coverage: clamp01(coverage),
    volumeFit: clamp01(volumeFit),
    timeFit: clamp01(timeFit),
    frequency: clamp01(frequency),
    balance: clamp01(balance),
    variety,
    preferences: clamp01(preferences),
  };
}
