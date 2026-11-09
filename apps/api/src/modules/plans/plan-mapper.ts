import type { Prisma } from '@prisma/client';
import { loadImplement, roundLoad as roundToStep } from '@pipos/engine-rules';
import type {
  engineV2,
  ExerciseMuscleRef,
  PlanExerciseResponse,
  PlanSessionResponse,
  PlanVersionResponse,
  PlanVersionSummary,
  WarmupSetResponse,
} from '@pipos/contracts';
import type { CatalogEntry } from '../catalog/catalog.service';

/** Lo que se guarda en `PlanVersion.rationale` (explicación estructurada del motor). */
export interface StoredRationale {
  split: engineV2.PlanDraft['split'];
  rationale: string[];
  /**
   * Explicaciones derivadas de datos de salud (limitaciones). Se vacían al retirar el
   * consentimiento (ConsentService.withdraw); las versiones antiguas pueden no tenerlo.
   */
  healthNotes?: string[];
  /** Los avisos con `health: true` se borran al retirar el consentimiento. */
  warnings: engineV2.EngineWarning[];
  weeklyVolume: engineV2.GroupVolume[];
  muscleVolume: engineV2.MuscleVolume[];
  score: engineV2.ScoreBreakdown;
  meta: engineV2.PlanDraft['meta'];
}

export const planVersionInclude = {
  sessions: {
    orderBy: { order: 'asc' },
    include: {
      exercises: {
        orderBy: { order: 'asc' },
        include: {
          exercise: { select: { slug: true, nameEs: true, movementPattern: true, loadType: true, equipment: true } },
          override: { select: { exercise: { select: { id: true, slug: true, nameEs: true } } } },
        },
      },
    },
  },
} satisfies Prisma.PlanVersionInclude;

export type PlanVersionRow = Prisma.PlanVersionGetPayload<{ include: typeof planVersionInclude }>;
type SummaryRow = Pick<
  PlanVersionRow,
  'id' | 'planId' | 'version' | 'engineVersion' | 'mesocycleWeeks' | 'objectiveScore' | 'createdAt' | 'rationale'
> & { _count?: { sessions: number }; sessions?: unknown[] };

/** Hacia abajo al paso real del material (PROGRAMACION.md §16.16; 1 kg sin material). */
export function roundLoad(kg: number, implement: engineV2.LoadImplement | null = null): number {
  return roundToStep(kg, implement, 'down');
}

export function warmupsFor(
  stored: unknown,
  workingLoad: number | null,
  implement: engineV2.LoadImplement | null = null,
): WarmupSetResponse[] {
  const ramp = Array.isArray(stored) ? (stored as { reps: number; loadPct: number | null }[]) : [];
  return ramp.map((w) => ({
    reps: w.reps,
    loadPct: w.loadPct,
    loadKg: workingLoad === null || w.loadPct === null ? null : roundLoad((workingLoad * w.loadPct) / 100, implement),
  }));
}

const asStrings = (v: unknown): string[] => (Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : []);

/**
 * Explicación de un ejercicio tal y como se guarda en `PlanExercise.rationale`: textos
 * normales como string y los derivados de salud como `{ text, health: true }`, para poder
 * borrarlos con SQL al retirar el consentimiento (RGPD art. 9; ConsentService.withdraw).
 */
export type StoredExerciseRationale = (string | { text: string; health: true })[];

export function exerciseRationaleToStore(e: Pick<engineV2.PlannedExercise, 'rationale' | 'healthNotes'>): StoredExerciseRationale {
  return [...e.rationale, ...e.healthNotes.map((text) => ({ text, health: true as const }))];
}

/** Lee `PlanExercise.rationale` (strings y entradas marcadas) como lista de textos. */
export function readExerciseRationale(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  return v.flatMap((x): string[] => {
    if (typeof x === 'string') return [x];
    if (x && typeof x === 'object' && typeof (x as { text?: unknown }).text === 'string') return [(x as { text: string }).text];
    return [];
  });
}

