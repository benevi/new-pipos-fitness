/**
 * generatePlan(profile, catalog, config) → PlanDraft (PLAN §3).
 * validar → filtrar → split → volumen → solución por reglas → prescripción → scoring
 * → explicaciones. Función pura y determinista.
 */
import { engineV2 } from '@pipos/contracts';
import { ENGINE_VERSION, PROGRAMMING, schemeGoal, type ProgrammingConfig } from '../config/programming.js';
import { buildInitial, type UnfilledSlot } from './construct.js';
import { exclusionReason, filterCatalog, type ExclusionReason } from './filter.js';
import {
  EQUIPMENT_ES,
  GOAL_ES,
  GROUP_ES,
  LEVEL_ES,
  MUSCLE_ES,
  PATTERN_ES,
  ZONE_ES,
  fmt,
  list,
} from './labels.js';
import { cmpStr, CORE_PATTERNS, round1, type Ex, type MovementPattern, type Profile, type VolumeGroup } from './model.js';
import { initialLoad, warmupSets } from './prescription.js';
import { chooseSplit, sessionsPerGroup } from './split.js';
import {
  aggregateSession,
  groupSessionCount,
  scorePlan,

  weeklyGroups,
  type Ctx,
  type DraftSession,
  type SessionAgg,
} from './state.js';

export interface GenerateOptions {
  config?: ProgrammingConfig;
}

type Warning = engineV2.EngineWarning;

function issuesOf(err: { issues: { path: (string | number)[]; message: string }[] }) {
  return err.issues.map((i) => ({ path: i.path.join('.'), message: i.message }));
}

