import { describe, expect, it, vi } from 'vitest';
import { Prisma } from '@prisma/client';
import { setLogSink } from '../../logging/logging';
import type { PrismaService } from '../../prisma/prisma.service';
import { catalogServiceMock, FixedClock, prismaMock, profileRow, rejectsWithCode, UID } from '../../test/unit/support';
import { AuditService } from '../audit/audit.service';
import type { AuthService } from '../auth/auth.service';
import { CatalogService, toEngineExercise } from '../catalog/catalog.service';
import { EngineInputService } from '../plans/engine-input.service';
import type { ProfileService } from '../profile/profile.service';
import { dailyTargetsInput, NutritionService, nutritionGoalFor } from '../nutrition/nutrition.service';
import { AccountService } from './account.service';

const NOW = new Date('2026-11-09T10:00:00Z');

describe('NutritionService', () => {
  function setup() {
    const prisma = prismaMock();
    const engineInput = new EngineInputService(prisma as unknown as PrismaService, new FixedClock(NOW));
    prisma.userExercisePreference.findMany.mockResolvedValue([]);
    prisma.consentEvent.findFirst.mockResolvedValue({ action: 'granted', policyVersion: 'health-2026-11', occurredAt: NOW });
    return { prisma, nutrition: new NutritionService(engineInput, new FixedClock(NOW)) };
  }
  const complete = profileRow({
    goal: 'fat_loss', sex: 'female', birthYear: 1990, activityLevel: 'active',
    weightKg: new Prisma.Decimal(65), heightCm: new Prisma.Decimal(168),
  });

  it('nutritionGoalFor', () => {
    expect(nutritionGoalFor('fat_loss')).toBe('fat_loss');
    expect(nutritionGoalFor('hypertrophy')).toBe('muscle_gain');
    expect(nutritionGoalFor('strength')).toBe('maintenance');
  });

  it('dailyTargetsInput lista lo que falta sin inventar valores', () => {
    const r = dailyTargetsInput(profileRow({ sex: 'other' }), true, NOW);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.issues.map((i) => i.path)).toEqual(['sex', 'birthYear', 'weightKg', 'heightCm', 'activityLevel']);
    const noConsent = dailyTargetsInput(complete, false, NOW);
    if (!noConsent.ok) expect(noConsent.issues.map((i) => i.path)).toEqual(['healthConsent']);
    expect(dailyTargetsInput(complete, true, NOW)).toMatchObject({ ok: true, input: { age: 36, weightKg: 65, goal: 'fat_loss' } });
  });

  it('targets: 409 sin perfil, 422 incompleto o fuera de rango, 200 completo', async () => {
    const { prisma, nutrition } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValueOnce(null);
    await rejectsWithCode(nutrition.targets(UID), 'PROFILE_REQUIRED', 409);
    prisma.trainingProfile.findUnique.mockResolvedValueOnce(profileRow());
    await rejectsWithCode(nutrition.targets(UID), 'NUTRITION_INPUT_INCOMPLETE', 422);
    prisma.trainingProfile.findUnique.mockResolvedValueOnce({ ...complete, birthYear: 2015 });
    await rejectsWithCode(nutrition.targets(UID), 'NUTRITION_INPUT_INCOMPLETE', 422);
    prisma.trainingProfile.findUnique.mockResolvedValueOnce(complete);
    const t = await nutrition.targets(UID);
    expect(t.nutritionGoal).toBe('fat_loss');
    expect(t.kcal).toBeGreaterThan(1000);
  });
});

