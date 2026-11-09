import { describe, expect, it, vi } from 'vitest';
import { Prisma } from '@prisma/client';
import type { PrismaService } from '../../prisma/prisma.service';
import {
  catalogServiceMock,
  FixedClock,
  grantedEvent,
  prismaMock,
  profileRow,
  rejectsWithCode,
  UID,
} from '../../test/unit/support';
import type { CatalogService } from '../catalog/catalog.service';
import { ageFrom, buildEngineProfile, EngineInputService, toTrainingHistory } from './engine-input.service';
import { PLAN_VERSION_MAX_ATTEMPTS, PlansService } from './plans.service';

const p2002 = () => new Prisma.PrismaClientKnownRequestError('dup', { code: 'P2002', clientVersion: '5' });

function setup() {
  const prisma = prismaMock();
  const clock = new FixedClock();
  const catalog = catalogServiceMock();
  const engineInput = new EngineInputService(prisma as unknown as PrismaService, clock);
  const plans = new PlansService(prisma as unknown as PrismaService, catalog as unknown as CatalogService, engineInput);
  prisma.setLog.findMany.mockResolvedValue([]);
  return { prisma, clock, catalog, engineInput, plans };
}

const versionRow = (over: Record<string, unknown> = {}) => ({
  id: 'v1',
  planId: 'p1',
  userId: UID,
  version: 1,
  engineVersion: '2.0.0',
  objectiveScore: 0.8,
  mesocycleWeeks: 6,
  createdAt: new Date('2026-11-09T10:00:00Z'),
  rationale: { split: { type: 'full_body', rationale: ['r'] }, rationale: ['x'], warnings: [], weeklyVolume: [], muscleVolume: [], score: {}, meta: {} },
  inputSnapshot: {},
  sessions: [],
  _count: { sessions: 3 },
  ...over,
});

describe('EngineInputService', () => {
  it('buildEngineProfile: sin consentimiento no pasa limitaciones, peso ni altura', () => {
    const row = profileRow({ limitations: ['knee'], weightKg: new Prisma.Decimal(80), heightCm: new Prisma.Decimal(180), birthYear: 1990, sex: 'male' });
    const now = new Date('2026-11-09T10:00:00Z');
    const without = buildEngineProfile(row, ['b'], ['a'], false, now);
    expect(without.limitations).toEqual([]);
    expect(without.body).toEqual({ age: 36, sex: 'male' });
    const withConsent = buildEngineProfile(row, [], [], true, now);
    expect(withConsent.limitations).toEqual(['knee']);
    expect(withConsent.body).toEqual({ weightKg: 80, heightCm: 180, age: 36, sex: 'male' });
    expect(buildEngineProfile(profileRow(), [], [], true, now).body).toBeUndefined();
    expect(ageFrom(null, now, 'UTC')).toBeNull();
  });

  it('toTrainingHistory agrupa por entrenamiento y ejercicio con fecha local', () => {
    const startedAt = new Date('2026-11-08T23:30:00Z'); // 9 nov en Madrid
    const h = toTrainingHistory(
      [
        { workoutSessionId: 'w', reps: 8, loadKg: 40, rir: 2, isWarmup: false, exercise: { slug: 'a' }, workoutSession: { startedAt } },
        { workoutSessionId: 'w', reps: 5, loadKg: 20, rir: null, isWarmup: true, exercise: { slug: 'a' }, workoutSession: { startedAt } },
      ],
      'Europe/Madrid',
    );
    expect(h.entries).toEqual([{ date: '2026-11-09', exerciseId: 'a', sets: [{ reps: 8, loadKg: 40, rir: 2 }, { reps: 5, loadKg: 20, isWarmup: true }] }]);
  });

  it('load: null sin perfil; con perfil devuelve preferencias y consentimiento', async () => {
    const { prisma, engineInput } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValueOnce(null);
    expect(await engineInput.load(UID)).toBeNull();
    prisma.trainingProfile.findUnique.mockResolvedValueOnce(profileRow({ limitations: ['knee'] }));
    prisma.userExercisePreference.findMany.mockResolvedValueOnce([
      { kind: 'banned', exercise: { slug: 'x' } },
      { kind: 'favourite', exercise: { slug: 'y' } },
    ]);
    prisma.consentEvent.findFirst.mockResolvedValueOnce(grantedEvent());
    const ctx = await engineInput.load(UID);
    expect(ctx?.bannedSlugs).toEqual(['x']);
    expect(ctx?.favouriteSlugs).toEqual(['y']);
    expect(ctx?.consent.granted).toBe(true);
    expect(ctx?.engineProfile.limitations).toEqual(['knee']);
  });

  it('history filtra por ejercicios y excluye el entrenamiento en curso', async () => {
    const { prisma, engineInput } = setup();
    await engineInput.history(UID, 'UTC', { exerciseIds: ['e'], excludeWorkoutId: 'w' });
    const where = prisma.setLog.findMany.mock.calls[0][0].where;
    expect(where.exerciseId).toEqual({ in: ['e'] });
    expect(where.workoutSession.id).toEqual({ not: 'w' });
  });
});

