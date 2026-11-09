import { loadCatalog } from '@pipos/catalog';
import { createTestApp, truncateAll, type TestContext } from '../test/e2e/helpers';
import { seedCatalog } from './seed-catalog';

describe('seed del catálogo (e2e, Postgres real)', () => {
  let ctx: TestContext;

  beforeAll(async () => {
    ctx = await createTestApp();
    await truncateAll(ctx.prisma);
  });
  afterAll(async () => {
    await seedCatalog(ctx.prisma); // deja el catálogo completo para el resto de suites
    await ctx.app.close();
  });

  it('es idempotente, marca con deletedAt lo retirado (nunca borra) y reactiva lo que vuelve', async () => {
    const full = loadCatalog();
    const before = await ctx.prisma.exercise.findMany({ select: { id: true, slug: true } });

    const again = await seedCatalog(ctx.prisma);
    expect(again).toMatchObject({ upserted: full.length, softDeleted: 0 });
    const ids = await ctx.prisma.exercise.findMany({ select: { id: true, slug: true } });
    expect(new Map(ids.map((e) => [e.slug, e.id]))).toEqual(new Map(before.map((e) => [e.slug, e.id])));

    const removed = full[0];
    const partial = await seedCatalog(ctx.prisma, full.slice(1));
    expect(partial.softDeleted).toBe(1);
    const row = await ctx.prisma.exercise.findUniqueOrThrow({ where: { slug: removed.slug } });
    expect(row.deletedAt).not.toBeNull();
    expect(await ctx.prisma.exercise.count()).toBe(full.length);

    await seedCatalog(ctx.prisma);
    expect((await ctx.prisma.exercise.findUniqueOrThrow({ where: { slug: removed.slug } })).deletedAt).toBeNull();
    expect(await ctx.prisma.exerciseMuscle.count({ where: { exerciseId: row.id } })).toBe(removed.muscles.length);
  });
});
