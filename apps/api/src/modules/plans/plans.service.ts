import { HttpStatus, Injectable } from '@nestjs/common';
import type { Prisma } from '@prisma/client';
import { generatePlan } from '@pipos/engine-rules';
import type {
  engineV2,
  PaginationQuery,
  PlanVersionListResponse,
  PlanVersionResponse,
  PlanVersionSummary,
} from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { log } from '../../logging/logging';
import { isUniqueViolation, PrismaService, type TransactionClient } from '../../prisma/prisma.service';
import { CatalogService } from '../catalog/catalog.service';
import { EngineInputService, type Db } from './engine-input.service';
import {
  draftToSessionsCreate,
  planVersionInclude,
  storedRationale,
  toSummary,
  toVersionResponse,
} from './plan-mapper';

/** Reintentos ante colisión del número de versión (dos generaciones simultáneas). */
export const PLAN_VERSION_MAX_ATTEMPTS = 3;

export interface PreparedPlan {
  draft: engineV2.PlanDraft;
  snapshot: engineV2.EngineProfileInput;
  sessions: Prisma.PlanSessionCreateWithoutPlanVersionInput[];
  /** Cambios fijados que se heredan, por posición en el plan nuevo (ids de ejercicio). */
  pinnedIds: { sessionOrder: number; exerciseOrder: number; exerciseId: string }[];
}