describe('PlansService', () => {
  const engineProfile = buildEngineProfile(profileRow(), [], [], false, new Date('2026-11-09T10:00:00Z'));

  it('prepare: ejecuta el motor y mapea al catálogo; perfil imposible → 422', async () => {
    const { plans } = setup();
    const prepared = await plans.prepare(UID, engineProfile, 'UTC');
    expect(prepared.sessions).toHaveLength(3);
    expect(prepared.draft.sessions[0].exercises.length).toBeGreaterThan(0);
    await rejectsWithCode(plans.prepare(UID, { ...engineProfile, daysPerWeek: 9 }, 'UTC'), 'PLAN_GENERATION_FAILED', 422);
  });

  it('prepare: catálogo inválido → 500', async () => {
    const { plans, catalog } = setup();
    catalog.engineCatalog.mockResolvedValueOnce({ exercises: [{ slug: 'x' }], bySlug: new Map(), byId: new Map() });
    await rejectsWithCode(plans.prepare(UID, engineProfile, 'UTC'), 'PLAN_GENERATION_FAILED', 500);
  });

  it('persistVersion: crea el plan si no hay y numera la versión siguiente', async () => {
    const { plans, prisma } = setup();
    const prepared = await plans.prepare(UID, engineProfile, 'UTC');
    prisma.trainingPlan.findFirst.mockResolvedValueOnce(null);
    prisma.trainingPlan.create.mockResolvedValueOnce({ id: 'p1' });
    prisma.planVersion.aggregate.mockResolvedValueOnce({ _max: { version: 4 } });
    prisma.planVersion.create.mockResolvedValueOnce(versionRow({ version: 5 }));
    const summary = await plans.persistVersion(prisma as never, UID, prepared);
    expect(summary).toMatchObject({ version: 5, sessionCount: 3, splitType: 'full_body' });
    const data = prisma.planVersion.create.mock.calls[0][0].data;
    expect(data.version).toBe(5);
    expect(data.sessions.create).toHaveLength(3);

    prisma.trainingPlan.findFirst.mockResolvedValueOnce({ id: 'p1' });
    prisma.planVersion.aggregate.mockResolvedValueOnce({ _max: { version: null } });
    prisma.planVersion.create.mockResolvedValueOnce(versionRow());
    await plans.persistVersion(prisma as never, UID, prepared);
    expect(prisma.planVersion.create.mock.calls[1][0].data.version).toBe(1);
  });

  it('withVersionRetry: reintenta P2002 y al final devuelve 409; otros errores se propagan', async () => {
    const { plans, prisma } = setup();
    const work = vi.fn().mockRejectedValueOnce(p2002()).mockResolvedValueOnce('ok');
    expect(await plans.withVersionRetry(work)).toBe('ok');
    expect(work).toHaveBeenCalledTimes(2);
    const always = vi.fn().mockRejectedValue(p2002());
    await rejectsWithCode(plans.withVersionRetry(always), 'PLAN_VERSION_CONFLICT', 409);
    expect(always).toHaveBeenCalledTimes(PLAN_VERSION_MAX_ATTEMPTS);
    prisma.$transaction.mockRejectedValueOnce(new Error('boom'));
    await expect(plans.withVersionRetry(vi.fn())).rejects.toThrow('boom');
  });

  it('generate: sin perfil → 409; con perfil persiste y devuelve la versión', async () => {
    const { plans, prisma } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValueOnce(null);
    await rejectsWithCode(plans.generate(UID), 'PROFILE_REQUIRED', 409);

    prisma.trainingProfile.findUnique.mockResolvedValueOnce(profileRow());
    prisma.userExercisePreference.findMany.mockResolvedValueOnce([]);
    prisma.consentEvent.findFirst.mockResolvedValueOnce(null);
    prisma.trainingPlan.findFirst.mockResolvedValueOnce({ id: 'p1' });
    prisma.planVersion.aggregate.mockResolvedValueOnce({ _max: { version: 1 } });
    prisma.planVersion.create.mockResolvedValueOnce(versionRow({ id: 'v2', version: 2 }));
    prisma.planVersion.findFirst.mockResolvedValueOnce(versionRow({ id: 'v2', version: 2 }));
    const res = await plans.generate(UID);
    expect(res.version).toBe(2);
  });

  it('current, versions, version (propiedad → 404)', async () => {
    const { plans, prisma } = setup();
    prisma.planVersion.findFirst.mockResolvedValueOnce(null);
    await rejectsWithCode(plans.current(UID), 'PLAN_REQUIRED', 404);
    prisma.planVersion.findFirst.mockResolvedValueOnce({ id: 'v1' }).mockResolvedValueOnce(versionRow());
    expect((await plans.current(UID)).id).toBe('v1');

    prisma.planVersion.count.mockResolvedValueOnce(1);
    prisma.planVersion.findMany.mockResolvedValueOnce([versionRow()]);
    const list = await plans.versions(UID, { page: 2, pageSize: 5 });
    expect(list).toMatchObject({ page: 2, pageSize: 5, total: 1 });
    expect(prisma.planVersion.findMany.mock.calls[0][0]).toMatchObject({ skip: 5, take: 5, where: { userId: UID } });

    prisma.planVersion.findFirst.mockResolvedValueOnce(null);
    await rejectsWithCode(plans.version(UID, 'other'), 'NOT_FOUND', 404);
    prisma.trainingPlan.count.mockResolvedValueOnce(1);
    expect(await plans.hasActivePlan(UID)).toBe(true);
  });
});
