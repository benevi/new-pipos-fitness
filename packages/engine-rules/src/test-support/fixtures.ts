/** Fixtures compartidos por tests y por el script de ejemplos. */
import type { engineV2 } from '@pipos/contracts';
import { loadCatalog } from '@pipos/catalog';

export const CATALOG: readonly engineV2.CatalogExercise[] = loadCatalog();

export const FULL_GYM: engineV2.Equipment[] = [
  'barbell',
  'ez_bar',
  'trap_bar',
  'dumbbell',
  'kettlebell',
  'weight_plate',
  'bench',
  'squat_rack',
  'cable',
  'machine',
  'smith_machine',
  'pull_up_bar',
  'dip_station',
];
export const HOME_DUMBBELLS: engineV2.Equipment[] = ['dumbbell', 'bench', 'resistance_band', 'pull_up_bar'];

export function profile(overrides: Partial<engineV2.EngineProfileInput> = {}): engineV2.EngineProfileInput {
  return {
    goal: 'hypertrophy',
    level: 'intermediate',
    daysPerWeek: 4,
    minutesPerSession: 60,
    equipment: FULL_GYM,
    ...overrides,
  };
}

/** Historial sintético: varias semanas de los básicos con progresión lineal. */
export function longHistory(): engineV2.TrainingHistory {
  const lifts: [string, number, number][] = [
    ['sentadilla-trasera-barra', 100, 5],
    ['press-banca-barra', 80, 5],
    ['peso-muerto-barra', 140, 5],
    ['press-militar-barra', 50, 6],
    ['remo-barra', 70, 8],
    ['dominadas-pronas', 0, 8],
    ['press-banca-mancuernas', 30, 10],
    ['jalon-pecho-polea', 65, 10],
  ];
  const entries: engineV2.ExerciseSessionLog[] = [];
  for (let week = 0; week < 12; week++) {
    const day = String(1 + ((week * 7) % 28)).padStart(2, '0');
    const month = String(8 + Math.floor((week * 7) / 28)).padStart(2, '0');
    for (const [slug, load, reps] of lifts) {
      entries.push({
        date: `2026-${month}-${day}`,
        exerciseId: slug,
        sets: [
          { reps: 5, loadKg: Math.round(load * 0.5), isWarmup: true },
          { reps, loadKg: load + week * 1, rir: 2 },
          { reps, loadKg: load + week * 1, rir: 2 },
          { reps: reps - 1, loadKg: load + week * 1, rir: 1 },
        ],
      });
    }
  }
  return { entries };
}
