import request from 'supertest';
import { loadCatalog, type CatalogExercise, type CatalogMedia } from '@pipos/catalog';
import { ExerciseDetailSchema, TodaySessionResponseSchema } from '@pipos/contracts';
import { seedCatalog } from '../../catalog-seed/seed-catalog';
import { CatalogService } from '../../modules/catalog/catalog.service';
import { bearer, createTestApp, truncateAll, userWithPlan, type TestContext } from './helpers';

/**
 * Vídeos e imágenes del catálogo (ADR-0014, Fase 4), e2e contra Postgres real, con un catálogo DE
 * PRUEBA: los medios de aquí son FICTICIOS. El catálogo real no lleva ninguno hasta que una
 * persona lo elija y lo apruebe por PR; al terminar se vuelve a sembrar el catálogo real.
 */
const FAKE_VIDEO: CatalogMedia = {
  kind: 'youtube',
  videoId: 'AAAAAAAAAA1',
  startSeconds: 42,
  endSeconds: 95,
  channelName: 'Canal de prueba',
  locale: 'es',
  isPrimary: true,
};
const FAKE_IMAGE: CatalogMedia = {
  kind: 'image',
  file: 'prueba-tecnica.webp',
  credit: 'Equipo Pipos',
  licence: 'own-work',
  isPrimary: false,
};

/** Catálogo real con `media` sustituido en los ejercicios de `bySlug`. */
function testCatalog(bySlug: Record<string, CatalogMedia[]>): CatalogExercise[] {
  return loadCatalog().map((e) => (bySlug[e.slug] ? { ...e, media: bySlug[e.slug] } : e));
}

describe('Vídeos e imágenes del catálogo (e2e, Postgres real)', () => {
  let ctx: TestContext;
  const server = () => ctx.app.getHttpServer();
  const slug = loadCatalog()[0].slug;

  async function seed(bySlug: Record<string, CatalogMedia[]>) {
    const result = await seedCatalog(ctx.prisma, testCatalog(bySlug));
    ctx.app.get(CatalogService).invalidate();
    return result;
  }

  async function detail(idOrSlug: string, token: string) {
    return ExerciseDetailSchema.parse(
      (await request(server()).get(`/exercises/${idOrSlug}`).set(bearer(token)).expect(200)).body,
    );
  }

  beforeAll(async () => {
    ctx = await createTestApp();
  });
  beforeEach(async () => {
    await truncateAll(ctx.prisma);
  });
  afterAll(async () => {
    // Deja el catálogo real (sin medios) para el resto de suites.
    await seedCatalog(ctx.prisma);
    ctx.app.get(CatalogService).invalidate();
    await ctx.app.close();
  });

  it('el detalle incluye los medios aprobados, el principal primero; los retirados desaparecen tras el seed', async () => {
    const { user } = await userWithPlan(ctx.app);
    const t = user.accessToken;

    // Sin medios en el catálogo, la lista llega vacía.
    await seed({});
    expect((await detail(slug, t)).media).toEqual([]);

    const first = await seed({ [slug]: [{ ...FAKE_IMAGE }, { ...FAKE_VIDEO }] });
    expect(first).toMatchObject({ media: 2, mediaRemoved: 0 });
    const withMedia = await detail(slug, t);
    expect(withMedia.media).toEqual([
      { ...FAKE_VIDEO },
      { kind: 'image', file: FAKE_IMAGE.file, credit: 'Equipo Pipos', licence: 'own-work', isPrimary: false },
    ]);
    // También por id; la revisión es el PR: quedan aprobados.
    expect((await detail(withMedia.id, t)).media).toEqual(withMedia.media);
    const rows = await ctx.prisma.exerciseMedia.findMany({ where: { exerciseId: withMedia.id } });
    expect(rows.map((r) => r.moderationStatus)).toEqual(['approved', 'approved']);
    expect(rows.every((r) => r.moderatedAt !== null && r.moderatedById === null)).toBe(true);

    // Un medio que no viene del catálogo (p. ej. pendiente) no se envía, y el seed lo borra.
    await ctx.prisma.exerciseMedia.create({
      data: { exerciseId: withMedia.id, kind: 'youtube', externalId: 'ZZZZZZZZZZ9', channelName: 'X', locale: 'es' },
    });
    expect((await detail(slug, t)).media).toHaveLength(2);

    // Idempotente: el mismo JSON conserva las filas (mismos ids) y quita lo que no está.
    const again = await seed({ [slug]: [{ ...FAKE_IMAGE }, { ...FAKE_VIDEO }] });
    expect(again).toMatchObject({ media: 2, mediaRemoved: 1 });
    const ids = (await ctx.prisma.exerciseMedia.findMany({ where: { exerciseId: withMedia.id } })).map((r) => r.id);
    expect(ids.sort()).toEqual(rows.map((r) => r.id).sort());

    // Cambiar cuál es el principal no choca con el índice único parcial.
    await seed({ [slug]: [{ ...FAKE_VIDEO, isPrimary: false, startSeconds: 10 }, { ...FAKE_IMAGE, isPrimary: true }] });
    expect((await detail(slug, t)).media.map((m) => [m.kind, m.isPrimary])).toEqual([
      ['image', true],
      ['youtube', false],
    ]);
    expect((await detail(slug, t)).media[1]).toMatchObject({ startSeconds: 10 });

    // Retirado del JSON: desaparece del detalle y de la tabla.
    const removed = await seed({ [slug]: [{ ...FAKE_VIDEO }] });
    expect(removed).toMatchObject({ mediaRemoved: 1 });
    expect((await detail(slug, t)).media).toEqual([{ ...FAKE_VIDEO }]);
    await seed({});
    expect((await detail(slug, t)).media).toEqual([]);
    expect(await ctx.prisma.exerciseMedia.count()).toBe(0);
  });

  it('Hoy marca hasVideo solo en el ejercicio con un vídeo aprobado', async () => {
    const { user } = await userWithPlan(ctx.app);
    const t = bearer(user.accessToken);
    const today = async () =>
      TodaySessionResponseSchema.parse((await request(server()).get('/sessions/today').set(t).expect(200)).body);

    await seed({});
    const before = await today();
    expect(before.exercises.length).toBeGreaterThan(1);
    expect(before.exercises.every((e) => e.hasVideo === false)).toBe(true);

    const [withVideo, withImage] = before.exercises.map((e) => e.exercise.slug);
    await seed({ [withVideo]: [{ ...FAKE_VIDEO }], [withImage]: [{ ...FAKE_IMAGE, isPrimary: true }] });
    const after = await today();
    expect(after.exercises.map((e) => [e.exercise.slug, e.hasVideo])).toEqual(
      before.exercises.map((e) => [e.exercise.slug, e.exercise.slug === withVideo]),
    );

    await seed({});
    expect((await today()).exercises.every((e) => e.hasVideo === false)).toBe(true);
  });
});
