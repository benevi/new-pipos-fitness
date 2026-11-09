import type { Prisma } from '@prisma/client';
import { PROGRAMMING } from '@pipos/engine-rules';
import type {
  engineV2,
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
        include: { exercise: { select: { slug: true, nameEs: true, movementPattern: true, loadType: true } } },
      },
    },
  },
} satisfies Prisma.PlanVersionInclude;

export type PlanVersionRow = Prisma.PlanVersionGetPayload<{ include: typeof planVersionInclude }>;
type SummaryRow = Pick<
  PlanVersionRow,
  'id' | 'planId' | 'version' | 'engineVersion' | 'mesocycleWeeks' | 'objectiveScore' | 'createdAt' | 'rationale'
> & { _count?: { sessions: number }; sessions?: unknown[] };

export function roundLoad(kg: number): number {
  const step = PROGRAMMING.e1rm.loadRoundingKg.value;
  return Math.floor(kg / step + 1e-9) * step;
}

export function warmupsFor(stored: unknown, workingLoad: number | null): WarmupSetResponse[] {
  const ramp = Array.isArray(stored) ? (stored as { reps: number; loadPct: number | null }[]) : [];
  return ramp.map((w) => ({
    reps: w.reps,
    loadPct: w.loadPct,
    loadKg: workingLoad === null || w.loadPct === null ? null : roundLoad((workingLoad * w.loadPct) / 100),
  }));
}

const asStrings = (v: unknown): string[] => (Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : []);

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
            rationale: e.rationale,
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

export function toExerciseResponse(e: PlanVersionRow['sessions'][number]['exercises'][number]): PlanExerciseResponse {
  const initial = e.initialLoadKg === null ? null : Number(e.initialLoadKg);
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
    warmupSets: warmupsFor(e.warmupSets, initial),
    estimatedMinutes: e.estimatedMinutes,
    rationale: asStrings(e.rationale),
  };
}

export function toSessionResponse(s: PlanVersionRow['sessions'][number]): PlanSessionResponse {
  return {
    id: s.id,
    order: s.order,
    dayIndex: s.dayIndex,
    kind: s.kind,
    name: s.name,
    targetMinutes: s.targetMinutes,
    estimatedMinutes: s.estimatedMinutes,
    rationale: asStrings(s.rationale),
    exercises: s.exercises.map(toExerciseResponse),
  };
}

export function toVersionResponse(row: PlanVersionRow): PlanVersionResponse {
  const r = readRationale(row.rationale);
  return {
    ...toSummary(row),
    split: r.split,
    rationale: r.rationale,
    warnings: r.warnings,
    weeklyVolume: r.weeklyVolume,
    sessions: row.sessions.map(toSessionResponse),
  };
}