export function generatePlan(
  profileInput: unknown,
  catalogInput: unknown,
  options: GenerateOptions = {},
): engineV2.GeneratePlanResult {
  const config = options.config ?? PROGRAMMING;
  // 1. Validar (nunca valores por defecto).
  const pp = engineV2.EngineProfileSchema.safeParse(profileInput);
  if (!pp.success) {
    return { ok: false, error: { code: 'INVALID_PROFILE', message: 'Perfil inválido', issues: issuesOf(pp.error) } };
  }
  const cp = engineV2.CatalogSchema.safeParse(catalogInput);
  if (!cp.success) {
    return { ok: false, error: { code: 'INVALID_CATALOG', message: 'Catálogo inválido', issues: issuesOf(cp.error) } };
  }
  const profile: Profile = { ...pp.data, equipment: [...new Set(pp.data.equipment)].sort(cmpStr) };
  // Orden canónico: nada de lo que sigue puede depender del orden en que llega el catálogo (I9).
  const catalog = [...cp.data].sort((a, b) => cmpStr(a.slug, b.slug));

  // 2. Restricciones duras.
  const { eligible, excluded } = filterCatalog(catalog, profile, config);
  const usable = eligible.filter((e) => !config.balance.autoGenerationExcludedPatterns.value.includes(e.pattern));
  if (usable.length === 0) {
    return {
      ok: false,
      error: {
        code: 'NO_EXERCISES',
        message: 'Ningún ejercicio del catálogo cumple tu material, nivel y limitaciones',
        issues: [],
      },
    };
  }

  // 3. Split.
  const split = chooseSplit(profile, config);
  const including = sessionsPerGroup(split.templates);

  // 4. Volumen objetivo por grupo.
  const groups = engineV2.VOLUME_GROUPS;
  const priorityMuscles = new Set(profile.priorityMuscles);
  const priorityGroups = new Set<VolumeGroup>();
  for (const m of priorityMuscles) {
    const g = config.volume.groupOfMuscle.value[m];
    if (g) priorityGroups.add(g);
  }
  const floors = new Map<VolumeGroup, number>();
  const ceilings = new Map<VolumeGroup, number>();
  const targets = new Map<VolumeGroup, number>();
  const vmin = config.volume.lowVolumeGoals.value.includes(profile.goal)
    ? Math.min(config.volume.weeklyMin[profile.level].value, config.volume.weeklyMin.beginner.value)
    : config.volume.weeklyMin[profile.level].value;
  const vmax = config.volume.weeklyMax[profile.level].value;
  for (const g of groups) {
    const prio = priorityGroups.has(g);
    const ceil = prio && profile.level === 'advanced' ? config.volume.weeklyMaxPriorityAdvanced.value : vmax;
    floors.set(g, vmin);
    ceilings.set(g, ceil);
    targets.set(g, prio ? ceil : vmin);
  }
  const present = new Set(usable.map((e) => (CORE_PATTERNS.has(e.pattern) ? 'core_anti_extension' : e.pattern)));
  const weeklyPatterns = config.balance.weeklyPatterns.value;
  const requiredPatterns = weeklyPatterns.filter((p) => present.has(p));

  const ctx: Ctx = {
    profile,
    config,
    eligible: usable,
    bySlug: new Map(usable.map((e) => [e.slug, e])),
    floors,
    ceilings,
    targets,
    priorityGroups,
    priorityMuscles,
    favourites: new Set(profile.favouriteExerciseIds),
    historySlugs: new Set((profile.history?.entries ?? []).map((e) => e.exerciseId)),
    sessionsIncluding: including,
    groups,
    requiredPatterns,
    budgetMinutes: profile.minutesPerSession,
    hypertrophyLike: schemeGoal(profile.goal, config) === 'hypertrophy',
  };

  // 5. Solución inicial.
  const skeleton: DraftSession[] = split.templates.map((t, i) => ({
    template: t,
    dayIndex: split.dayIndexes[i] ?? i,
    items: [],
  }));
  const initial = buildInitial(skeleton, ctx);

  const aggs = initial.sessions.map((s) => aggregateSession(s, ctx));
  const score = scorePlan(aggs, ctx);

  // 6 + 8. Prescripción final y explicaciones.
  const warnings = buildWarnings(ctx, aggs, initial.unfilled, catalog, excluded, weeklyPatterns, present);
  const sessions = initial.sessions.map((s, i) => renderSession(s, aggs[i], i, ctx));
  const weekly = weeklyGroups(aggs);
  const weeklyVolume: engineV2.GroupVolume[] = groups.map((g) => {
    const v = round1(weekly.get(g) ?? 0);
    const min = floors.get(g) ?? 0;
    const max = ceilings.get(g) ?? 0;
    return {
      group: g,
      effectiveSets: v,
      min,
      max,
      sessions: groupSessionCount(aggs, g, ctx),
      isPriority: priorityGroups.has(g),
      status: v < min - 1e-9 ? 'below' : v > max + 1e-9 ? 'above' : 'within',
    };
  });
  const muscleTotals = new Map<engineV2.Muscle, number>();
  for (const a of aggs) for (const [m, v] of a.muscle) muscleTotals.set(m, (muscleTotals.get(m) ?? 0) + v);
  const muscleVolume = engineV2.MUSCLES.filter((m) => muscleTotals.has(m)).map((m) => ({
    muscle: m,
    effectiveSets: round1(muscleTotals.get(m) ?? 0),
  }));

  const plan: engineV2.PlanDraft = {
    engineVersion: ENGINE_VERSION,
    split: { type: split.type, rationale: split.rationale },
    mesocycleWeeks: config.plan.mesocycleWeeks.value,
    sessions,
    weeklyVolume,
    muscleVolume,
    warnings,
    rationale: planRationale(ctx, weeklyVolume),
    healthNotes: planHealthNotes(ctx),
    score: roundScore(score),
    meta: {
      catalogSize: catalog.length,
      eligibleExercises: usable.length,
    },
  };
  return { ok: true, plan };
}

function roundScore(s: engineV2.ScoreBreakdown): engineV2.ScoreBreakdown {
  const r = (x: number) => Math.round(x * 1e4) / 1e4;
  return {
    total: r(s.total),
    coverage: r(s.coverage),
    volumeFit: r(s.volumeFit),
    timeFit: r(s.timeFit),
    frequency: r(s.frequency),
    balance: r(s.balance),
    variety: r(s.variety),
    preferences: r(s.preferences),
  };
}

