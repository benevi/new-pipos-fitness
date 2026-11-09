import request from 'supertest';
import { loadCatalog } from '@pipos/catalog';
import { ExerciseListResponseSchema, MUSCLES, type ExerciseSummary } from '@pipos/contracts';
import { createTestApp, truncateAll, type TestContext } from './helpers';

/** Biblioteca por músculo (ADR-0014, Fase 3): `GET /exercises?muscle=…&role=…`. */
describe('Biblioteca por músculo (e2e, Postgres real)', () => {
  let ctx: TestContext;
  const server = () => ctx.app.getHttpServer();
  const catalog = loadCatalog();
  const LEVEL_RANK = { beginner: 0, intermediate: 1, advanced: 2 } as const;

  const slugsWith = (muscle: string, role: 'primary' | 'secondary', equipment?: string[]) =>
    catalog
      .filter((e) => e.muscles.some((m) => m.muscle === muscle && m.role === role))
      .filter((e) => !equipment || e.equipment.every((q) => q === 'bodyweight' || equipment.includes(q)))
      .map((e) => e.slug)
      .sort();

  beforeAll(async () => {
    ctx = await createTestApp();
  });
  beforeEach(async () => {
    await truncateAll(ctx.prisma);
  });
  afterAll(async () => {
    await ctx.app.close();
  });

  it('rol principal por defecto: exactamente los ejercicios del catálogo, ordenados por nivel', async () => {
    const res = await request(server()).get('/exercises?muscle=glutes&pageSize=100').expect(200);
    expect(ExerciseListResponseSchema.safeParse(res.body).success).toBe(true);
    const items = res.body.items as ExerciseSummary[];
    expect(items.map((e) => e.slug).sort()).toEqual(slugsWith('glutes', 'primary'));
    expect(res.body.total).toBe(items.length);
    for (const e of items) expect(e.primaryMuscles).toContain('glutes');
    const ranks = items.map((e) => LEVEL_RANK[e.minLevel]);
    expect(ranks).toEqual([...ranks].sort((a, b) => a - b));
  });

  it('rol secundario explícito', async () => {
    const res = await request(server()).get('/exercises?muscle=triceps&role=secondary&pageSize=100').expect(200);
    const items = res.body.items as ExerciseSummary[];
    expect(items.length).toBeGreaterThan(0);
    expect(items.map((e) => e.slug).sort()).toEqual(slugsWith('triceps', 'secondary'));
    for (const e of items) expect(e.primaryMuscles).not.toContain('triceps');
  });

  it('combinado con el material del usuario', async () => {
    const equipment = ['dumbbell', 'bench'];
    const res = await request(server())
      .get(`/exercises?muscle=chest&equipment=${equipment.join(',')}&pageSize=100`)
      .expect(200);
    const items = res.body.items as ExerciseSummary[];
    expect(items.length).toBeGreaterThan(0);
    expect(items.map((e) => e.slug).sort()).toEqual(slugsWith('chest', 'primary', equipment));
    for (const e of items) expect(e.equipment.every((q) => q === 'bodyweight' || equipment.includes(q))).toBe(true);
    // Todo el catálogo da más ejercicios que el material de casa.
    const all = await request(server()).get('/exercises?muscle=chest&pageSize=100').expect(200);
    expect(all.body.total).toBeGreaterThan(res.body.total);
  });

  it('los 19 músculos responden y cada ejercicio activo aparece en la lista de sus principales', async () => {
    const seen = new Set<string>();
    for (const muscle of MUSCLES) {
      const res = await request(server()).get(`/exercises?muscle=${muscle}&pageSize=100`).expect(200);
      expect(res.body.total).toBe(slugsWith(muscle, 'primary').length);
      for (const e of res.body.items as ExerciseSummary[]) seen.add(e.slug);
    }
    expect(seen.size).toBe(catalog.length);
  });

  it('un músculo o un rol inválidos devuelven 400', async () => {
    const bad = await request(server()).get('/exercises?muscle=pecho').expect(400);
    expect(bad.body.code).toBe('VALIDATION_FAILED');
    await request(server()).get('/exercises?muscle=chest&role=main').expect(400);
  });
});