/** Borrador del motor → `sessions.create` anidado (una sola escritura dentro de la transacción). */
export function draftToSessionsCreate(
  draft: engineV2.PlanDraft,
  bySlug: ReadonlyMap<string, CatalogEntry>,
): Prisma.PlanSessionCreateWithoutPlanVersionInput[] {
  return draft.sessions.map((s) => ({
    dayIndex: s.dayIndex,
    order: s.order,
    kind: s.kind,
    name: s.name,
    targetMinutes: s.targetMinutes,
    estimatedMinutes: s.estimatedMinutes,
    rationale: s.rationale,
    exercises: {
      createMany: {
        data: s.exercises.map((e) => {
          const entry = bySlug.get(e.exerciseId);
          if (!entry) throw new Error(`Engine returned an exercise outside the catalog: ${e.exerciseId}`);
          return {
            exerciseId: entry.id,
            order: e.order,
            role: e.role,
            sets: e.sets,
            repMin: e.repMin,
            repMax: e.repMax,
            targetRir: e.targetRir,
            restSeconds: e.restSeconds,
            initialLoadKg: e.initialLoadKg,
            initialLoadIsEstimate: e.initialLoadIsEstimate,
            warmupSets: e.warmupSets.map((w) => ({ reps: w.reps, loadPct: w.loadPct })),
            estimatedMinutes: e.estimatedMinutes,
            rationale: exerciseRationaleToStore(e),
          };
        }),
      },
    },
  }));
}

export function storedRationale(draft: engineV2.PlanDraft): StoredRationale {
  return {
    split: draft.split,
    rationale: draft.rationale,
    healthNotes: draft.healthNotes,
    warnings: draft.warnings,
    weeklyVolume: draft.weeklyVolume,
    muscleVolume: draft.muscleVolume,
    score: draft.score,
    meta: draft.meta,
  };
}

export function readRationale(value: Prisma.JsonValue): StoredRationale {
  return value as unknown as StoredRationale;
}

export function toSummary(row: SummaryRow): PlanVersionSummary {
  const r = readRationale(row.rationale);
  return {
    id: row.id,
    planId: row.planId,
    version: row.version,
    engineVersion: row.engineVersion,
    splitType: r.split.type,
    mesocycleWeeks: row.mesocycleWeeks,
    objectiveScore: row.objectiveScore,
    sessionCount: row._count?.sessions ?? row.sessions?.length ?? 0,
    createdAt: row.createdAt.toISOString(),
  };
}

/**
 * Catálogo activo por id (la caché de CatalogService) para rellenar los músculos sin consultas
 * por ejercicio. null = sin músculos (p. ej. la exportación RGPD, que no los necesita).
 */
export type CatalogById = ReadonlyMap<string, { muscleRefs: ExerciseMuscleRef[] }> | null;

type PlanExerciseRow = PlanVersionRow['sessions'][number]['exercises'][number];

export function toExerciseResponse(e: PlanExerciseRow, catalog: CatalogById): PlanExerciseResponse {
  const initial = e.initialLoadKg === null ? null : Number(e.initialLoadKg);
  const implement = loadImplement(e.exercise);
  return {
    id: e.id,
    order: e.order,
    exerciseId: e.exerciseId,
    slug: e.exercise.slug,
    nameEs: e.exercise.nameEs,
    movementPattern: e.exercise.movementPattern,
    loadType: e.exercise.loadType,
    role: e.role,
    sets: e.sets,
    repMin: e.repMin,
    repMax: e.repMax,
    targetRir: e.targetRir,
    restSeconds: e.restSeconds,
    initialLoadKg: initial,
    initialLoadIsEstimate: e.initialLoadIsEstimate,
    loadImplement: implement,
    pinned: e.override ? e.override.exercise : null,
    warmupSets: warmupsFor(e.warmupSets, initial, implement),
    estimatedMinutes: e.estimatedMinutes,
    rationale: readExerciseRationale(e.rationale),
    // El ejercicio que se hace en el hueco: el fijado si lo hay (ADR-0014, Fase 1).
    muscles: catalog?.get(e.override?.exercise.id ?? e.exerciseId)?.muscleRefs ?? [],
  };
}

export function toSessionResponse(s: PlanVersionRow['sessions'][number], catalog: CatalogById): PlanSessionResponse {
  return {
    id: s.id,
    order: s.order,
    dayIndex: s.dayIndex,
    kind: s.kind,
    name: s.name,
    targetMinutes: s.targetMinutes,
    estimatedMinutes: s.estimatedMinutes,
    rationale: asStrings(s.rationale),
    exercises: s.exercises.map((e) => toExerciseResponse(e, catalog)),
  };
}

export function toVersionResponse(row: PlanVersionRow, catalog: CatalogById): PlanVersionResponse {
  const r = readRationale(row.rationale);
  return {
    ...toSummary(row),
    split: r.split,
    rationale: [...r.rationale, ...(r.healthNotes ?? [])],
    warnings: r.warnings,
    weeklyVolume: r.weeklyVolume,
    sessions: row.sessions.map((s) => toSessionResponse(s, catalog)),
  };
}