@Injectable()
export class PlansService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly catalog: CatalogService,
    private readonly engineInput: EngineInputService,
  ) {}

  /**
   * Ejecuta el motor (puro, fuera de la transacción). El historial reciente entra para
   * calcular cargas iniciales por e1RM (CUJ-6: el nuevo plan conserva lo aprendido).
   */
  async prepare(userId: string, engineProfile: engineV2.EngineProfileInput, timezone: string): Promise<PreparedPlan> {
    const [catalog, history, pins] = await Promise.all([
      this.catalog.engineCatalog(),
      this.engineInput.history(userId, timezone),
      this.currentPins(userId),
    ]);
    // Los cambios fijados de la versión vigente se heredan si siguen siendo válidos (idea 3).
    const result = generatePlan({ ...engineProfile, history }, catalog.exercises, { pinnedSubstitutions: pins });
    if (!result.ok) {
      const status = result.error.code === 'INVALID_CATALOG' ? HttpStatus.INTERNAL_SERVER_ERROR : HttpStatus.UNPROCESSABLE_ENTITY;
      if (status >= 500) log('error', 'Engine rejected the catalog', { code: result.error.code });
      throw new ApiError(status, 'PLAN_GENERATION_FAILED', result.error.message, result.error.issues);
    }
    return {
      draft: result.plan,
      snapshot: engineProfile,
      sessions: draftToSessionsCreate(result.plan, catalog.bySlug),
      pinnedIds: result.plan.pinnedSubstitutions.map((p) => ({
        sessionOrder: p.sessionOrder,
        exerciseOrder: p.exerciseOrder,
        exerciseId: catalog.bySlug.get(p.to)?.id ?? '',
      })),
    };
  }

  /** Cambios fijados de la versión vigente como pares de slugs `from → to` (sin duplicados). */
  async currentPins(userId: string, db: Db = this.prisma): Promise<engineV2.PinnedSubstitutionInput[]> {
    const id = await this.currentVersionId(userId, db);
    if (!id) return [];
    const rows = await db.planExerciseOverride.findMany({
      where: { userId, planExercise: { planSession: { planVersionId: id } } },
      select: { exercise: { select: { slug: true } }, planExercise: { select: { exercise: { select: { slug: true } } } } },
    });
    const pins = new Map<string, string>();
    for (const r of rows) pins.set(r.planExercise.exercise.slug, r.exercise.slug);
    return [...pins].sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0)).map(([from, to]) => ({ from, to }));
  }

  /**
   * Guarda una versión nueva del plan activo dentro de `tx` (una sola escritura anidada:
   * versión + sesiones + ejercicios con orden). El número de versión lo protege
   * UNIQUE(planId, version); la carrera se resuelve reintentando la transacción entera.
   */
  async persistVersion(tx: TransactionClient, userId: string, prepared: PreparedPlan): Promise<PlanVersionSummary> {
    const plan =
      (await tx.trainingPlan.findFirst({ where: { userId, status: 'active' }, select: { id: true } })) ??
      (await tx.trainingPlan.create({ data: { userId }, select: { id: true } }));
    const last = await tx.planVersion.aggregate({ where: { planId: plan.id }, _max: { version: true } });
    const created = await tx.planVersion.create({
      data: {
        planId: plan.id,
        userId,
        version: (last._max.version ?? 0) + 1,
        engineVersion: prepared.draft.engineVersion,
        objectiveScore: prepared.draft.score.total,
        mesocycleWeeks: prepared.draft.mesocycleWeeks,
        rationale: storedRationale(prepared.draft) as unknown as Prisma.InputJsonValue,
        inputSnapshot: prepared.snapshot as unknown as Prisma.InputJsonValue,
        sessions: { create: prepared.sessions },
      },
      include: { _count: { select: { sessions: true } } },
    });
    if (prepared.pinnedIds.length > 0) {
      const slots = await tx.planExercise.findMany({
        where: { planSession: { planVersionId: created.id } },
        select: { id: true, order: true, planSession: { select: { order: true } } },
      });
      const byPos = new Map(slots.map((s) => [`${s.planSession.order}:${s.order}`, s.id]));
      const data = prepared.pinnedIds.flatMap((p) => {
        const planExerciseId = byPos.get(`${p.sessionOrder}:${p.exerciseOrder}`);
        return planExerciseId && p.exerciseId ? [{ planExerciseId, userId, exerciseId: p.exerciseId }] : [];
      });
      if (data.length > 0) await tx.planExerciseOverride.createMany({ data });
    }
    return toSummary(created);
  }

  /** `$transaction` con reintento ante P2002 (número de versión o plan activo duplicados). */
  async withVersionRetry<T>(work: (tx: TransactionClient) => Promise<T>): Promise<T> {
    for (let attempt = 1; ; attempt++) {
      try {
        return await this.prisma.$transaction(work, { timeout: 15_000 });
      } catch (error) {
        if (!isUniqueViolation(error)) throw error;
        if (attempt >= PLAN_VERSION_MAX_ATTEMPTS) {
          throw new ApiError(HttpStatus.CONFLICT, 'PLAN_VERSION_CONFLICT', 'Concurrent plan generation; retry');
        }
      }
    }
  }

  async generate(userId: string): Promise<PlanVersionResponse> {
    const ctx = await this.engineInput.load(userId);
    if (!ctx) {
      throw new ApiError(HttpStatus.CONFLICT, 'PROFILE_REQUIRED', 'Complete your training profile first');
    }
    const prepared = await this.prepare(userId, ctx.engineProfile, ctx.profile.timezone);
    const summary = await this.withVersionRetry((tx) => this.persistVersion(tx, userId, prepared));
    return this.version(userId, summary.id);
  }

  async hasActivePlan(userId: string, db: Db = this.prisma): Promise<boolean> {
    return (await db.trainingPlan.count({ where: { userId, status: 'active' } })) > 0;
  }

  /** Versión vigente = la de mayor número del plan activo. */
  async currentVersionId(userId: string, db: Db = this.prisma): Promise<string | null> {
    const row = await db.planVersion.findFirst({
      where: { userId, plan: { status: 'active' } },
      orderBy: { version: 'desc' },
      select: { id: true },
    });
    return row?.id ?? null;
  }

  async current(userId: string): Promise<PlanVersionResponse> {
    const id = await this.currentVersionId(userId);
    if (!id) throw new ApiError(HttpStatus.NOT_FOUND, 'PLAN_REQUIRED', 'No training plan yet');
    return this.version(userId, id);
  }

  async versions(userId: string, page: PaginationQuery): Promise<PlanVersionListResponse> {
    const where = { userId };
    const [total, rows] = await Promise.all([
      this.prisma.planVersion.count({ where }),
      this.prisma.planVersion.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { version: 'desc' }],
        skip: (page.page - 1) * page.pageSize,
        take: page.pageSize,
        include: { _count: { select: { sessions: true } } },
      }),
    ]);
    return { items: rows.map(toSummary), page: page.page, pageSize: page.pageSize, total };
  }

  /** Propiedad: solo versiones del propio usuario (otra → 404, no se revela su existencia). */
  async version(userId: string, id: string): Promise<PlanVersionResponse> {
    const row = await this.prisma.planVersion.findFirst({ where: { id, userId }, include: planVersionInclude });
    if (!row) throw ApiError.notFound('Plan version not found');
    return toVersionResponse(row);
  }
}
