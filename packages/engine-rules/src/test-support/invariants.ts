/** Comprobación de los invariantes I1-I11 de docs/engine/INVARIANTES.md sobre un plan. */
import { engineV2 } from '@pipos/contracts';
import { PROGRAMMING, schemeGoal } from '../config/programming.js';
import { CATALOG } from './fixtures.js';

const LEVEL = { beginner: 0, intermediate: 1, advanced: 2 } as const;
const BY_SLUG = new Map(CATALOG.map((e) => [e.slug, e]));

export function assertPlanInvariants(input: engineV2.EngineProfileInput, plan: engineV2.PlanDraft): void {
  const profile = engineV2.EngineProfileSchema.parse(input);
  const fail = (msg: string) => {
    throw new Error(`${msg}\nperfil: ${JSON.stringify(input)}`);
  };
  engineV2.PlanDraftSchema.parse(plan);
  const have = new Set<string>([...profile.equipment, 'bodyweight']);
  const zones = new Set(profile.limitations);
  const warn = (code: string) => plan.warnings.filter((w) => w.code === code);
  const tol = PROGRAMMING.time.tolerancePct.value / 100;
  const priority = new Set(profile.priorityMuscles);
  const hyper = schemeGoal(profile.goal) === 'hypertrophy';

  if (plan.sessions.length !== profile.daysPerWeek) fail('número de sesiones ≠ días');
  for (const s of plan.sessions) {
    const seen = new Set<string>();
    let sawIsolation: string | null = null;
    let sawCore = false;
    for (const e of s.exercises) {
      const ex = BY_SLUG.get(e.exerciseId);
      if (!ex) return fail(`ejercicio desconocido ${e.exerciseId}`);
      // I1 material completo.
      if (!ex.equipment.every((q) => have.has(q))) fail(`I1 ${ex.slug} necesita ${ex.equipment.join('+')}`);
      // I2 limitaciones.
      if (ex.riskTags.some((r) => r.level === 'avoid' && zones.has(r.zone))) fail(`I2 ${ex.slug} vetado por limitación`);
      // I3 vetados y nivel.
      if (profile.bannedExerciseIds.includes(ex.slug)) fail(`I3 ${ex.slug} vetado`);
      if (LEVEL[ex.minLevel] > LEVEL[profile.level]) fail(`I3 ${ex.slug} nivel`);
      // I11 sin duplicados.
      if (seen.has(ex.slug)) fail(`I11 ${ex.slug} repetido en ${s.name}`);
      seen.add(ex.slug);
      // I10 prescripción válida.
      if (e.repMin > e.repMax || e.repMin < 1 || e.sets < 1 || e.sets > 10) fail(`I10 reps/series ${ex.slug}`);
      if (e.targetRir < 0 || e.targetRir > 5 || e.restSeconds < 60) fail(`I10 RIR/descanso ${ex.slug}`);
      if (ex.isCompound && e.targetRir < 1) fail(`I10 fallo en multiarticular ${ex.slug}`);
      // I7 orden: core al final; multiarticular nunca tras aislamiento salvo prioridad en hipertrofia.
      const isCore = e.role === 'core' || ex.movementPattern.startsWith('core_');
      if (sawCore && !isCore) fail(`I7 ${ex.slug} después del core en ${s.name}`);
      if (isCore) sawCore = true;
      else if (ex.isCompound && sawIsolation) fail(`I7 ${ex.slug} después del aislamiento ${sawIsolation} en ${s.name}`);
      else if (!ex.isCompound) {
        const prio = hyper && ex.muscles.some((m) => m.role === 'primary' && priority.has(m.muscle));
        if (!prio) sawIsolation = ex.slug;
      }
    }
    // I6 tiempo.
    if (s.estimatedMinutes > s.targetMinutes * (1 + tol) + 0.05) fail(`I6 ${s.name} ${s.estimatedMinutes} > ${s.targetMinutes}`);
    if (s.estimatedMinutes < s.targetMinutes * (1 - tol) && !warn('TIME_UNDERUSED').some((w) => w.data?.session === s.order)) {
      fail(`I6 ${s.name} corta sin aviso`);
    }
  }
  for (const v of plan.weeklyVolume) {
    // I4 suelo o aviso; I5 techo.
    if (v.effectiveSets < v.min && !warn('VOLUME_BELOW_FLOOR').some((w) => w.data?.group === v.group)) {
      fail(`I4 ${v.group} ${v.effectiveSets} < ${v.min} sin aviso`);
    }
    if (v.effectiveSets > v.max + 1e-9) fail(`I5 ${v.group} ${v.effectiveSets} > ${v.max}`);
    // I8 frecuencia o aviso.
    if (v.sessions < 2 && !warn('FREQUENCY_BELOW_MIN').some((w) => w.data?.group === v.group)) {
      fail(`I8 ${v.group} ${v.sessions} sesiones sin aviso`);
    }
  }
}
