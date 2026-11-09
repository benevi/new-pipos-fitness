import { describe, expect, it, vi } from 'vitest';
import { substitutes } from '@pipos/engine-rules';
import type { PrismaService } from '../../prisma/prisma.service';
import { catalogServiceMock, fakeEngineCatalog, prismaMock, profileRow, rejectsWithCode, UID } from '../../test/unit/support';
import type { AnalyticsService } from '../analytics/analytics.service';
import type { CatalogService } from '../catalog/catalog.service';
import { buildEngineProfile, type EngineInputService } from './engine-input.service';
import { OverridesService } from './overrides.service';
import type { PlansService } from './plans.service';

const ORIGINAL_SLUG = 'sentadilla-trasera-barra';
const engineProfile = buildEngineProfile(profileRow(), [], [], false, new Date('2026-11-09T10:00:00Z'));
const catalog = fakeEngineCatalog();
const original = { id: `id:${ORIGINAL_SLUG}`, slug: ORIGINAL_SLUG, nameEs: catalog.bySlug.get(ORIGINAL_SLUG)!.nameEs };

/** Un sustituto válido según el propio motor (el servicio valida con la misma función). */
function validSubstitute() {
  const result = substitutes(ORIGINAL_SLUG, engineProfile, catalog.exercises, 50);
  if (!result.ok || result.substitutes.length === 0) throw new Error('el catálogo debería tener sustitutos');
  return catalog.bySlug.get(result.substitutes[0].exerciseId)!;
}

function setup({ versionId = 'v1' as string | null, ctx = { engineProfile } as unknown } = {}) {
  const prisma = prismaMock();
  const plans = { currentVersionId: vi.fn().mockResolvedValue(versionId) };
  const engineInput = { load: vi.fn().mockResolvedValue(ctx) };
  const analytics = { lockUser: vi.fn() };
  prisma.planExercise.findFirst.mockResolvedValue({ exerciseId: original.id, exercise: original });
  prisma.planExercise.findMany.mockResolvedValue([{ id: 'pe1' }, { id: 'pe2' }]);
  const service = new OverridesService(
    prisma as unknown as PrismaService,
    catalogServiceMock(catalog) as unknown as CatalogService,
    engineInput as unknown as EngineInputService,
    plans as unknown as PlansService,
    analytics as unknown as AnalyticsService,
  );
  return { prisma, analytics, service };
}

describe('OverridesService (cambio fijado en el plan, idea 3)', () => {
  it('sin plan → 404 PLAN_REQUIRED', async () => {
    const { service } = setup({ versionId: null });
    await rejectsWithCode(service.pin(UID, 'pe1', 'x'), 'PLAN_REQUIRED', 404);
  });

  it('hueco que no es de la versión vigente del usuario → 404', async () => {
    const { prisma, service } = setup();
    prisma.planExercise.findFirst.mockResolvedValue(null);
    await rejectsWithCode(service.unpin(UID, 'ajeno'), 'NOT_FOUND', 404);
  });

  it('fijar el propio original equivale a quitar el cambio', async () => {
    const { prisma, service } = setup();
    await expect(service.pin(UID, 'pe1', original.id)).resolves.toEqual({
      planVersionId: 'v1',
      planExerciseIds: ['pe1', 'pe2'],
      original,
      pinned: null,
    });
    expect(prisma.planExerciseOverride.deleteMany).toHaveBeenCalledWith({
      where: { userId: UID, planExerciseId: { in: ['pe1', 'pe2'] } },
    });
  });

  it('sin perfil → 409 PROFILE_REQUIRED', async () => {
    const { service } = setup({ ctx: null });
    await rejectsWithCode(service.pin(UID, 'pe1', validSubstitute().id), 'PROFILE_REQUIRED', 409);
  });

  it('un ejercicio que no es sustituto válido (o no existe) → 400', async () => {
    const { prisma, service } = setup();
    await rejectsWithCode(service.pin(UID, 'pe1', 'id:no-existe'), 'VALIDATION_FAILED', 400);
    await rejectsWithCode(service.pin(UID, 'pe1', `id:${'curl-biceps-barra'}`), 'VALIDATION_FAILED', 400);
    expect(prisma.planExerciseOverride.upsert).not.toHaveBeenCalled();
  });

  it('sustituto válido → upsert en todos los huecos con ese ejercicio', async () => {
    const { prisma, analytics, service } = setup();
    const target = validSubstitute();
    await expect(service.pin(UID, 'pe1', target.id)).resolves.toEqual({
      planVersionId: 'v1',
      planExerciseIds: ['pe1', 'pe2'],
      original,
      pinned: { id: target.id, slug: target.slug, nameEs: target.nameEs },
    });
    expect(analytics.lockUser).toHaveBeenCalledWith(prisma, UID);
    expect(prisma.planExerciseOverride.upsert).toHaveBeenCalledTimes(2);
    expect(prisma.planExerciseOverride.upsert.mock.calls[1][0]).toEqual({
      where: { planExerciseId: 'pe2' },
      create: { planExerciseId: 'pe2', userId: UID, exerciseId: target.id },
      update: { exerciseId: target.id },
    });
  });
});
