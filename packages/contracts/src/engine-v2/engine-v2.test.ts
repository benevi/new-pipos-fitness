import { describe, expect, it } from 'vitest';
import { engineV2 } from '../index.js';

const exercise = {
  slug: 'press-banca-barra',
  nameEs: 'Press de banca con barra',
  nameEn: 'Barbell bench press',
  movementPattern: 'horizontal_push',
  isCompound: true,
  isUnilateral: false,
  minLevel: 'beginner',
  equipment: ['barbell', 'bench'],
  loadType: 'weighted',
  muscles: [
    { muscle: 'chest', role: 'primary', fraction: 1 },
    { muscle: 'triceps', role: 'secondary', fraction: 0.5 },
  ],
  riskTags: [{ zone: 'shoulder', level: 'caution' }],
  substitutionGroup: 'horizontal_press',
  cuesEs: ['Escápulas juntas', 'Barra al centro del pecho'],
  descriptionEs: 'Empuje tumbado en banco que baja la barra al pecho y la sube; trabaja sobre todo el pecho.',
  mistakesEs: ['Rebotar la barra en el pecho', 'Despegar los glúteos del banco'],
  media: [],
};

/** Medios FICTICIOS (solo para tests; el catálogo real no lleva vídeos hasta que se aprueben por PR). */
const VIDEO = {
  kind: 'youtube',
  videoId: 'AAAAAAAAAA1',
  startSeconds: 12,
  channelName: 'Canal de prueba',
  locale: 'es',
  isPrimary: true,
};
const IMAGE = { kind: 'image', file: 'press-prueba.webp', credit: 'Equipo Pipos', licence: 'own-work', isPrimary: false };

describe('engineV2: catálogo', () => {
  it('acepta un ejercicio bien etiquetado', () => {
    expect(engineV2.CatalogExerciseSchema.safeParse(exercise).success).toBe(true);
  });

  it('acepta hasta 2 medios con uno principal (ADR-0014, Fase 4)', () => {
    expect(engineV2.CatalogExerciseSchema.safeParse({ ...exercise, media: [VIDEO] }).success).toBe(true);
    expect(engineV2.CatalogExerciseSchema.safeParse({ ...exercise, media: [VIDEO, IMAGE] }).success).toBe(true);
  });

  it.each([
    ['material vacío', { equipment: [] }],
    ['bodyweight con otro material', { equipment: ['bodyweight', 'bench'] }],
    ['material repetido', { equipment: ['bench', 'bench'] }],
    ['sin primario', { muscles: [{ muscle: 'chest', role: 'secondary', fraction: 0.5 }] }],
    ['primario con fracción < 1', { muscles: [{ muscle: 'chest', role: 'primary', fraction: 0.5 }] }],
    [
      'secundario con fracción 1',
      {
        muscles: [
          { muscle: 'chest', role: 'primary', fraction: 1 },
          { muscle: 'triceps', role: 'secondary', fraction: 1 },
        ],
      },
    ],
    [
      'músculo repetido',
      {
        muscles: [
          { muscle: 'chest', role: 'primary', fraction: 1 },
          { muscle: 'chest', role: 'secondary', fraction: 0.5 },
        ],
      },
    ],
    [
      'zona de riesgo repetida',
      {
        riskTags: [
          { zone: 'shoulder', level: 'caution' },
          { zone: 'shoulder', level: 'avoid' },
        ],
      },
    ],
    ['slug no kebab', { slug: 'Press Banca' }],
    ['patrón desconocido', { movementPattern: 'chest_press' }],
    ['una sola indicación', { cuesEs: ['Solo una'] }],
    ['campo extra', { place: 'gym' }],
    ['descripción de más de 400 caracteres', { descriptionEs: 'x'.repeat(401) }],
    ['más de 3 errores comunes', { mistakesEs: ['Error uno', 'Error dos', 'Error tres', 'Error cuatro'] }],
    ['error común de más de 120 caracteres', { mistakesEs: ['x'.repeat(121)] }],
    ['medios a null (formato anterior a la Fase 4)', { media: null }],
    ['más de 2 medios', { media: [VIDEO, { ...VIDEO, videoId: 'BBBBBBBBBB2', isPrimary: false }, IMAGE] }],
    ['medios sin principal', { media: [{ ...VIDEO, isPrimary: false }] }],
    ['dos medios principales', { media: [VIDEO, { ...IMAGE, isPrimary: true }] }],
    ['el mismo vídeo dos veces', { media: [VIDEO, { ...VIDEO, isPrimary: false }] }],
  ])('rechaza %s', (_name, patch) => {
    expect(engineV2.CatalogExerciseSchema.safeParse({ ...exercise, ...patch }).success).toBe(false);
  });

  it('la descripción y los errores comunes son obligatorios; la lista de errores puede ir vacía (ADR-0014)', () => {
    expect(engineV2.CatalogExerciseSchema.safeParse({ ...exercise, mistakesEs: [] }).success).toBe(true);
    for (const key of ['descriptionEs', 'mistakesEs'] as const) {
      const without: Record<string, unknown> = { ...exercise };
      delete without[key];
      expect(engineV2.CatalogExerciseSchema.safeParse(without).success).toBe(false);
    }
  });

  it('rechaza slugs duplicados en la lista', () => {
    expect(engineV2.CatalogSchema.safeParse([exercise, exercise]).success).toBe(false);
  });
});

