import type { PrismaClient } from '@prisma/client';
import { loadCatalog, type CatalogExercise } from '@pipos/catalog';

export interface SeedResult {
  upserted: number;
  softDeleted: number;
  groups: number;
}

/**
 * Carga el catálogo versionado (@pipos/catalog, ADR-0005) en la BD.
 * - Idempotente: upsert por `slug` y por `SubstitutionGroup.key`.
 * - Los ejercicios que desaparecen del catálogo se marcan con `deletedAt` (borrado lógico):
 *   nunca se borran físicamente porque planes e historial los referencian (RESTRICT).
 * - Un ejercicio que vuelve al catálogo se reactiva (`deletedAt = null`).
 */
export async function seedCatalog(
  prisma: PrismaClient,
  catalog: readonly CatalogExercise[] = loadCatalog(),
  now: Date = new Date(),
): Promise<SeedResult> {
  return prisma.$transaction(
    async (tx) => {
      const keys = [...new Set(catalog.map((e) => e.substitutionGroup))].sort();
      const groupIds = new Map<string, string>();
      for (const key of keys) {
        const group = await tx.substitutionGroup.upsert({
          where: { key },
          create: { key },
          update: {},
          select: { id: true },
        });
        groupIds.set(key, group.id);
      }

      for (const ex of catalog) {
        const data = {
          nameEs: ex.nameEs,
          nameEn: ex.nameEn,
          movementPattern: ex.movementPattern,
          isCompound: ex.isCompound,
          isUnilateral: ex.isUnilateral,
          minLevel: ex.minLevel,
          equipment: ex.equipment,
          loadType: ex.loadType,
          substitutionGroupId: groupIds.get(ex.substitutionGroup) ?? null,
          cuesEs: ex.cuesEs,
          deletedAt: null,
        };
        const row = await tx.exercise.upsert({
          where: { slug: ex.slug },
          create: { slug: ex.slug, ...data },
          update: data,
          select: { id: true },
        });
        await tx.exerciseMuscle.deleteMany({ where: { exerciseId: row.id } });
        await tx.exerciseMuscle.createMany({
          data: ex.muscles.map((m) => ({ exerciseId: row.id, muscle: m.muscle, role: m.role, fraction: m.fraction })),
        });
        await tx.exerciseRiskTag.deleteMany({ where: { exerciseId: row.id } });
        if (ex.riskTags.length > 0) {
          await tx.exerciseRiskTag.createMany({
            data: ex.riskTags.map((r) => ({ exerciseId: row.id, zone: r.zone, level: r.level })),
          });
        }
      }

      const removed = await tx.exercise.updateMany({
        where: { slug: { notIn: catalog.map((e) => e.slug) }, deletedAt: null },
        data: { deletedAt: now },
      });
      return { upserted: catalog.length, softDeleted: removed.count, groups: keys.length };
    },
    { timeout: 60_000 },
  );
}