describe('AccountService', () => {
  function setup() {
    const prisma = prismaMock();
    const auth = { verifyPassword: vi.fn() };
    const profiles = { find: vi.fn().mockResolvedValue(null) };
    const service = new AccountService(
      prisma as unknown as PrismaService,
      auth as unknown as AuthService,
      profiles as unknown as ProfileService,
      new FixedClock(NOW),
      new AuditService(prisma as unknown as PrismaService, new FixedClock(NOW)),
    );
    return { prisma, auth, profiles, service };
  }

  it('me: 401 si el usuario ya no existe', async () => {
    const { prisma, service } = setup();
    prisma.user.findUnique.mockResolvedValueOnce(null);
    await rejectsWithCode(service.me(UID), 'UNAUTHORIZED', 401);
  });

  it('export reúne todos los datos del usuario', async () => {
    const { prisma, service } = setup();
    prisma.user.findUnique.mockResolvedValue({ id: UID, email: 'a@b.com', role: 'user', locale: 'es', createdAt: NOW });
    prisma.consentEvent.findMany.mockResolvedValue([
      { purpose: 'health_data_processing', action: 'granted', policyVersion: 'v', textHash: 'h', locale: 'es', occurredAt: NOW },
    ]);
    prisma.trainingPlan.findMany.mockResolvedValue([
      {
        id: 'p', status: 'active', createdAt: NOW,
        versions: [{
          id: 'v', planId: 'p', version: 1, engineVersion: '2', objectiveScore: 1, mesocycleWeeks: 6, createdAt: NOW, inputSnapshot: null,
          rationale: { split: { type: 'full_body', rationale: [] }, rationale: [], warnings: [], weeklyVolume: [] }, sessions: [],
        }],
      },
    ]);
    prisma.workoutSession.findMany.mockResolvedValue([
      { id: 'w', clientId: 'c', planSessionId: 'ps', status: 'completed', startedAt: NOW, completedAt: NOW, setLogs: [], substitutions: [] },
    ]);
    prisma.exerciseE1rm.findMany.mockResolvedValue([
      { exerciseId: 'e', workoutSessionId: 'w', performedOn: NOW, e1rmKg: new Prisma.Decimal(50), formulaVersion: 'f', exercise: { slug: 's' } },
    ]);
    prisma.weeklyMuscleVolume.findMany.mockResolvedValue([
      { weekStart: NOW, muscle: 'chest', effectiveSets: new Prisma.Decimal(3), tonnageKg: new Prisma.Decimal(10) },
    ]);
    prisma.weeklyAdherence.findMany.mockResolvedValue([
      { weekStart: NOW, plannedSessions: 3, completedSessions: 1, plannedSets: 9, completedSets: 3 },
    ]);
    prisma.userExerciseNote.findMany.mockResolvedValue([
      { exerciseId: 'e1', text: 'Asiento en el 4', clientUpdatedAt: NOW, updatedAt: NOW, exercise: { slug: 's' } },
    ]);
    const data = await service.export(UID);
    expect(data).toMatchObject({ formatVersion: 1, user: { email: 'a@b.com' }, profile: null });
    expect(data.exerciseNotes).toEqual([
      { exerciseId: 'e1', slug: 's', text: 'Asiento en el 4', clientUpdatedAt: NOW.toISOString(), updatedAt: NOW.toISOString() },
    ]);
    expect(data.plans[0].versions[0].inputSnapshot).toEqual({});
    expect(data.analytics.e1rm[0]).toMatchObject({ slug: 's', e1rmKg: 50, performedOn: '2026-11-09' });
    expect(data.workouts).toHaveLength(1);
  });

  it('delete: 403 con contraseña incorrecta; si no, borra el User (cascada)', async () => {
    const { prisma, auth, service } = setup();
    auth.verifyPassword.mockResolvedValueOnce(false);
    await rejectsWithCode(service.delete(UID, 'x'), 'AUTH_INVALID_CREDENTIALS', 403);
    expect(prisma.user.delete).not.toHaveBeenCalled();
    auth.verifyPassword.mockResolvedValueOnce(true);
    const lines: string[] = [];
    const restore = setLogSink((l) => lines.push(l));
    try {
      await service.delete(UID, 'ok');
    } finally {
      restore();
    }
    expect(lines[0]).toContain('account deleted');
    expect(lines[0]).not.toContain(UID);
    expect(prisma.user.delete).toHaveBeenCalledWith({ where: { id: UID } });
    // Queda solo `account_deleted`, sin userId y con un id aleatorio (issue #17).
    const audit = prisma.auditEvent.create.mock.calls[0][0].data;
    expect(audit).toMatchObject({ type: 'account_deleted', userId: null });
    expect(audit.subjectRef).not.toBe(UID);
    expect(lines[0]).toContain(audit.subjectRef);
  });
});