describe('engineV2: perfil', () => {
  const profile = {
    goal: 'hypertrophy',
    level: 'intermediate',
    daysPerWeek: 4,
    minutesPerSession: 60,
    equipment: ['barbell', 'bench'],
  };

  it('acepta un perfil mínimo y rellena solo listas vacías', () => {
    const parsed = engineV2.EngineProfileSchema.parse(profile);
    expect(parsed.limitations).toEqual([]);
    expect(parsed.priorityMuscles).toEqual([]);
    expect(parsed.body).toBeUndefined();
  });

  it.each([
    ['días = 1', { daysPerWeek: 1 }],
    ['días = 7', { daysPerWeek: 7 }],
    ['minutos = 29', { minutesPerSession: 29 }],
    ['minutos = 91', { minutesPerSession: 91 }],
    ['material desconocido', { equipment: ['sofa'] }],
    ['objetivo antiguo', { goal: 'muscle_gain' }],
    ['más de 3 músculos prioritarios', { priorityMuscles: ['chest', 'lats', 'quads', 'glutes'] }],
    ['sin objetivo', { goal: undefined }],
  ])('rechaza %s', (_n, patch) => {
    expect(engineV2.EngineProfileSchema.safeParse({ ...profile, ...patch }).success).toBe(false);
  });
});

describe('engineV2: progresión y nutrición', () => {
  it('rechaza repMin > repMax', () => {
    const r = engineV2.CurrentPrescriptionSchema.safeParse({
      exerciseId: 'x',
      movementPattern: 'squat',
      loadType: 'weighted',
      sets: 3,
      repMin: 12,
      repMax: 8,
      targetRir: 2,
      loadKg: 50,
    });
    expect(r.success).toBe(false);
  });

  it('dailyTargets exige todos los datos corporales (sin valores por defecto)', () => {
    const base = {
      sex: 'female',
      age: 30,
      weightKg: 60,
      heightCm: 165,
      activityLevel: 'active',
      goal: 'maintenance',
      level: 'beginner',
    };
    expect(engineV2.DailyTargetsInputSchema.safeParse(base).success).toBe(true);
    for (const key of ['sex', 'age', 'weightKg', 'heightCm', 'activityLevel', 'goal', 'level']) {
      const copy: Record<string, unknown> = { ...base };
      delete copy[key];
      expect(engineV2.DailyTargetsInputSchema.safeParse(copy).success).toBe(false);
    }
    expect(engineV2.DailyTargetsInputSchema.safeParse({ ...base, sex: 'other' }).success).toBe(false);
    expect(engineV2.DailyTargetsInputSchema.safeParse({ ...base, age: 17 }).success).toBe(false);
  });

  it('los enums siguen los nombres de MODELO_DATOS.md', () => {
    expect(engineV2.EQUIPMENT).toHaveLength(19);
    expect(engineV2.MUSCLES).toHaveLength(19);
    expect(engineV2.MOVEMENT_PATTERNS).toHaveLength(18);
    expect(engineV2.BODY_ZONES).toEqual(['shoulder', 'elbow', 'wrist', 'lumbar', 'hip', 'knee', 'ankle']);
    expect(engineV2.TRAINING_GOALS).toEqual([
      'strength',
      'hypertrophy',
      'general_health',
      'fat_loss',
      'muscular_endurance',
    ]);
  });
});
