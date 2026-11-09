/**
 * Genera docs/engine/ejemplos/*.md: 10 perfiles variados con su plan explicado.
 * Uso: pnpm --filter @pipos/engine-rules examples
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import type { engineV2 } from '@pipos/contracts';
import { GOAL_ES, GROUP_ES, LEVEL_ES, ZONE_ES, EQUIPMENT_ES, MUSCLE_ES } from '../src/training/labels.js';
import { generatePlan } from '../src/training/index.js';
import { CATALOG, FULL_GYM, longHistory } from '../src/test-support/fixtures.js';

const OUT = resolve(__dirname, '../../../docs/engine/ejemplos');

interface Example {
  file: string;
  title: string;
  profile: engineV2.EngineProfileInput;
}

const intermediateHistory: engineV2.TrainingHistory = {
  entries: longHistory().entries.filter((e) => e.date >= '2026-10-01'),
};

const EXAMPLES: Example[] = [
  {
    file: '01-principiante-salud-2dias-casa.md',
    title: 'Principiante, salud general, 2 días × 30 min, sin material',
    profile: { goal: 'general_health', level: 'beginner', daysPerWeek: 2, minutesPerSession: 30, equipment: [] },
  },
  {
    file: '02-principiante-hipertrofia-3dias-mancuernas.md',
    title: 'Principiante, hipertrofia, 3 días × 45 min, mancuernas y banco en casa',
    profile: { goal: 'hypertrophy', level: 'beginner', daysPerWeek: 3, minutesPerSession: 45, equipment: ['dumbbell', 'bench'] },
  },
  {
    file: '03-intermedio-hipertrofia-4dias-gimnasio-gluteos.md',
    title: 'Intermedio, hipertrofia, 4 días × 60 min, gimnasio, prioridad glúteos',
    profile: {
      goal: 'hypertrophy',
      level: 'intermediate',
      daysPerWeek: 4,
      minutesPerSession: 60,
      equipment: FULL_GYM,
      priorityMuscles: ['glutes'],
      favouriteExerciseIds: ['hip-thrust-barra'],
    },
  },
  {
    file: '04-intermedio-fuerza-3dias-gimnasio-historial.md',
    title: 'Intermedio, fuerza, 3 días × 75 min, gimnasio, con historial',
    profile: {
      goal: 'strength',
      level: 'intermediate',
      daysPerWeek: 3,
      minutesPerSession: 75,
      equipment: FULL_GYM,
      history: intermediateHistory,
    },
  },
  {
    file: '05-avanzado-fuerza-4dias-gimnasio-historial-largo.md',
    title: 'Avanzado, fuerza, 4 días × 90 min, gimnasio, historial largo',
    profile: { goal: 'strength', level: 'advanced', daysPerWeek: 4, minutesPerSession: 90, equipment: FULL_GYM, history: longHistory() },
  },
  {
    file: '06-avanzado-hipertrofia-6dias-gimnasio-hombros-biceps.md',
    title: 'Avanzado, hipertrofia, 6 días × 90 min, gimnasio, prioridad deltoides lateral y bíceps',
    profile: {
      goal: 'hypertrophy',
      level: 'advanced',
      daysPerWeek: 6,
      minutesPerSession: 90,
      equipment: FULL_GYM,
      priorityMuscles: ['side_delts', 'biceps'],
    },
  },
  {
    file: '07-intermedio-perdida-grasa-5dias-gimnasio-hombro.md',
    title: 'Intermedio, pérdida de grasa, 5 días × 45 min, gimnasio, lesión de hombro',
    profile: {
      goal: 'fat_loss',
      level: 'intermediate',
      daysPerWeek: 5,
      minutesPerSession: 45,
      equipment: FULL_GYM,
      limitations: ['shoulder'],
      bannedExerciseIds: ['peso-muerto-barra'],
    },
  },
  {
    file: '08-principiante-resistencia-3dias-bandas.md',
    title: 'Principiante, resistencia muscular, 3 días × 40 min, bandas y barra de dominadas',
    profile: {
      goal: 'muscular_endurance',
      level: 'beginner',
      daysPerWeek: 3,
      minutesPerSession: 40,
      equipment: ['resistance_band', 'pull_up_bar'],
    },
  },
  {
    file: '09-intermedio-hipertrofia-4dias-casa-rodilla.md',
    title: 'Intermedio, hipertrofia, 4 días × 50 min, casa (mancuernas, banco, banda), lesión de rodilla',
    profile: {
      goal: 'hypertrophy',
      level: 'intermediate',
      daysPerWeek: 4,
      minutesPerSession: 50,
      equipment: ['dumbbell', 'bench', 'resistance_band'],
      limitations: ['knee'],
    },
  },
  {
    file: '10-avanzado-salud-2dias-kettlebell-trx.md',
    title: 'Avanzado, salud general, 2 días × 60 min, kettlebell, TRX y bandas',
    profile: {
      goal: 'general_health',
      level: 'advanced',
      daysPerWeek: 2,
      minutesPerSession: 60,
      equipment: ['kettlebell', 'suspension_trainer', 'resistance_band'],
      limitations: ['lumbar'],
    },
  },
];

const DAY_ES = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

function inputSummary(p: engineV2.EngineProfileInput): string {
  const eq = p.equipment.length ? p.equipment.map((e) => EQUIPMENT_ES[e]).join(', ') : 'solo peso corporal';
  const lines = [
    `- Objetivo: **${GOAL_ES[p.goal]}** · nivel **${LEVEL_ES[p.level]}**`,
    `- ${p.daysPerWeek} días por semana, ${p.minutesPerSession} min por sesión`,
    `- Material: ${eq}`,
    `- Limitaciones: ${p.limitations?.length ? p.limitations.map((z) => ZONE_ES[z]).join(', ') : 'ninguna'}`,
    `- Músculos prioritarios: ${p.priorityMuscles?.length ? p.priorityMuscles.map((m) => MUSCLE_ES[m]).join(', ') : 'ninguno'}`,
  ];
  if (p.favouriteExerciseIds?.length) lines.push(`- Favoritos: ${p.favouriteExerciseIds.join(', ')}`);
  if (p.bannedExerciseIds?.length) lines.push(`- Vetados: ${p.bannedExerciseIds.join(', ')}`);
  if (p.history) lines.push(`- Historial: ${p.history.entries.length} registros de sesión`);
  return lines.join('\n');
}

function render(ex: Example, plan: engineV2.PlanDraft): string {
  const out: string[] = [];
  out.push(`# ${ex.title}`, '', `> Generado por \`pnpm --filter @pipos/engine-rules examples\` con el motor ${plan.engineVersion}. No editar a mano.`, '');
  out.push('## Entrada', '', inputSummary(ex.profile), '');
  const { history, ...visible } = ex.profile;
  out.push('<details><summary>JSON del perfil</summary>', '', '```json', JSON.stringify(history ? { ...visible, history: `(${history.entries.length} registros)` } : visible, null, 2), '```', '', '</details>', '');
  out.push(`## Split: ${plan.split.type}`, '', ...plan.split.rationale.map((r) => `- ${r}`), '');
  out.push('## Sesiones', '');
  for (const s of plan.sessions) {
    out.push(`### ${s.order + 1}. ${s.name} (${DAY_ES[s.dayIndex]}) — ${s.estimatedMinutes} / ${s.targetMinutes} min`, '');
    out.push('| # | Ejercicio | Series | Reps | RIR | Descanso | Carga inicial | Aprox. | Min |', '|---|---|---|---|---|---|---|---|---|');
    for (const e of s.exercises) {
      const load = e.loadType === 'unweighted' ? 'sin kg' : e.initialLoadKg === null ? 'a elegir' : `${e.initialLoadKg} kg${e.initialLoadIsEstimate ? ' (est.)' : ''}`;
      const warm = e.warmupSets.length ? e.warmupSets.map((w) => `${w.reps}@${w.loadPct}%`).join(' ') : '—';
      out.push(`| ${e.order + 1} | ${e.nameEs} | ${e.sets} | ${e.repMin}-${e.repMax} | ${e.targetRir} | ${e.restSeconds} s | ${load} | ${warm} | ${e.estimatedMinutes} |`);
    }
    out.push('', ...s.rationale.map((r) => `- ${r}`), '');
    out.push('<details><summary>Por qué cada ejercicio</summary>', '');
    for (const e of s.exercises) out.push(`- **${e.nameEs}**: ${e.rationale.join(' ')}`);
    out.push('', '</details>', '');
  }
  out.push('## Volumen semanal por grupo (series efectivas)', '', '| Grupo | Series | Rango | Sesiones/sem | Estado |', '|---|---|---|---|---|');
  for (const v of plan.weeklyVolume) {
    const st = v.status === 'within' ? 'dentro' : v.status === 'below' ? '**por debajo**' : '**por encima**';
    out.push(`| ${GROUP_ES[v.group]}${v.isPriority ? ' ★' : ''} | ${v.effectiveSets} | ${v.min}-${v.max} | ${v.sessions} | ${st} |`);
  }
  out.push('', '## Avisos', '');
  out.push(...(plan.warnings.length ? plan.warnings.map((w) => `- \`${w.code}\`: ${w.message}`) : ['- Ninguno.']), '');
  out.push('## Explicación del plan', '', ...plan.rationale.map((r) => `- ${r}`), '');
  const ls = plan.meta.localSearch;
  const gain = ((ls.finalScore - ls.initialScore) / ls.initialScore) * 100;
  out.push(
    '## Puntuación',
    '',
    `| total | cobertura | volumen | tiempo | frecuencia | balance | variedad | preferencias |`,
    '|---|---|---|---|---|---|---|---|',
    `| ${plan.score.total} | ${plan.score.coverage} | ${plan.score.volumeFit} | ${plan.score.timeFit} | ${plan.score.frequency} | ${plan.score.balance} | ${plan.score.variety} | ${plan.score.preferences} |`,
    '',
    `Búsqueda local: ${ls.initialScore} → ${ls.finalScore} (${gain >= 0 ? '+' : ''}${gain.toFixed(2)} %), ${ls.acceptedMoves} movimientos, ${ls.evaluations} evaluaciones, parada: ${ls.stoppedBy}.`,
    '',
  );
  return out.join('\n');
}

mkdirSync(OUT, { recursive: true });
const summary: string[] = [
  '# Planes de ejemplo del motor v2',
  '',
  'Generados con `pnpm --filter @pipos/engine-rules examples` (10 perfiles que cubren todos los objetivos, niveles, 2-6 días, casa y gimnasio, y lesiones de hombro, rodilla y lumbar). La revisión como entrenador está en [REVISION.md](REVISION.md).',
  '',
  '| Perfil | Split | Score inicial | Score final | Mejora búsqueda local | Avisos |',
  '|---|---|---|---|---|---|',
];
const gains: number[] = [];
for (const ex of EXAMPLES) {

  const r = generatePlan(ex.profile, CATALOG);

  if (!r.ok) throw new Error(`${ex.file}: ${JSON.stringify(r.error)}`);
  writeFileSync(resolve(OUT, ex.file), render(ex, r.plan));
  const ls = r.plan.meta.localSearch;
  const gain = ((ls.finalScore - ls.initialScore) / ls.initialScore) * 100;
  gains.push(gain);
  summary.push(
    `| [${ex.title}](${ex.file}) | ${r.plan.split.type} | ${ls.initialScore.toFixed(4)} | ${ls.finalScore.toFixed(4)} | ${gain >= 0 ? '+' : ''}${gain.toFixed(2)} % | ${r.plan.warnings.map((w) => w.code).join(', ') || '—'} |`,
  );
}
const mean = gains.reduce((a, b) => a + b, 0) / gains.length;
const above = gains.filter((g) => g > 2).length;
summary.push(
  '',
  `**Criterio de retirada de ADR-0006** (la búsqueda local se elimina si no mejora el score más de un 2 %): mejora media **${mean.toFixed(2)} %**; ${above} de ${gains.length} perfiles mejoran más de un 2 %; máxima ${Math.max(...gains).toFixed(2)} %.`,
  '',
);
writeFileSync(resolve(OUT, 'README.md'), summary.join('\n'));
console.log(summary.join('\n'));
