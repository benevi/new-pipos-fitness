/**
 * TODAS las constantes del motor v2, tipadas y citadas (ADR-0006).
 *
 * Cada hoja es un `Constant<T>` con `source: 'PROGRAMACION.md §N'` y la confianza del documento.
 * Las marcadas como heurística en PROGRAMACION.md llevan `heuristic: true`. Cuando el documento da
 * un rango, `value` es el valor por defecto elegido y `range` el rango citado.
 * Un test (programming.test.ts) falla si alguna constante no tiene fuente.
 */
import type { engineV2 } from '@pipos/contracts';

export const ENGINE_VERSION = '2.1.0';

export type Confidence = 'alta' | 'media-alta' | 'media' | 'baja-media' | 'baja';
export type Source = `PROGRAMACION.md §${string}`;

export interface Constant<T> {
  readonly value: T;
  readonly source: Source;
  readonly confidence: Confidence;
  readonly unit?: string;
  readonly range?: readonly [number, number];
  readonly heuristic?: boolean;
  readonly note?: string;
}

function k<T>(
  value: T,
  source: Source,
  confidence: Confidence,
  extra: Omit<Constant<T>, 'value' | 'source' | 'confidence'> = {},
): Constant<T> {
  return { value, source, confidence, ...extra };
}

type Level = engineV2.TrainingLevel;
type Goal = engineV2.TrainingGoal;
type Muscle = engineV2.Muscle;
type VolumeGroup = engineV2.VolumeGroup;
type MovementPattern = engineV2.MovementPattern;
type LoadImplement = engineV2.LoadImplement;

export interface RepScheme {
  readonly repMin: number;
  readonly repMax: number;
  readonly rir: number;
  readonly restSeconds: number;
}

const GROUP_MAP: Record<Muscle, VolumeGroup | null> = {
  chest: 'chest',
  lats: 'back',
  upper_back: 'back',
  front_delts: null,
  side_delts: 'shoulders',
  rear_delts: 'shoulders',
  biceps: 'biceps',
  triceps: 'triceps',
  quads: 'quads',
  hamstrings: 'hamstrings',
  glutes: 'glutes',
  abductors: 'glutes',
  calves: 'calves',
  abs: 'core',
  obliques: 'core',
  traps: null,
  forearms: null,
  lower_back: null,
  adductors: null,
};

