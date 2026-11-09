import type { Prisma, PrismaClient } from '@prisma/client';
import { loadCatalog, type CatalogExercise, type CatalogMedia } from '@pipos/catalog';

export interface SeedResult {
  upserted: number;
  softDeleted: number;
  groups: number;
  /** Medios del catálogo escritos (creados o actualizados) y borrados por haber salido del JSON. */
  media: number;
  mediaRemoved: number;
}

/** Columnas de un medio del catálogo; `moderationStatus = approved` porque la revisión es el PR (ADR-0005). */
function mediaColumns(m: CatalogMedia) {
  const common = { isPrimary: m.isPrimary, moderationStatus: 'approved' as const, moderatedById: null };
  return m.kind === 'youtube'
    ? {
        ...common,
        kind: 'youtube' as const,
        externalId: m.videoId,
        startSeconds: m.startSeconds ?? null,
        endSeconds: m.endSeconds ?? null,
        channelName: m.channelName,
        locale: m.locale,
        file: null,
        credit: null,
        licence: null,
        url: null,
      }
    : {
        ...common,
        kind: 'image' as const,
        file: m.file,
        credit: m.credit,
        licence: m.licence,
        externalId: null,
        startSeconds: null,
        endSeconds: null,
        channelName: null,
        locale: null,
        url: null,
      };
}

/**
 * Sincroniza los medios de un ejercicio con el JSON (ADR-0014, Fase 4): borra los que ya no
 * están (incluidos los que no vienen del catálogo: el único origen es el PR), actualiza los que
 * siguen (conservan id) y crea los nuevos. Primero se desmarca el principal para no chocar con
 * el índice único parcial `media_one_primary` al cambiarlo de un medio a otro.
 */
async function syncMedia(
  tx: Prisma.TransactionClient,
  exerciseId: string,
  media: readonly CatalogMedia[],
  now: Date,
): Promise<{ written: number; removed: number }> {
  const existing = await tx.exerciseMedia.findMany({
    where: { exerciseId },
    select: { id: true, kind: true, externalId: true, file: true },
  });
  const keyOf = (r: { kind: string; externalId: string | null; file: string | null }) =>
    r.kind === 'youtube' ? `youtube:${r.externalId}` : `image:${r.file}`;
  const wanted = new Map(media.map((m) => [m.kind === 'youtube' ? `youtube:${m.videoId}` : `image:${m.file}`, m]));
  const keep = new Map<string, string>();
  const drop: string[] = [];
  for (const row of existing) {
    const key = keyOf(row);
    if (wanted.has(key) && !keep.has(key)) keep.set(key, row.id);
    else drop.push(row.id);
  }
  if (drop.length > 0) await tx.exerciseMedia.deleteMany({ where: { id: { in: drop } } });
  if (keep.size > 0) {
    await tx.exerciseMedia.updateMany({ where: { id: { in: [...keep.values()] } }, data: { isPrimary: false } });
  }
  // El principal se escribe el último: así nunca hay dos a la vez.
  const ordered = [...wanted].sort(([, a], [, b]) => Number(a.isPrimary) - Number(b.isPrimary));
  for (const [key, m] of ordered) {
    const id = keep.get(key);
    const data = mediaColumns(m);
    // `moderatedAt` es la fecha del primer seed que lo aprobó; no cambia en cada despliegue.
    if (id) await tx.exerciseMedia.update({ where: { id }, data });
    else await tx.exerciseMedia.create({ data: { exerciseId, ...data, moderatedAt: now } });
  }
  return { written: wanted.size, removed: drop.length };
}

/**
 * Carga el catálogo versionado (@pipos/catalog, ADR-0005) en la BD.
 * - Idempotente: upsert por `slug` y por `SubstitutionGroup.key`.
 * - Los ejercicios que desaparecen del catálogo se marcan con `deletedAt` (borrado lógico):
 *   nunca se borran físicamente porque planes e historial los referencian (RESTRICT).
 * - Un ejercicio que vuelve al catálogo se reactiva (`deletedAt = null`).
 * - Los medios (vídeos e imágenes, ADR-0014) se escriben aprobados y los que salen del JSON se
 *   borran: un medio retirado deja de verse en cuanto se despliega el seed.
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

      let media = 0;
      let mediaRemoved = 0;
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
          descriptionEs: ex.descriptionEs,
          mistakesEs: ex.mistakesEs,
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
        const synced = await syncMedia(tx, row.id, ex.media, now);
        media += synced.written;
        mediaRemoved += synced.removed;
      }

      const removed = await tx.exercise.updateMany({
        where: { slug: { notIn: catalog.map((e) => e.slug) }, deletedAt: null },
        data: { deletedAt: now },
      });
      return { upserted: catalog.length, softDeleted: removed.count, groups: keys.length, media, mediaRemoved };
    },
    { timeout: 60_000 },
  );
}