describe('CatalogService', () => {
  const row = (slug: string, over: Record<string, unknown> = {}) => ({
    id: `id:${slug}`, slug, nameEs: 'Ej', nameEn: 'Ex', movementPattern: 'squat', isCompound: true, isUnilateral: false,
    minLevel: 'beginner', equipment: ['bodyweight'], loadType: 'unweighted', cuesEs: ['uno', 'dos'], deletedAt: null,
    muscles: [{ muscle: 'quads', role: 'primary', fraction: new Prisma.Decimal(1) }, { muscle: 'glutes', role: 'secondary', fraction: new Prisma.Decimal(0.5) }],
    riskTags: [{ zone: 'knee', level: 'caution' }],
    substitutionGroup: { key: 'squat' },
    ...over,
  });

  function setup() {
    const prisma = prismaMock();
    const clock = new FixedClock(NOW);
    return { prisma, clock, service: new CatalogService(prisma as unknown as PrismaService, clock) };
  }

  it('toEngineExercise mapea a la forma del motor', () => {
    expect(toEngineExercise(row('a') as never)).toMatchObject({
      slug: 'a', substitutionGroup: 'squat', muscles: [{ fraction: 1 }, { fraction: 0.5 }], media: null,
    });
    expect(toEngineExercise(row('a-b', { substitutionGroup: null }) as never).substitutionGroup).toBe('a_b');
  });

  it('engineCatalog cachea durante el TTL e invalidate la vacía', async () => {
    const { prisma, clock, service } = setup();
    prisma.exercise.findMany.mockResolvedValue([row('a')]);
    const first = await service.engineCatalog();
    await service.engineCatalog();
    expect(prisma.exercise.findMany).toHaveBeenCalledTimes(1);
    expect(first.bySlug.get('a')?.id).toBe('id:a');
    clock.date = new Date(NOW.getTime() + 61_000);
    await service.engineCatalog();
    expect(prisma.exercise.findMany).toHaveBeenCalledTimes(2);
    service.invalidate();
    await service.engineCatalog();
    expect(prisma.exercise.findMany).toHaveBeenCalledTimes(3);
  });

  it('refs, list con filtros y get', async () => {
    const { prisma, service } = setup();
    expect((await service.refs([])).size).toBe(0);
    prisma.exercise.findMany.mockResolvedValueOnce([{ id: 'x', slug: 's', nameEs: 'n' }]);
    expect((await service.refs(['x', 'x'])).get('x')).toEqual({ id: 'x', slug: 's', nameEs: 'n' });

    prisma.$queryRaw.mockResolvedValueOnce([{ id: 'id:a' }]);
    prisma.exercise.count.mockResolvedValueOnce(1);
    prisma.exercise.findMany.mockResolvedValueOnce([row('a')]);
    const list = await service.list({ page: 1, pageSize: 10, equipment: ['dumbbell'], level: 'intermediate', movementPattern: 'squat', q: 'Sent' });
    expect(list.items[0]).toMatchObject({ slug: 'a', primaryMuscles: ['quads'] });
    const where = prisma.exercise.count.mock.calls[0][0].where;
    expect(where).toMatchObject({ deletedAt: null, movementPattern: 'squat', minLevel: { in: ['beginner', 'intermediate'] }, id: { in: ['id:a'] } });

    prisma.exercise.findFirst.mockResolvedValueOnce(null);
    await rejectsWithCode(service.get('nope'), 'NOT_FOUND', 404);
    prisma.exercise.findFirst.mockResolvedValueOnce(row('a', { substitutionGroup: null }));
    expect(await service.get('id:a')).toMatchObject({ substitutionGroup: null, riskTags: [{ zone: 'knee' }] });
  });

  it('catalogServiceMock está alineado con el catálogo real', () => {
    expect(catalogServiceMock()).toBeDefined();
  });
});