function renderSession(s: DraftSession, agg: SessionAgg, order: number, ctx: Ctx): engineV2.PlannedSession {
  const exercises: engineV2.PlannedExercise[] = agg.ordered.map((it, i) => {
    const sc = agg.schemes[i];
    const load = initialLoad(it.ex, sc, ctx.profile, ctx.config);
    const w = agg.warmups[i];
    const warm = it.ex.weighted ? warmupSets(w, load.loadKg, ctx.config) : [];
    return {
      order: i,
      exerciseId: it.ex.slug,
      nameEs: it.ex.src.nameEs,
      movementPattern: it.ex.pattern,
      isCompound: it.ex.src.isCompound,
      role: it.role,
      sets: it.sets,
      repMin: sc.repMin,
      repMax: sc.repMax,
      targetRir: sc.rir,
      restSeconds: sc.restSeconds,
      loadType: it.ex.weighted ? 'weighted' : 'unweighted',
      initialLoadKg: load.loadKg,
      initialLoadIsEstimate: load.isEstimate,
      warmupSets: warm,
      estimatedMinutes: round1(agg.exerciseMinutes[i]),
      rationale: exerciseRationale(it.ex, it.role, i, sc, load.note, warm.length, ctx),
      healthNotes: [...it.ex.cautionZones].map(
        (z) => `Precaución por tu limitación de ${ZONE_ES[z]}: usa un rango cómodo y para si aparece dolor.`,
      ),
    };
  });
  const groupsTrained = s.template.groups.map((g) => GROUP_ES[g]);
  const est = round1(agg.minutes);
  const rationale = [
    `${s.template.name}: trabaja ${list(groupsTrained)}; ${fmt(est)} min estimados de tus ${ctx.budgetMinutes} (incluye ${ctx.config.time.generalWarmupMin.value} min de calentamiento general).`,
  ];
  if (est < ctx.budgetMinutes * (1 - ctx.config.time.tolerancePct.value / 100)) {
    rationale.push('Queda algo de tiempo libre porque añadir más series superaría el volumen útil para tu nivel.');
  }
  return {
    order,
    dayIndex: s.dayIndex,
    kind: s.template.kind,
    name: s.template.name,
    targetMinutes: ctx.budgetMinutes,
    estimatedMinutes: est,
    exercises,
    rationale,
  };
}

function exerciseRationale(
  ex: Ex,
  role: engineV2.ExerciseRole,
  index: number,
  sc: { repMin: number; repMax: number; rir: number; restSeconds: number; kind: string },
  loadNote: string,
  warmups: number,
  ctx: Ctx,
): string[] {
  const out: string[] = [];
  const p = ctx.profile;
  if (ctx.favourites.has(ex.slug)) out.push('Lo incluimos porque lo marcaste como favorito.');
  const prio = [...ex.primaryMuscles].filter((m) => ctx.priorityMuscles.has(m));
  if (prio.length > 0) {
    out.push(
      index === 0
        ? `Va primero porque ${list(prio.map((m) => MUSCLE_ES[m]))} es prioridad para ti: el primer ejercicio acumula más volumen (Simão 2012).`
        : `Trabaja ${list(prio.map((m) => MUSCLE_ES[m]))}, tu músculo prioritario.`,
    );
  } else if (role === 'main' && ex.src.isCompound) {
    out.push(
      p.goal === 'strength'
        ? `Multiarticular principal al inicio de la sesión: la fuerza mejora más en los ejercicios que se hacen primero (Nunes 2021; ACSM 2026).`
        : `Multiarticular de ${PATTERN_ES[ex.pattern]} al inicio, cuando estás más fresco.`,
    );
  } else if (!ex.src.isCompound && !CORE_PATTERNS.has(ex.pattern)) {
    const gs = [...ex.groups].filter(([, f]) => f >= 1).map(([g]) => GROUP_ES[g]);
    out.push(`Aislamiento para sumar volumen directo de ${list(gs)}.`);
  } else if (CORE_PATTERNS.has(ex.pattern)) {
    out.push('Core al final para no fatigar el tronco antes de los ejercicios pesados.');
  }
  const goalTxt = GOAL_ES[p.goal];
  if (sc.kind === 'strength_main') {
    out.push(`${sc.repMin}-${sc.repMax} reps a RIR ${sc.rir} y ${sc.restSeconds / 60} min de descanso: cargas altas (≥80 % 1RM) para tu objetivo de fuerza.`);
  } else if (p.level === 'beginner') {
    out.push(
      `${sc.repMin}-${sc.repMax} reps dejando ${sc.rir} en reserva: como ${LEVEL_ES[p.level]} conviene empezar conservador porque el RIR se calibra con la práctica (Zourdos 2016).`,
    );
  } else {
    out.push(`${sc.repMin}-${sc.repMax} reps a RIR ${sc.rir}, descanso ${sc.restSeconds} s, según tu objetivo de ${goalTxt}.`);
  }
  if (warmups > 0) out.push(`${warmups} series de aproximación antes de las series efectivas.`);
  out.push(loadNote);
  // Las precauciones por limitación (datos de salud) van en `healthNotes`, no aquí.
  return out;
}

