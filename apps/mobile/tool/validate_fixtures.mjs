// Valida los fixtures de test/fixtures/api_v1 contra los esquemas Zod de la
// API v1 (packages/contracts). Así los fixtures que usa el test de contrato
// de Dart (test/contract/contract_fixtures_test.dart) son JSON que la API
// realmente puede emitir.
//
// Uso (desde la raíz del repo):
//   pnpm install --filter @pipos/contracts --frozen-lockfile
//   pnpm --filter @pipos/contracts build
//   node apps/mobile/tool/validate_fixtures.mjs
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const contracts = await import(join(here, '../../../packages/contracts/dist/index.js'));
const fixtures = join(here, '../test/fixtures/api_v1');

const map = {
  auth_response: 'AuthResponseSchema',
  me: 'MeResponseSchema',
  profile: 'ProfileResponseSchema',
  profile_update: 'ProfileUpdateResponseSchema',
  health_consent: 'HealthConsentStatusSchema',
  withdraw_consent: 'WithdrawHealthConsentResponseSchema',
  plan_version: 'PlanVersionResponseSchema',
  plan_versions: 'PlanVersionListResponseSchema',
  set_log: 'SetLogResponseSchema',
  workout: 'WorkoutResponseSchema',
  substitution: 'SubstitutionResponseSchema',
  substitutes: 'SubstitutesResponseSchema',
  today_session: 'TodaySessionResponseSchema',
  e1rm: 'E1rmResponseSchema',
  volume: 'VolumeResponseSchema',
  adherence: 'AdherenceResponseSchema',
  nutrition_targets: 'NutritionTargetsResponseSchema',
  exercise_list: 'ExerciseListResponseSchema',
  // Biblioteca por músculo (ADR-0014, Fase 3): `GET /exercises?muscle=glutes`.
  exercise_list_by_muscle: 'ExerciseListResponseSchema',
  // Ficha del ejercicio (ADR-0014). La «legacy» es la respuesta anterior a la
  // Fase 2, sin descripción, errores ni medios: debe seguir siendo válida.
  exercise_detail: 'ExerciseDetailSchema',
  exercise_detail_legacy: 'ExerciseDetailSchema',
  // Fase 4 (ADR-0014): ficha con medios. El vídeo y la imagen son FICTICIOS
  // (solo para tests): el catálogo real no lleva medios hasta que se aprueben por PR.
  exercise_detail_video: 'ExerciseDetailSchema',
  error_validation: 'ErrorResponseSchema',
  error_nutrition_incomplete: 'ErrorResponseSchema',
  export: 'AccountExportSchema',
  // ADR-0013 (ideas recuperadas). Los *_request son lo que serializa la app.
  health_consent_v2: 'HealthConsentStatusSchema',
  exercise_note: 'ExerciseNoteResponseSchema',
  exercise_notes: 'ExerciseNoteListResponseSchema',
  exercise_note_request: 'ExerciseNoteRequestSchema',
  plan_override: 'PlanExerciseOverrideResponseSchema',
  today_session_adjusted: 'TodaySessionResponseSchema',
  today_session_break: 'TodaySessionResponseSchema',
  start_workout_adjusted: 'StartWorkoutRequestSchema',
  patch_set_request: 'PatchSetRequestSchema',
  training_break: 'TrainingBreakResponseSchema',
  training_breaks: 'TrainingBreakListResponseSchema',
  training_break_request: 'CreateTrainingBreakRequestSchema',
  profile_schedule_request: 'ProfileScheduleRequestSchema',
  body_measurement: 'BodyMeasurementResponseSchema',
  body_measurements: 'BodyMeasurementListResponseSchema',
  body_measurement_request: 'UpsertBodyMeasurementRequestSchema',
  body_progress: 'BodyProgressResponseSchema',
  body_progress_not_applicable: 'BodyProgressResponseSchema',
  body_progress_consent_required: 'BodyProgressResponseSchema',
};

/**
 * Listas `muscles` de Hoy y Plan (ADR-0014, `{ muscle, role }`; no el detalle del catálogo, que
 * lleva `fraction`): principales primero y en el orden del enum. El orden
 * no es parte del esquema Zod (perdería el tipo en openapi.json), así que se comprueba aparte.
 */
function unorderedMuscles(node, path = []) {
  if (Array.isArray(node)) return node.flatMap((n, i) => unorderedMuscles(n, [...path, i]));
  if (!node || typeof node !== 'object') return [];
  const own =
    Array.isArray(node.muscles) &&
    node.muscles.every((m) => 'role' in m && !('fraction' in m)) &&
    !contracts.areExerciseMusclesOrdered(node.muscles)
      ? [[...path, 'muscles'].join('.')]
      : [];
  return [...own, ...Object.entries(node).flatMap(([k, v]) => unorderedMuscles(v, [...path, k]))];
}

/** Con `muscle`, la API ordena por nivel mínimo (principiante → avanzado). */
const LEVELS = ['beginner', 'intermediate', 'advanced'];
const byLevel = new Set(['exercise_list_by_muscle']);
function unorderedLevels(file, json) {
  if (!byLevel.has(file)) return false;
  const ranks = json.items.map((e) => LEVELS.indexOf(e.minLevel));
  return ranks.some((r, i) => i > 0 && r < ranks[i - 1]);
}

let failed = 0;
for (const [file, schemaName] of Object.entries(map)) {
  const schema = contracts[schemaName];
  if (!schema) {
    console.error(`✗ ${file}: no existe ${schemaName} en @pipos/contracts`);
    failed++;
    continue;
  }
  const json = JSON.parse(readFileSync(join(fixtures, `${file}.json`), 'utf8'));
  const result = schema.safeParse(json);
  const unordered = unorderedMuscles(json);
  if (result.success && unorderedLevels(file, json)) {
    failed++;
    console.error(`✗ ${file}: ejercicios fuera de orden por nivel`);
  } else if (result.success && unordered.length > 0) {
    failed++;
    console.error(`✗ ${file}: músculos fuera de orden (principales primero, orden del enum)`);
    for (const p of unordered) console.error(`   ${p}`);
  } else if (result.success) {
    console.log(`✓ ${file} (${schemaName})`);
  } else {
    failed++;
    console.error(`✗ ${file} (${schemaName})`);
    for (const issue of result.error.issues) console.error(`   ${issue.path.join('.')}: ${issue.message}`);
  }
}
if (failed) {
  console.error(`${failed} fixture(s) no cumplen el contrato`);
  process.exit(1);
}
console.log('Todos los fixtures cumplen los contratos de la API v1.');
