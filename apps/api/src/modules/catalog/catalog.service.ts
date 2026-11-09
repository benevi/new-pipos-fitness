import { Injectable } from '@nestjs/common';
import type { Prisma } from '@prisma/client';
import { loadImplement } from '@pipos/engine-rules';
import { sortExerciseMuscles } from '@pipos/contracts';
import type {
  engineV2,
  ExerciseDetail,
  ExerciseListQuery,
  ExerciseListResponse,
  ExerciseMuscleRef,
  ExerciseRef,
  ExerciseSummary,
  LoadType,
  MovementPattern,
} from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { Clock } from '../../common/clock';
import { PrismaService } from '../../prisma/prisma.service';

const exerciseInclude = {
  muscles: { orderBy: { muscle: 'asc' } },
  riskTags: { orderBy: { zone: 'asc' } },
  substitutionGroup: { select: { key: true } },
} satisfies Prisma.ExerciseInclude;

type ExerciseRow = Prisma.ExerciseGetPayload<{ include: typeof exerciseInclude }>;

export interface CatalogEntry {
  id: string;
  slug: string;
  nameEs: string;
  movementPattern: MovementPattern;
  loadType: LoadType;
  isUnilateral: boolean;
  cuesEs: string[];
  muscles: { muscle: engineV2.Muscle; fraction: number }[];
  /** Músculos para mostrar en Hoy y en Plan (principales primero, orden del enum; ADR-0014). */
  muscleRefs: ExerciseMuscleRef[];
  /** Material que fija el paso de carga (PROGRAMACION.md §16.16); null si no se carga en kg. */
  loadImplement: engineV2.LoadImplement | null;
}

export interface EngineCatalog {
  /** Catálogo activo con la forma que espera el motor (identificador = slug). */
  exercises: engineV2.CatalogExercise[];
  bySlug: ReadonlyMap<string, CatalogEntry>;
  byId: ReadonlyMap<string, CatalogEntry>;
}

/** El catálogo solo cambia con un despliegue (seed, ADR-0005): una caché corta basta. */
export const CATALOG_CACHE_TTL_MS = 60_000;

export function toEngineExercise(row: ExerciseRow): engineV2.CatalogExercise {
  return {
    slug: row.slug,
    nameEs: row.nameEs,
    nameEn: row.nameEn,
    movementPattern: row.movementPattern,
    isCompound: row.isCompound,
    isUnilateral: row.isUnilateral,
    minLevel: row.minLevel,
    equipment: row.equipment,
    loadType: row.loadType,
    muscles: row.muscles.map((m) => ({ muscle: m.muscle, role: m.role, fraction: Number(m.fraction) })),
    riskTags: row.riskTags.map((r) => ({ zone: r.zone, level: r.level })),
    substitutionGroup: row.substitutionGroup?.key ?? row.slug.replace(/-/g, '_'),
    cuesEs: row.cuesEs,
    media: null,
  };
}

function toSummary(row: ExerciseRow): ExerciseSummary {
  return {
    id: row.id,
    slug: row.slug,
    nameEs: row.nameEs,
    nameEn: row.nameEn,
    movementPattern: row.movementPattern,
    isCompound: row.isCompound,
    isUnilateral: row.isUnilateral,
    minLevel: row.minLevel,
    equipment: row.equipment,
    loadType: row.loadType,
    primaryMuscles: row.muscles.filter((m) => m.role === 'primary').map((m) => m.muscle),
  };
}

function toEntry(row: ExerciseRow): CatalogEntry {
  return {
    id: row.id,
    slug: row.slug,
    nameEs: row.nameEs,
    movementPattern: row.movementPattern,
    loadType: row.loadType,
    isUnilateral: row.isUnilateral,
    cuesEs: row.cuesEs,
    muscles: row.muscles.map((m) => ({ muscle: m.muscle, fraction: Number(m.fraction) })),
    muscleRefs: sortExerciseMuscles(row.muscles),
    loadImplement: loadImplement(row),
  };
}

const LEVELS = ['beginner', 'intermediate', 'advanced'] as const;

@Injectable()
export class CatalogService {
  private cache: { at: number; value: EngineCatalog } | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  /** Catálogo activo (sin borrados lógicos) para el motor, con índices por slug e id. */
  async engineCatalog(): Promise<EngineCatalog> {
    const now = this.clock.now().getTime();
    if (this.cache && now - this.cache.at < CATALOG_CACHE_TTL_MS) return this.cache.value;
    const rows = await this.prisma.exercise.findMany({
      where: { deletedAt: null },
      include: exerciseInclude,
      orderBy: { slug: 'asc' },
    });
    const entries = rows.map(toEntry);
    const value: EngineCatalog = {
      exercises: rows.map(toEngineExercise),
      bySlug: new Map(entries.map((e) => [e.slug, e])),
      byId: new Map(entries.map((e) => [e.id, e])),
    };
    this.cache = { at: now, value };
    return value;
  }

  invalidate(): void {
    this.cache = null;
  }

  /** Referencias (id, slug, nombre) también de ejercicios retirados: el historial los muestra. */
  async refs(ids: readonly string[]): Promise<Map<string, ExerciseRef>> {
    if (ids.length === 0) return new Map();
    const rows = await this.prisma.exercise.findMany({
      where: { id: { in: [...new Set(ids)] } },
      select: { id: true, slug: true, nameEs: true },
    });
    return new Map(rows.map((r) => [r.id, r]));
  }

  async list(query: ExerciseListQuery): Promise<ExerciseListResponse> {
    const where: Prisma.ExerciseWhereInput = {
      deletedAt: null,
      ...(query.movementPattern ? { movementPattern: query.movementPattern } : {}),
      ...(query.level ? { minLevel: { in: LEVELS.slice(0, LEVELS.indexOf(query.level) + 1) } } : {}),
      ...(query.q
        ? {
            OR: [
              { nameEs: { contains: query.q, mode: 'insensitive' } },
              { nameEn: { contains: query.q, mode: 'insensitive' } },
              { slug: { contains: query.q.toLowerCase() } },
            ],
          }
        : {}),
    };
    if (query.equipment) {
      // Realizable con ese material: TODO el material del ejercicio está en la lista (`<@`).
      const available = [...new Set([...query.equipment, 'bodyweight' as const])];
      const ids = await this.prisma.$queryRaw<{ id: string }[]>`
        SELECT id FROM "Exercise"
        WHERE "deletedAt" IS NULL AND equipment <@ ${available}::"Equipment"[]`;
      where.id = { in: ids.map((r) => r.id) };
    }
    const [total, rows] = await Promise.all([
      this.prisma.exercise.count({ where }),
      this.prisma.exercise.findMany({
        where,
        include: exerciseInclude,
        orderBy: { slug: 'asc' },
        skip: (query.page - 1) * query.pageSize,
        take: query.pageSize,
      }),
    ]);
    return { items: rows.map(toSummary), page: query.page, pageSize: query.pageSize, total };
  }

  async get(id: string): Promise<ExerciseDetail> {
    const row = await this.prisma.exercise.findFirst({ where: { id, deletedAt: null }, include: exerciseInclude });
    if (!row) throw ApiError.notFound('Exercise not found');
    return {
      ...toSummary(row),
      muscles: row.muscles.map((m) => ({ muscle: m.muscle, role: m.role, fraction: Number(m.fraction) })),
      riskTags: row.riskTags.map((r) => ({ zone: r.zone, level: r.level })),
      substitutionGroup: row.substitutionGroup?.key ?? null,
      cuesEs: row.cuesEs,
    };
  }
}