const GOAL_RATIONALE: Record<engineV2.TrainingGoal, string> = {
  strength:
    'Fuerza: los multiarticulares principales van a 3-6 repeticiones con cargas altas (≥80 % 1RM) y 3 min de descanso; el resto, a 6-12 (ACSM 2026; Schoenfeld 2017).',
  hypertrophy:
    'Hipertrofia: 8-12 repeticiones en multiarticulares y 10-15 en aislamiento, cerca del fallo pero sin llegar en los ejercicios pesados (Schoenfeld 2017; Robinson 2024).',
  fat_loss:
    'Pérdida de grasa: se entrena como para hipertrofia para conservar el músculo; el déficit lo marcan tus objetivos nutricionales, no el entrenamiento.',
  muscular_endurance: 'Resistencia muscular: 15-25 repeticiones con cargas ligeras y descansos cortos de 60 s.',
  general_health:
    'Salud general: 8-12 repeticiones dejando margen (RIR 2-3) y hasta 3 series por ejercicio, con todos los grupos principales 2 veces por semana (OMS 2020; ACSM 2009).',
};

function planRationale(ctx: Ctx, vol: engineV2.GroupVolume[]): string[] {
  const p = ctx.profile;
  const out: string[] = [];
  const equipmentText =
    p.equipment.length >= 10
      ? 'material de gimnasio completo'
      : list(p.equipment.length ? p.equipment.map((e) => EQUIPMENT_ES[e]) : ['tu peso corporal']);
  out.push(
    `Plan para ${GOAL_ES[p.goal]}, nivel ${LEVEL_ES[p.level]}, ${p.daysPerWeek} días de ${p.minutesPerSession} min con ${equipmentText}.`,
  );
  out.push(GOAL_RATIONALE[p.goal]);
  const vmin = vol[0]?.min ?? 0;
  const vmax = ctx.config.volume.weeklyMax[p.level].value;
  out.push(
    `Volumen objetivo: ${vmin}-${vmax} series efectivas por grupo y semana para tu nivel; los músculos secundarios cuentan media serie (Pelland 2026).`,
  );
  if (ctx.config.volume.lowVolumeGoals.value.includes(p.goal) && vmin < ctx.config.volume.weeklyMin[p.level].value) {
    out.push(
      `Para ${GOAL_ES[p.goal]} basta con un volumen bajo o moderado (en fuerza los rendimientos decrecientes llegan antes), así que el mínimo baja a ${vmin} series; si sobra tiempo se sube hacia el rango alto.`,
    );
  }
  if (ctx.priorityMuscles.size > 0) {
    out.push(
      `Prioridad en ${list([...ctx.priorityMuscles].map((m) => MUSCLE_ES[m]))}: su volumen se lleva a la parte alta del rango y sus ejercicios van antes.`,
    );
  }
  const below = vol.filter((v) => v.status === 'below').map((v) => GROUP_ES[v.group]);
  if (below.length === 0) out.push('Todos los grupos musculares llegan al mínimo de volumen semanal.');
  else {
    out.push(
      `Con ${p.daysPerWeek} días de ${p.minutesPerSession} min y este material, ${list(below)} no llegan al mínimo de volumen: el plan cumple igualmente el mínimo de salud de entrenar fuerza ≥ 2 días por semana (OMS 2020), y los avisos dicen qué añadir para completarlo.`,
    );
  }
  out.push(
    `Cada ${ctx.config.plan.mesocycleWeeks.value} semanas toca una semana de descarga (menos series y más RIR), o antes si el rendimiento cae dos sesiones seguidas.`,
  );
  return out;
}

/** Explicación del plan derivada de las limitaciones (datos de salud, art. 9 RGPD). */
function planHealthNotes(ctx: Ctx): string[] {
  const p = ctx.profile;
  if (p.limitations.length === 0) return [];
  return [
    `Por tu limitación de ${list(p.limitations.map((z) => ZONE_ES[z]))} se excluyen los ejercicios de riesgo alto para esa zona y se marcan con precaución los de riesgo moderado.`,
  ];
}