export const PROGRAMMING = {
  volume: {
    directSetWeight: k(1, 'PROGRAMACION.md §1', 'alta', { unit: 'serie' }),
    indirectSetWeight: k(0.5, 'PROGRAMACION.md §1', 'media-alta', { unit: 'serie' }),
    weeklyMin: {
      beginner: k(6, 'PROGRAMACION.md §1', 'media', { unit: 'series fraccionales/sem', range: [4, 6] }),
      intermediate: k(10, 'PROGRAMACION.md §1', 'media', { unit: 'series fraccionales/sem' }),
      advanced: k(12, 'PROGRAMACION.md §1', 'media', { unit: 'series fraccionales/sem' }),
    } satisfies Record<Level, Constant<number>>,
    weeklyMax: {
      beginner: k(12, 'PROGRAMACION.md §1', 'baja-media', {
        unit: 'series fraccionales/sem',
        range: [10, 12],
        note: 'techo superior del rango para que haya margen de tiempo',
      }),
      intermediate: k(16, 'PROGRAMACION.md §1', 'media', {
        unit: 'series fraccionales/sem',
        range: [16, 20],
        note: 'extremo inferior para controlar fatiga y tiempo',
      }),
      advanced: k(20, 'PROGRAMACION.md §1', 'media', { unit: 'series fraccionales/sem' }),
    } satisfies Record<Level, Constant<number>>,
    lowVolumeGoals: k<readonly Goal[]>(['general_health', 'strength'], 'PROGRAMACION.md §1', 'media', {
      note: 'regla 4: en salud general o fuerza se acepta volumen bajo o moderado; el suelo baja al de principiante',
    }),
    weeklyMaxPriorityAdvanced: k(24, 'PROGRAMACION.md §1', 'media', {
      unit: 'series fraccionales/sem',
      note: 'solo músculos prioritarios en avanzados',
    }),
    sessionMaxPerMuscle: k(10, 'PROGRAMACION.md §1', 'baja-media', {
      unit: 'series fraccionales/sesión/músculo',
      range: [10, 11],
    }),
    groupOfMuscle: k(GROUP_MAP, 'PROGRAMACION.md §16.1', 'baja', { heuristic: true }),
  },
  frequency: {
    minPerGroup: k(2, 'PROGRAMACION.md §2', 'alta', { unit: 'sesiones/sem/grupo' }),
    maxPerGroup: k(3, 'PROGRAMACION.md §2', 'baja-media', { unit: 'sesiones/sem/grupo' }),
    minEffectiveSetsToCount: k(1, 'PROGRAMACION.md §16.2', 'baja', {
      unit: 'series efectivas/sesión',
      heuristic: true,
    }),
    daysGuide: {
      beginner: k([2, 3] as const, 'PROGRAMACION.md §2', 'alta', { unit: 'días/sem' }),
      intermediate: k([3, 4] as const, 'PROGRAMACION.md §2', 'alta', { unit: 'días/sem' }),
      advanced: k([4, 6] as const, 'PROGRAMACION.md §2', 'media', { unit: 'días/sem' }),
    } satisfies Record<Level, Constant<readonly [number, number]>>,
    split: {
      twoToThreeDays: k('full_body' as const, 'PROGRAMACION.md §2', 'baja', { heuristic: true }),
      fourDays: k('upper_lower' as const, 'PROGRAMACION.md §2', 'baja', { heuristic: true }),
      fiveDays: k('hybrid_ul_ppl' as const, 'PROGRAMACION.md §2', 'baja', { heuristic: true }),
      sixDays: k('push_pull_legs' as const, 'PROGRAMACION.md §2', 'baja', { heuristic: true }),
    },
  },
  prescription: {
    /** Esquemas por objetivo y tipo de ejercicio (main = primer multiarticular del objetivo de fuerza). */
    schemes: {
      strength: {
        main: k<RepScheme>({ repMin: 3, repMax: 6, rir: 2, restSeconds: 180 }, 'PROGRAMACION.md §3', 'alta', {
          note: 'REPS_FUERZA 3-6; RIR_FUERZA 1-3 (2); DESCANSO_COMPUESTO_PESADO 180',
        }),
        compound: k<RepScheme>({ repMin: 6, repMax: 12, rir: 2, restSeconds: 120 }, 'PROGRAMACION.md §3', 'media', {
          note: 'trabajo accesorio 6-12; descanso compuesto 120',
        }),
        isolation: k<RepScheme>({ repMin: 6, repMax: 12, rir: 1, restSeconds: 90 }, 'PROGRAMACION.md §4', 'media', {
          note: 'accesorio 6-12; RIR aislamiento 0-1 (1); DESCANSO_AISLAMIENTO 90',
        }),
      },
      hypertrophy: {
        compound: k<RepScheme>({ repMin: 8, repMax: 12, rir: 2, restSeconds: 120 }, 'PROGRAMACION.md §3', 'media', {
          note: 'REPS_HIPERTROFIA_DEF 8-12; RIR_HIPERTROFIA_COMPUESTO 1-2 (2); DESCANSO 120',
        }),
        isolation: k<RepScheme>({ repMin: 10, repMax: 15, rir: 1, restSeconds: 90 }, 'PROGRAMACION.md §16.4', 'baja', {
          heuristic: true,
          note: 'dentro de REPS_HIPERTROFIA_RANGO 5-30; RIR 0-1 (1)',
        }),
      },
      muscular_endurance: {
        compound: k<RepScheme>({ repMin: 15, repMax: 20, rir: 2, restSeconds: 60 }, 'PROGRAMACION.md §3', 'media', {
          note: 'REPS_RESISTENCIA 15-25 (rango por defecto 15-20); DESCANSO_MIN 60; RIR §16.4',
        }),
        isolation: k<RepScheme>({ repMin: 15, repMax: 25, rir: 1, restSeconds: 60 }, 'PROGRAMACION.md §3', 'media', {
          note: 'REPS_RESISTENCIA 15-25; DESCANSO_MIN 60',
        }),
      },
      general_health: {
        compound: k<RepScheme>({ repMin: 8, repMax: 12, rir: 3, restSeconds: 120 }, 'PROGRAMACION.md §3', 'alta', {
          note: 'REPS_SALUD 8-12; RIR_PRINCIPIANTE 2-4 (3)',
        }),
        isolation: k<RepScheme>({ repMin: 8, repMax: 12, rir: 2, restSeconds: 90 }, 'PROGRAMACION.md §3', 'alta', {
          note: 'REPS_SALUD 8-12; RIR 2-4 (2 en aislamiento)',
        }),
      },
    },
    fatLossUsesScheme: k<'hypertrophy'>('hypertrophy', 'PROGRAMACION.md §16.4', 'baja', { heuristic: true }),
    beginner: {
      reps: k<readonly [number, number]>([8, 12], 'PROGRAMACION.md §3', 'alta', {
        note: 'ACSM 2009: principiantes 8-12 RM, también con objetivo de fuerza',
      }),
      compoundRir: k(3, 'PROGRAMACION.md §4', 'media', { range: [2, 4] }),
      isolationRir: k(2, 'PROGRAMACION.md §4', 'media', { range: [2, 4] }),
    },
    maxExercisesPerSession: k(8, 'PROGRAMACION.md §16.3', 'baja', { heuristic: true, unit: 'ejercicios/sesión' }),
    maxCoreExercisesPerSession: k(2, 'PROGRAMACION.md §16.3', 'baja', { heuristic: true, unit: 'ejercicios/sesión' }),
    /** Grupos que solo se llevan hasta el suelo al rellenar tiempo (salvo prioritarios). */
    fillOnlyToFloor: k<readonly ('calves' | 'core')[]>(['calves', 'core'], 'PROGRAMACION.md §16.3', 'baja', {
      heuristic: true,
    }),
    neverFailureOnCompounds: k(true, 'PROGRAMACION.md §4', 'baja', { heuristic: true }),
    minRestSeconds: k(60, 'PROGRAMACION.md §5', 'media', { unit: 's' }),
    sets: {
      strengthMain: k(3, 'PROGRAMACION.md §3', 'alta', { range: [2, 3], unit: 'series/ejercicio' }),
      min: k(2, 'PROGRAMACION.md §16.3', 'baja', { heuristic: true, unit: 'series/ejercicio' }),
      max: k(4, 'PROGRAMACION.md §16.3', 'baja', { heuristic: true, unit: 'series/ejercicio' }),
      default: k(3, 'PROGRAMACION.md §16.3', 'baja', { heuristic: true, unit: 'series/ejercicio' }),
      generalHealthMax: k(3, 'PROGRAMACION.md §3', 'alta', { range: [1, 3], unit: 'series/ejercicio' }),
    },
    warmup: {
      heavyCompoundSets: k(2, 'PROGRAMACION.md §8', 'baja', { heuristic: true, range: [2, 3] }),
      strengthGoalSets: k(3, 'PROGRAMACION.md §8', 'baja', { heuristic: true, range: [2, 3] }),
      otherSets: k(0, 'PROGRAMACION.md §8', 'baja', { heuristic: true, range: [0, 1] }),
      otherHeavySets: k(1, 'PROGRAMACION.md §8', 'baja', {
        heuristic: true,
        range: [0, 1],
        note: 'resto de multiarticulares a 3-6 reps',
      }),
      ramp: k<readonly { pct: number; reps: number }[]>(
        [
          { pct: 50, reps: 8 },
          { pct: 70, reps: 5 },
          { pct: 85, reps: 3 },
        ],
        'PROGRAMACION.md §16.5',
        'baja',
        { heuristic: true },
      ),
    },
  },
  order: {
    priority: k(
      ['main', 'secondary', 'accessory', 'core'] as const,
      'PROGRAMACION.md §6',
      'alta',
      { note: 'compuesto prioritario → compuesto → aislamiento → core' },
    ),
    allowIsolationFirstForPriority: k(true, 'PROGRAMACION.md §6', 'media'),
  },
  progression: {
    loadIncrementPctUpper: k(2.5, 'PROGRAMACION.md §7', 'baja-media', { unit: '%', range: [2, 10] }),
    loadIncrementPctLower: k(5, 'PROGRAMACION.md §7', 'baja-media', { unit: '%', range: [2, 10] }),
    minIncrementKg: k(1, 'PROGRAMACION.md §7', 'baja', { unit: 'kg', heuristic: true }),
    lowerBodyPatterns: k<readonly MovementPattern[]>(
      ['squat', 'hinge', 'lunge', 'knee_extension', 'knee_flexion', 'hip_isolation', 'calf_raise'],
      'PROGRAMACION.md §7',
      'baja-media',
      { note: 'reparto superior/inferior por convención' },
    ),
    autoregulateByRir: k(true, 'PROGRAMACION.md §7', 'media'),
    stagnationSessions: k(2, 'PROGRAMACION.md §7', 'baja', { heuristic: true, range: [2, 3] }),
    reactiveDecreasePct: k(5, 'PROGRAMACION.md §16.9', 'baja', { heuristic: true, unit: '%', range: [5, 10] }),
    deloadEveryWeeks: k(6, 'PROGRAMACION.md §7', 'baja', { heuristic: true, range: [4, 8] }),
    deloadDurationDays: k(7, 'PROGRAMACION.md §7', 'baja-media', { unit: 'días' }),
    deloadVolumeReductionPct: k(50, 'PROGRAMACION.md §7', 'baja', { heuristic: true, unit: '%', range: [40, 50] }),
    deloadExtraRir: k(2, 'PROGRAMACION.md §7', 'baja'),
    deloadTotalRest: k(false, 'PROGRAMACION.md §7', 'media'),
    breakDays: k(14, 'PROGRAMACION.md §16.9', 'baja', { heuristic: true, unit: 'días' }),
    breakLoadReductionPct: k(10, 'PROGRAMACION.md §16.9', 'baja', { heuristic: true, unit: '%', range: [5, 10] }),
  },
  time: {
    secondsPerRep: k(3.5, 'PROGRAMACION.md §8', 'baja', { heuristic: true, unit: 's/rep', range: [3, 4] }),
    generalWarmupMin: k(5, 'PROGRAMACION.md §8', 'baja', { heuristic: true, unit: 'min' }),
    warmupSetSeconds: k(60, 'PROGRAMACION.md §8', 'baja', { heuristic: true, unit: 's/serie' }),
    transitionSeconds: k(60, 'PROGRAMACION.md §8', 'baja', { heuristic: true, unit: 's', range: [60, 120] }),
    unilateralFactor: k(2, 'PROGRAMACION.md §16.6', 'baja', { heuristic: true }),
    tolerancePct: k(10, 'PROGRAMACION.md §16.6', 'baja', { heuristic: true, unit: '%' }),
  },
  e1rm: {
    epleyDivisor: k(30, 'PROGRAMACION.md §9', 'media', { note: 'e1RM = carga × (1 + reps/30)' }),
    maxReps: k(10, 'PROGRAMACION.md §9', 'media', { unit: 'reps' }),
    useRirAsExtraReps: k(true, 'PROGRAMACION.md §9', 'baja', { heuristic: true }),
    unreliablePatterns: k<readonly MovementPattern[]>(['hinge'], 'PROGRAMACION.md §9', 'media', {
      note: 'Epley infraestima el peso muerto (LeSuer 1997): la carga se marca como estimación',
    }),
    loadRoundingKg: k(1, 'PROGRAMACION.md §16.10', 'baja', { heuristic: true, unit: 'kg' }),
  },
  /** Pasos reales de carga por material y discos (idea 1 de docs/IDEAS_EL_PLAN.md). */
  load: {
    stepKgByImplement: k<Record<LoadImplement, number>>(
      {
        barbell: 2.5,
        trap_bar: 2.5,
        ez_bar: 2.5,
        smith_machine: 2.5,
        dumbbell: 2,
        kettlebell: 4,
        machine: 5,
        cable: 2.5,
        weight_plate: 2.5,
      },
      'PROGRAMACION.md §16.16',
      'baja',
      {
        heuristic: true,
        unit: 'kg totales',
        note: 'INCREMENTO_MIN_KG §7 («el siguiente peso disponible»); material típico de gimnasio, decisión de diseño',
      },
    ),
    barKg: k<Partial<Record<LoadImplement, number>>>(
      { barbell: 20, ez_bar: 10, trap_bar: 25 },
      'PROGRAMACION.md §16.16',
      'baja',
      { heuristic: true, unit: 'kg', note: 'barras estándar; la guiada (smith) varía y no se desglosa' },
    ),
    platesKg: k<readonly number[]>([25, 20, 15, 10, 5, 2.5, 1.25], 'PROGRAMACION.md §16.16', 'baja', {
      heuristic: true,
      unit: 'kg por disco',
    }),
    bigJumpPct: k(10, 'PROGRAMACION.md §16.16', 'baja', {
      heuristic: true,
      unit: '%',
      note: 'por encima, la explicación avisa de que el siguiente peso disponible es un salto grande',
    }),
  },
  /** Ajuste de la sesión de hoy: poco tiempo o volumen reducido (idea 4, ADR-0013). */
  adjust: {
    dropOrder: k(['core', 'accessory', 'secondary'] as const, 'PROGRAMACION.md §16.17', 'baja', {
      heuristic: true,
      note: 'orden inverso de prioridad de §6; nunca se quita el principal',
    }),
    minMinutes: k(15, 'PROGRAMACION.md §16.17', 'baja', { heuristic: true, unit: 'min' }),
    maxMinutes: k(90, 'PROGRAMACION.md §16.17', 'baja', { heuristic: true, unit: 'min' }),
    minMainSets: k(2, 'PROGRAMACION.md §16.17', 'baja', { heuristic: true, unit: 'series' }),
    reducedSetsDelta: k(1, 'PROGRAMACION.md §16.17', 'baja', { heuristic: true, unit: 'series' }),
    reducedMinSetsMain: k(2, 'PROGRAMACION.md §16.17', 'baja', { heuristic: true, unit: 'series' }),
    reducedMinSetsOther: k(1, 'PROGRAMACION.md §16.17', 'baja', { heuristic: true, unit: 'series' }),
    reducedExtraRir: k(1, 'PROGRAMACION.md §16.17', 'baja', {
      heuristic: true,
      note: 'apoyo: autorregulación por RIR (Graham y Cleather 2021; Helms 2018, §7)',
    }),
  },
  /** Medidas corporales: tendencia de peso, IMC y % de grasa estimado (idea 7, ADR-0013). */
  body: {
    movingAverageDays: k(7, 'PROGRAMACION.md §16.19', 'baja', { heuristic: true, unit: 'días' }),
    trendWindowDays: k(28, 'PROGRAMACION.md §16.19', 'baja', {
      heuristic: true,
      unit: 'días',
      note: '§11 regla 6: recalibrar con la tendencia real cada 2-3 semanas; se usan las 4 últimas',
    }),
    minSpanDays: k(14, 'PROGRAMACION.md §16.19', 'baja', { heuristic: true, unit: 'días' }),
    minEntries: k(4, 'PROGRAMACION.md §16.19', 'baja', { heuristic: true, unit: 'registros' }),
    gainRatePctPerWeek: k(0.25, 'PROGRAMACION.md §11', 'baja', {
      unit: '% peso/sem',
      range: [0.25, 0.5],
      note: 'Iraki et al. 2019, cifra de resúmenes secundarios [NO VERIFICADO textualmente]',
    }),
    bmiCutoffs: k<readonly [number, number, number, number, number]>([18.5, 25, 30, 35, 40], 'PROGRAMACION.md §16.19', 'alta', {
      unit: 'kg/m²',
      note: 'WHO 2000 (TRS 894): adultos; poblaciones asiáticas usan cortes más bajos (WHO 2004)',
    }),
    bmiAdultAge: k(18, 'PROGRAMACION.md §16.19', 'alta', { unit: 'años' }),
    navyMale: k({ c: 1.0324, abdomenNeck: 0.19077, height: 0.15456 }, 'PROGRAMACION.md §16.19', 'media', {
      note: 'Hodgdon y Beckett 1984 (NHRC 84-11): densidad corporal en cm y log10; % = 495/D − 450 (Siri 1961)',
    }),
    navyFemale: k({ c: 1.29579, waistHipNeck: 0.35004, height: 0.221 }, 'PROGRAMACION.md §16.19', 'media', {
      note: 'Hodgdon y Beckett 1984 (NHRC 84-29); % = 495/D − 450 (Siri 1961)',
    }),
  },
  balance: {
    pullPushRatioMin: k(1, 'PROGRAMACION.md §10', 'baja', { heuristic: true }),
    pullPushRatioMax: k(1.5, 'PROGRAMACION.md §10', 'baja', { heuristic: true }),
    weeklyPatterns: k<readonly MovementPattern[]>(
      ['horizontal_push', 'vertical_push', 'horizontal_pull', 'vertical_pull', 'squat', 'hinge', 'core_anti_extension'],
      'PROGRAMACION.md §10',
      'baja',
      { heuristic: true, note: 'core: cualquier patrón core cuenta (anti-extensión, anti-rotación o flexión)' },
    ),
    autoGenerationExcludedPatterns: k<readonly MovementPattern[]>(['carry'], 'PROGRAMACION.md §16.12', 'baja', {
      heuristic: true,
    }),
  },
  scoring: {
    weights: k(
      {
        coverage: 0.25,
        volumeFit: 0.2,
        timeFit: 0.2,
        frequency: 0.1,
        balance: 0.1,
        variety: 0.1,
        preferences: 0.05,
      },
      'PROGRAMACION.md §16.7',
      'baja',
      { heuristic: true },
    ),
    cautionPenalty: k(0.5, 'PROGRAMACION.md §16.7', 'baja', { heuristic: true }),
  },
  nutrition: {
    msjWeight: k(10, 'PROGRAMACION.md §11', 'alta', { unit: 'kcal/kg' }),
    msjHeight: k(6.25, 'PROGRAMACION.md §11', 'alta', { unit: 'kcal/cm' }),
    msjAge: k(-5, 'PROGRAMACION.md §11', 'alta', { unit: 'kcal/año' }),
    msjMale: k(5, 'PROGRAMACION.md §11', 'alta', { unit: 'kcal' }),
    msjFemale: k(-161, 'PROGRAMACION.md §11', 'alta', { unit: 'kcal' }),
    pal: {
      sedentary_light: k(1.55, 'PROGRAMACION.md §11', 'media', { range: [1.4, 1.69] }),
      active: k(1.85, 'PROGRAMACION.md §11', 'media', { range: [1.7, 1.99] }),
      vigorous: k(2.1, 'PROGRAMACION.md §11', 'media', { range: [2.0, 2.39] }),
    } satisfies Record<engineV2.ActivityLevel, Constant<number>>,
    proteinGPerKg: k(1.6, 'PROGRAMACION.md §11', 'alta', { unit: 'g/kg/día', range: [1.6, 2.2] }),
    proteinDeficitGPerKgBody: k(2.2, 'PROGRAMACION.md §11', 'media', { unit: 'g/kg/día', range: [2.2, 2.6] }),
    proteinDeficitGPerKgLean: k(2.3, 'PROGRAMACION.md §11', 'media', { unit: 'g/kg masa magra/día', range: [2.3, 3.1] }),
    fatPctDefault: k(25, 'PROGRAMACION.md §16.11', 'baja', { heuristic: true, unit: '% energía', range: [20, 35] }),
    fatPctMin: k(20, 'PROGRAMACION.md §11', 'alta', { unit: '% energía' }),
    fatPctMax: k(35, 'PROGRAMACION.md §11', 'alta', { unit: '% energía' }),
    fatGPerKgGuard: k(0.8, 'PROGRAMACION.md §11', 'baja', {
      heuristic: true,
      unit: 'g/kg/día',
      note: 'heurística sin fuente: solo genera un aviso',
    }),
    lossRatePctPerWeek: k(0.7, 'PROGRAMACION.md §11', 'media-alta', { unit: '% peso/sem', range: [0.5, 1] }),
    kcalPerKgTissue: k(7700, 'PROGRAMACION.md §11', 'baja', { heuristic: true, unit: 'kcal/kg' }),
    surplusPct: k(10, 'PROGRAMACION.md §11', 'baja-media', { unit: '% TDEE', range: [10, 20] }),
    surplusPctAdvanced: k(5, 'PROGRAMACION.md §11', 'baja-media', { unit: '% TDEE', range: [5, 10] }),
    kcalFloorIsRee: k(true, 'PROGRAMACION.md §16.11', 'baja', { heuristic: true }),
    kcalPerGProtein: k(4, 'PROGRAMACION.md §16.11', 'alta', { note: 'factor de Atwater' }),
    kcalPerGCarb: k(4, 'PROGRAMACION.md §16.11', 'alta', { note: 'factor de Atwater' }),
    kcalPerGFat: k(9, 'PROGRAMACION.md §16.11', 'alta', { note: 'factor de Atwater' }),
    studyAgeRange: k<readonly [number, number]>([19, 78], 'PROGRAMACION.md §11', 'alta', {
      note: 'población de Mifflin 1990; fuera de rango se avisa',
    }),
  },
  plan: {
    mesocycleWeeks: k(6, 'PROGRAMACION.md §16.14', 'baja', { heuristic: true, note: '= DELOAD_CADA_SEMANAS' }),
  },
} as const;

export type ProgrammingConfig = typeof PROGRAMMING;

/** Para los tipos de objetivo con esquema propio. */
export type SchemeGoal = keyof ProgrammingConfig['prescription']['schemes'];
export function schemeGoal(goal: Goal, config: ProgrammingConfig = PROGRAMMING): SchemeGoal {
  return goal === 'fat_loss' ? config.prescription.fatLossUsesScheme.value : goal;
}
