import { HttpStatus, Injectable } from '@nestjs/common';
import { substitutes as engineSubstitutes } from '@pipos/engine-rules';
import type { PlanExerciseOverrideResponse } from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { PrismaService } from '../../prisma/prisma.service';
import { AnalyticsService } from '../analytics/analytics.service';
import { CatalogService } from '../catalog/catalog.service';
import { EngineInputService } from './engine-input.service';
import { PlansService } from './plans.service';

/** Alternativas que se miran al validar un cambio fijado (las mismas que el cambio puntual). */
const OVERRIDE_VALIDATION_LIMIT = 50;

/**
 * Cambio de ejercicio permanente dentro del plan (idea 3, ADR-0013). La versión del plan es
 * inmutable; el cambio vive en PlanExerciseOverride, se aplica a todos los huecos de la versión
 * vigente con el mismo ejercicio original y se hereda al generar la siguiente (PlansService.prepare).
 * No crea una versión nueva del plan.
 */
@Injectable()
export class OverridesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly catalog: CatalogService,
    private readonly engineInput: EngineInputService,
    private readonly plans: PlansService,
    private readonly analytics: AnalyticsService,
  ) {}

  private async slotOfCurrentVersion(userId: string, planExerciseId: string) {
    const versionId = await this.plans.currentVersionId(userId);
    if (!versionId) throw new ApiError(HttpStatus.NOT_FOUND, 'PLAN_REQUIRED', 'No training plan yet');
    // Propiedad + vigencia: el hueco debe ser de la versión vigente del propio usuario.
    const slot = await this.prisma.planExercise.findFirst({
      where: { id: planExerciseId, planSession: { planVersionId: versionId, userId } },
      select: { exerciseId: true, exercise: { select: { id: true, slug: true, nameEs: true } } },
    });
    if (!slot) throw ApiError.notFound('Plan exercise not found in your current plan version');
    const slots = await this.prisma.planExercise.findMany({
      where: { exerciseId: slot.exerciseId, planSession: { planVersionId: versionId, userId } },
      select: { id: true },
      orderBy: { id: 'asc' },
    });
    return { versionId, original: slot.exercise, slotIds: slots.map((s) => s.id) };
  }

  async pin(userId: string, planExerciseId: string, exerciseId: string): Promise<PlanExerciseOverrideResponse> {
    const { versionId, original, slotIds } = await this.slotOfCurrentVersion(userId, planExerciseId);
    if (exerciseId === original.id) return this.unpin(userId, planExerciseId);

    const ctx = await this.engineInput.load(userId);
    if (!ctx) throw new ApiError(HttpStatus.CONFLICT, 'PROFILE_REQUIRED', 'Complete your training profile first');
    const catalog = await this.catalog.engineCatalog();
    const result = engineSubstitutes(original.slug, ctx.engineProfile, catalog.exercises, OVERRIDE_VALIDATION_LIMIT);
    const target = catalog.byId.get(exerciseId);
    const valid = result.ok && target !== undefined && result.substitutes.some((s) => s.exerciseId === target.slug);
    if (!valid || !target) {
      throw ApiError.validation(
        [{ path: 'body.exerciseId', message: 'Not a valid substitute for your profile' }],
        'Exercise is not a valid substitute',
      );
    }
    await this.prisma.$transaction(async (tx) => {
      await this.analytics.lockUser(tx, userId);
      for (const id of slotIds) {
        await tx.planExerciseOverride.upsert({
          where: { planExerciseId: id },
          create: { planExerciseId: id, userId, exerciseId },
          update: { exerciseId },
        });
      }
    });
    return {
      planVersionId: versionId,
      planExerciseIds: slotIds,
      original,
      pinned: { id: target.id, slug: target.slug, nameEs: target.nameEs },
    };
  }

  /** Volver al ejercicio original del plan (idempotente). */
  async unpin(userId: string, planExerciseId: string): Promise<PlanExerciseOverrideResponse> {
    const { versionId, original, slotIds } = await this.slotOfCurrentVersion(userId, planExerciseId);
    await this.prisma.planExerciseOverride.deleteMany({ where: { userId, planExerciseId: { in: slotIds } } });
    return { planVersionId: versionId, planExerciseIds: slotIds, original, pinned: null };
  }
}