function suggestEquipment(
  pattern: MovementPattern,
  catalog: readonly engineV2.CatalogExercise[],
  profile: Profile,
): string[] {
  const options = new Set<string>();
  const have = new Set([...profile.equipment, 'bodyweight']);
  for (const ex of catalog) {
    if (ex.movementPattern !== pattern) continue;
    const r = exclusionReason(ex, { ...profile, equipment: [...engineV2.EQUIPMENT] });
    if (r) continue;
    const missing = ex.equipment.filter((e) => !have.has(e));
    if (missing.length === 1) options.add(missing[0]);
  }
  const rank = (e: string) => {
    const i = PORTABILITY.indexOf(e as engineV2.Equipment);
    return i < 0 ? PORTABILITY.length : i;
  };
  return [...options].sort((a, b) => rank(a) - rank(b) || cmpStr(a, b)).slice(0, 3);
}

/** Orden de sugerencia de material: primero lo barato y fácil de tener en casa. */
const PORTABILITY: readonly engineV2.Equipment[] = [
  'resistance_band',
  'pull_up_bar',
  'dumbbell',
  'bench',
  'suspension_trainer',
  'gymnastic_rings',
  'kettlebell',
  'plyo_box',
  'ez_bar',
  'barbell',
  'squat_rack',
  'trap_bar',
  'dip_station',
  'cable',
  'machine',
  'smith_machine',
];

function buildWarnings(
  ctx: Ctx,
  aggs: readonly SessionAgg[],
  unfilled: readonly UnfilledSlot[],
  catalog: readonly engineV2.CatalogExercise[],
  excluded: ReadonlyMap<string, ExclusionReason>,
  weeklyPatterns: readonly MovementPattern[],
  presentPatterns: ReadonlySet<MovementPattern>,
): Warning[] {
  const out: Warning[] = [];
  const p = ctx.profile;
  // Patrones sin cobertura (semanales o de huecos de plantilla).
  const uncovered = new Set<MovementPattern>();
  for (const pat of weeklyPatterns) if (!presentPatterns.has(pat)) uncovered.add(pat);
  for (const u of unfilled) for (const pat of u.slot.patterns) if (!presentPatterns.has(pat)) uncovered.add(pat);
  const inPlan = new Set<MovementPattern>();
  for (const a of aggs) for (const pat of a.patterns) inPlan.add(pat);
  for (const pat of [...uncovered].sort(cmpStr)) {
    if (CORE_PATTERNS.has(pat) && [...inPlan].some((x) => CORE_PATTERNS.has(x))) continue;
    // Causa: la limitación (o el nivel) si, sin ella, habría alguna variante disponible.
    const variants = catalog.filter((ex) => ex.movementPattern === pat);
    const levelVariant = variants.find((ex) => !exclusionReason(ex, { ...p, level: 'advanced' }));
    const reason: 'limitation' | 'level' | 'equipment' =
      p.limitations.length > 0 && variants.some((ex) => !exclusionReason(ex, { ...p, limitations: [] }))
        ? 'limitation'
        : levelVariant
          ? 'level'
          : 'equipment';
    const sugg = reason === 'equipment' ? suggestEquipment(pat, catalog, p) : [];
    const why =
      reason === 'limitation'
        ? `tus limitaciones (${list(p.limitations.map((z) => ZONE_ES[z]))}) excluyen todas las variantes`
        : reason === 'level'
          ? `las variantes posibles con tu material piden más nivel (p. ej., ${levelVariant?.nameEs.toLowerCase()})`
          : 'tu material no permite ninguna variante segura';
    out.push({
      code: 'PATTERN_UNCOVERED',
      message: `No hay ejercicios de ${PATTERN_ES[pat]}: ${why}.${
        sugg.length ? ` Con ${list(sugg.map((e) => EQUIPMENT_ES[e as engineV2.Equipment]))} se cubriría.` : ''
      }`,
      data: { pattern: pat, reason, suggestedEquipment: sugg },
      ...(reason === 'limitation' ? { health: true } : {}),
    });
  }
  const weekly = weeklyGroups(aggs);
  for (const g of ctx.groups) {
    const v = weekly.get(g) ?? 0;
    const floor = ctx.floors.get(g) ?? 0;
    if (v < floor - 1e-9) {
      out.push({
        code: 'VOLUME_BELOW_FLOOR',
        message: `${GROUP_ES[g]}: ${fmt(round1(v))} series efectivas/semana, por debajo del mínimo de ${floor} para tu nivel (falta tiempo o material para más).`,
        data: { group: g, effectiveSets: round1(v), min: floor },
      });
    }
    const n = groupSessionCount(aggs, g, ctx);
    if (n < ctx.config.frequency.minPerGroup.value) {
      out.push({
        code: 'FREQUENCY_BELOW_MIN',
        message: `${GROUP_ES[g]} se trabaja ${n} ${n === 1 ? 'vez' : 'veces'} por semana; lo recomendado es al menos ${ctx.config.frequency.minPerGroup.value}.`,
        data: { group: g, sessions: n },
      });
    }
  }
  const tol = ctx.config.time.tolerancePct.value / 100;
  aggs.forEach((a, i) => {
    // Se compara con la cifra redondeada que ve el usuario.
    const minutes = round1(a.minutes);
    if (minutes < ctx.budgetMinutes * (1 - tol)) {
      out.push({
        code: 'TIME_UNDERUSED',
        message: `La sesión ${i + 1} dura unos ${fmt(minutes)} min de tus ${ctx.budgetMinutes}: más series superarían el volumen útil o no hay más ejercicios adecuados.`,
        data: { session: i, minutes: round1(a.minutes) },
      });
    } else if (minutes > ctx.budgetMinutes) {
      out.push({
        code: 'TIME_OVER_BUDGET',
        message: `La sesión ${i + 1} se estima en ${fmt(minutes)} min, algo por encima de tus ${ctx.budgetMinutes} (dentro de la tolerancia del ${ctx.config.time.tolerancePct.value} %).`,
        data: { session: i, minutes: round1(a.minutes) },
      });
    }
  });
  for (const m of [...ctx.priorityMuscles].sort(cmpStr)) {
    const has = aggs.some((a) => a.ordered.some((it) => it.ex.primaryMuscles.has(m)));
    if (!has) {
      out.push({
        code: 'PRIORITY_UNCOVERED',
        message: `No hay ningún ejercicio disponible que trabaje ${MUSCLE_ES[m]} como músculo principal con tu material y limitaciones.`,
        data: { muscle: m },
      });
    }
  }
  let push = 0;
  let pull = 0;
  for (const a of aggs) {
    push += a.push;
    pull += a.pull;
  }
  const bMin = ctx.config.balance.pullPushRatioMin.value;
  const bMax = ctx.config.balance.pullPushRatioMax.value;
  const backCapped = (weekly.get('back') ?? 0) >= (ctx.ceilings.get('back') ?? Infinity) - 1;
  if (push > 0) {
    const r = pull / push;
    if ((r < bMin - 1e-9 && !backCapped) || r > bMax + 1e-9) {
      out.push({
        code: 'PUSH_PULL_IMBALANCE',
        message: `Relación tirón/empuje de ${fmt(Math.round(r * 100) / 100)} (${pull} series de tirón y ${push} de empuje); lo orientativo es ${fmt(bMin)}-${fmt(bMax)}.`,
        data: { ratio: Math.round(r * 100) / 100, pullSets: pull, pushSets: push },
      });
    }
  }
  const [, gMax] = ctx.config.frequency.daysGuide[p.level].value;
  if (p.daysPerWeek > gMax) {
    out.push({
      code: 'DAYS_ABOVE_LEVEL_GUIDE',
      message: `Como ${LEVEL_ES[p.level]}, ${p.daysPerWeek} días superan la guía orientativa de hasta ${gMax}; es válido, pero prioriza la recuperación.`,
      data: { days: p.daysPerWeek, guideMax: gMax },
    });
  }
  for (const fav of [...ctx.favourites].sort(cmpStr)) {
    const reason = excluded.get(fav);
    if (reason) {
      const txt: Record<ExclusionReason, string> = {
        equipment: 'necesita material que no tienes',
        limitation: 'es de riesgo para una zona que tienes limitada',
        banned: 'también está en tu lista de vetados',
        level: 'requiere un nivel más alto',
      };
      out.push({
        code: 'FAVOURITE_EXCLUDED',
        message: `Tu favorito «${fav}» no se incluye porque ${txt[reason]}.`,
        data: { exerciseId: fav, reason },
        ...(reason === 'limitation' ? { health: true } : {}),
      });
    }
  }
  return out;
}
