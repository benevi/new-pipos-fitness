import { describe, expect, it, vi } from 'vitest';
import { Prisma } from '@prisma/client';
import type { PrismaService } from '../../prisma/prisma.service';
import { catalogServiceMock, FixedClock, prismaMock, profileRow, rejectsWithCode, UID } from '../../test/unit/support';
import type { AnalyticsService } from '../analytics/analytics.service';
import type { CatalogService } from '../catalog/catalog.service';
import { EngineInputService } from '../plans/engine-input.service';
import { currentLoad, SessionsService, weeksSinceDeload } from './sessions.service';
import { WorkoutsService } from './workouts.service';

const NOW = new Date('2026-11-09T10:00:00.000Z');
const W = 'w1';
const workoutRow = (over: Record<string, unknown> = {}) => ({
  id: W, clientId: 'c1', userId: UID, planSessionId: 'ps1', status: 'in_progress', startedAt: NOW, completedAt: null,
  setLogs: [], substitutions: [], ...over,
});
const setRow = (over: Record<string, unknown> = {}) => ({
  id: 's1', clientId: 'sc1', userId: UID, workoutSessionId: W, planExerciseId: 'pe1', exerciseId: 'id:press-banca-barra',
  setIndex: 0, reps: 8, loadKg: new Prisma.Decimal(40), rir: 2, isWarmup: false, completedAt: NOW,
  clientUpdatedAt: NOW, deletedAt: null, createdAt: NOW, updatedAt: NOW, ...over,
});
const p2002 = () => new Prisma.PrismaClientKnownRequestError('dup', { code: 'P2002', clientVersion: '5' });

function setup() {
  const prisma = prismaMock();
  const clock = new FixedClock(NOW);
  const analytics = { lockUser: vi.fn(), onSetChanged: vi.fn(), onWorkoutFinished: vi.fn() };
  const catalog = catalogServiceMock();
  const engineInput = new EngineInputService(prisma as unknown as PrismaService, clock);
  const service = new WorkoutsService(
    prisma as unknown as PrismaService,
    analytics as unknown as AnalyticsService,
    catalog as unknown as CatalogService,
    engineInput,
    clock,
  );
  const sessions = new SessionsService(prisma as unknown as PrismaService, catalog as unknown as CatalogService, engineInput, clock);
  prisma.userExercisePreference.findMany.mockResolvedValue([]);
  prisma.consentEvent.findFirst.mockResolvedValue(null);
  prisma.setLog.findMany.mockResolvedValue([]);
  return { prisma, analytics, service, sessions, catalog };
}

const startBody = { clientId: 'c1', planSessionId: 'ps1', startedAt: NOW.toISOString() };
const setBody = {
  clientId: 'sc1', planExerciseId: 'pe1', exerciseId: 'id:press-banca-barra', setIndex: 0, reps: 8, loadKg: 40, rir: 2,
  isWarmup: false, completedAt: NOW.toISOString(),
};

describe('WorkoutsService.start', () => {
  it('reenvío del mismo clientId → existente (created=false); con otra sesión → 409', async () => {
    const { prisma, service } = setup();
    prisma.workoutSession.findUnique.mockResolvedValue(workoutRow());
    expect((await service.start(UID, startBody)).created).toBe(false);
    await rejectsWithCode(service.start(UID, { ...startBody, planSessionId: 'other' }), 'CLIENT_ID_CONFLICT', 409);
  });

  it('sesión ajena → 404; otro en curso → 409; crea → 201', async () => {
    const { prisma, service } = setup();
    prisma.workoutSession.findUnique.mockResolvedValue(null);
    prisma.planSession.findFirst.mockResolvedValueOnce(null);
    await rejectsWithCode(service.start(UID, startBody), 'NOT_FOUND', 404);
    prisma.planSession.findFirst.mockResolvedValue({ id: 'ps1' });
    prisma.workoutSession.findFirst.mockResolvedValueOnce({ id: 'w0' });
    await rejectsWithCode(service.start(UID, startBody), 'WORKOUT_IN_PROGRESS', 409);
    prisma.workoutSession.findFirst.mockResolvedValueOnce(null);
    prisma.workoutSession.create.mockResolvedValueOnce(workoutRow());
    const res = await service.start(UID, startBody);
    expect(res.created).toBe(true);
    expect(res.value.startedAt).toBe(NOW.toISOString());
  });

  it('carrera P2002: devuelve la del mismo clientId o 409; otros errores se propagan', async () => {
    const { prisma, service } = setup();
    prisma.planSession.findFirst.mockResolvedValue({ id: 'ps1' });
    prisma.workoutSession.findFirst.mockResolvedValue(null);
    prisma.workoutSession.findUnique.mockResolvedValueOnce(null).mockResolvedValueOnce(workoutRow());
    prisma.workoutSession.create.mockRejectedValueOnce(p2002());
    expect((await service.start(UID, startBody)).created).toBe(false);

    prisma.workoutSession.findUnique.mockResolvedValue(null);
    prisma.workoutSession.create.mockRejectedValueOnce(p2002());
    await rejectsWithCode(service.start(UID, startBody), 'WORKOUT_IN_PROGRESS');
    prisma.workoutSession.create.mockRejectedValueOnce(new Error('x'));
    await expect(service.start(UID, startBody)).rejects.toThrow('x');
  });

  it('get: 404 si no es suyo', async () => {
    const { prisma, service } = setup();
    prisma.workoutSession.findFirst.mockResolvedValueOnce(null);
    await rejectsWithCode(service.get(UID, W), 'NOT_FOUND', 404);
  });
});

describe('WorkoutsService.sets', () => {
  it('upsertSet: idempotente, conflicto de clientId, terminado, validaciones e inserción con analítica', async () => {
    const { prisma, analytics, service } = setup();
    prisma.workoutSession.findFirst.mockResolvedValue(workoutRow());
    prisma.setLog.findUnique.mockResolvedValueOnce(setRow());
    expect((await service.upsertSet(UID, W, setBody)).created).toBe(false);
    prisma.setLog.findUnique.mockResolvedValueOnce(setRow({ workoutSessionId: 'other' }));
    await rejectsWithCode(service.upsertSet(UID, W, setBody), 'CLIENT_ID_CONFLICT', 409);

    prisma.setLog.findUnique.mockResolvedValue(null);
    prisma.workoutSession.findFirst.mockResolvedValueOnce(workoutRow({ status: 'completed' }));
    await rejectsWithCode(service.upsertSet(UID, W, setBody), 'WORKOUT_FINISHED', 409);

    prisma.exercise.findUnique.mockResolvedValueOnce(null);
    await rejectsWithCode(service.upsertSet(UID, W, setBody), 'VALIDATION_FAILED', 400);
    prisma.exercise.findUnique.mockResolvedValue({ id: 'x' });
    prisma.planExercise.findFirst.mockResolvedValueOnce(null);
    await rejectsWithCode(service.upsertSet(UID, W, setBody), 'VALIDATION_FAILED');

    prisma.planExercise.findFirst.mockResolvedValueOnce({ exerciseId: 'otro', substitutions: [] });
    await rejectsWithCode(service.upsertSet(UID, W, setBody), 'VALIDATION_FAILED');
    prisma.planExercise.findFirst.mockResolvedValue({ exerciseId: 'otro', substitutions: [{ exerciseId: 'id:press-banca-barra' }] });
    prisma.setLog.createMany.mockResolvedValueOnce({ count: 1 });
    prisma.setLog.findUniqueOrThrow.mockResolvedValueOnce(setRow());
    const created = await service.upsertSet(UID, W, setBody);
    expect(created.created).toBe(true);
    expect(created.value.loadKg).toBe(40);
    expect(analytics.lockUser).toHaveBeenCalled();
    expect(analytics.onSetChanged).toHaveBeenCalledTimes(1);
    expect(prisma.setLog.createMany.mock.calls[0][0].skipDuplicates).toBe(true);

    // Libre (sin hueco del plan) y carrera perdida en el INSERT: no recalcula.
    prisma.setLog.createMany.mockResolvedValueOnce({ count: 0 });
    prisma.setLog.findUniqueOrThrow.mockResolvedValueOnce(setRow({ planExerciseId: null }));
    expect((await service.upsertSet(UID, W, { ...setBody, planExerciseId: null })).created).toBe(false);
    expect(analytics.onSetChanged).toHaveBeenCalledTimes(1);
  });

  it('patchSet: última escritura gana; borrada no cambia; 404 si no es de ese entrenamiento', async () => {
    const { prisma, analytics, service } = setup();
    prisma.workoutSession.findFirst.mockResolvedValue(workoutRow());
    const later = new Date(NOW.getTime() + 1000).toISOString();
    prisma.setLog.findUnique.mockResolvedValueOnce(null);
    await rejectsWithCode(service.patchSet(UID, W, 'sc1', { reps: 1, clientUpdatedAt: later }), 'NOT_FOUND', 404);
    prisma.setLog.findUnique.mockResolvedValueOnce(setRow());
    expect((await service.patchSet(UID, W, 'sc1', { reps: 1, clientUpdatedAt: NOW.toISOString() })).reps).toBe(8);
    prisma.setLog.findUnique.mockResolvedValueOnce(setRow({ deletedAt: NOW }));
    expect((await service.patchSet(UID, W, 'sc1', { reps: 1, clientUpdatedAt: later })).reps).toBe(8);
    prisma.setLog.findUnique.mockResolvedValueOnce(setRow());
    prisma.setLog.update.mockResolvedValueOnce(setRow({ reps: 6, loadKg: new Prisma.Decimal(42.5), rir: null, isWarmup: true }));
    const res = await service.patchSet(UID, W, 'sc1', { reps: 6, loadKg: 42.5, rir: null, isWarmup: true, clientUpdatedAt: later });
    expect(res).toMatchObject({ reps: 6, loadKg: 42.5, isWarmup: true });
    expect(analytics.onSetChanged).toHaveBeenCalledTimes(1);
  });

  it('deleteSet: borrado lógico idempotente', async () => {
    const { prisma, analytics, service } = setup();
    prisma.workoutSession.findFirst.mockResolvedValue(workoutRow());
    prisma.setLog.findUnique.mockResolvedValueOnce(setRow({ deletedAt: NOW }));
    expect((await service.deleteSet(UID, W, 'sc1')).deletedAt).toBe(NOW.toISOString());
    expect(prisma.setLog.update).not.toHaveBeenCalled();
    prisma.setLog.findUnique.mockResolvedValueOnce(setRow());
    prisma.setLog.update.mockResolvedValueOnce(setRow({ deletedAt: NOW }));
    await service.deleteSet(UID, W, 'sc1');
    expect(prisma.setLog.update.mock.calls[0][0].data.deletedAt).toEqual(NOW);
    expect(analytics.onSetChanged).toHaveBeenCalledTimes(1);
  });

  it('finish: 409 si ya terminado, 400 si acaba antes de empezar, si no cierra y recalcula', async () => {
    const { prisma, analytics, service } = setup();
    prisma.workoutSession.findFirst.mockResolvedValueOnce(workoutRow({ status: 'completed' }));
    await rejectsWithCode(service.finish(UID, W, { completedAt: NOW.toISOString() }), 'WORKOUT_FINISHED', 409);
    prisma.workoutSession.findFirst.mockResolvedValueOnce(workoutRow());
    await rejectsWithCode(service.finish(UID, W, { completedAt: new Date(NOW.getTime() - 1).toISOString() }), 'VALIDATION_FAILED');
    prisma.workoutSession.findFirst
      .mockResolvedValueOnce(workoutRow())
      .mockResolvedValueOnce(workoutRow({ status: 'completed', completedAt: NOW }));
    const res = await service.finish(UID, W, { completedAt: NOW.toISOString() });
    expect(res.status).toBe('completed');
    expect(analytics.onWorkoutFinished).toHaveBeenCalled();
  });
});

describe('WorkoutsService.substitutes', () => {
  it('substitutesFor: 404 ejercicio, 409 sin perfil, 3 alternativas', async () => {
    const { prisma, service } = setup();
    await rejectsWithCode(service.substitutesFor(UID, 'nope'), 'NOT_FOUND', 404);
    prisma.trainingProfile.findUnique.mockResolvedValueOnce(null);
    await rejectsWithCode(service.substitutesFor(UID, 'id:press-banca-barra'), 'PROFILE_REQUIRED', 409);
    prisma.trainingProfile.findUnique.mockResolvedValue(profileRow());
    const res = await service.substitutesFor(UID, 'id:press-banca-barra');
    expect(res.substitutes.length).toBeGreaterThan(0);
    expect(res.substitutes.length).toBeLessThanOrEqual(3);
    expect(res.substitutes.every((s) => s.exerciseId.startsWith('id:'))).toBe(true);
  });

  it('substitute: terminado 409, hueco ajeno 404, vuelta al original, inválido 400 y válido', async () => {
    const { prisma, service } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValue(profileRow());
    prisma.workoutSession.findFirst.mockResolvedValueOnce(workoutRow({ status: 'completed' }));
    await rejectsWithCode(service.substitute(UID, W, 'pe1', 'x'), 'WORKOUT_FINISHED', 409);
    prisma.workoutSession.findFirst.mockResolvedValue(workoutRow());
    prisma.planExercise.findFirst.mockResolvedValueOnce(null);
    await rejectsWithCode(service.substitute(UID, W, 'pe1', 'x'), 'NOT_FOUND', 404);

    const original = { id: 'id:press-banca-barra', slug: 'press-banca-barra', nameEs: 'Press' };
    prisma.planExercise.findFirst.mockResolvedValue({ id: 'pe1', exercise: original });
    const back = await service.substitute(UID, W, 'pe1', original.id);
    expect(back.exercise).toEqual(original);
    expect(prisma.workoutSubstitution.deleteMany).toHaveBeenCalled();

    await rejectsWithCode(service.substitute(UID, W, 'pe1', 'id:sentadilla-trasera-barra'), 'VALIDATION_FAILED', 400);
    const valid = (await service.substitutesFor(UID, original.id)).substitutes[0];
    const res = await service.substitute(UID, W, 'pe1', valid.exerciseId);
    expect(res.exercise.id).toBe(valid.exerciseId);
    expect(prisma.workoutSubstitution.upsert).toHaveBeenCalled();
  });
});

describe('SessionsService', () => {
  it('weeksSinceDeload y currentLoad', () => {
    expect(weeksSinceDeload('2026-11-01', '2026-11-09')).toBe(1);
    expect(weeksSinceDeload('2026-09-01', '2026-11-09')).toBe(9 % 7);
    expect(currentLoad('unweighted', 5, [])).toBe(5);
    expect(currentLoad('weighted', null, [])).toBeNull();
    const h = [
      { date: '2026-11-01', exerciseId: 'a', sets: [{ reps: 8, loadKg: 40 }] },
      { date: '2026-11-05', exerciseId: 'a', sets: [{ reps: 8, loadKg: 45 }, { reps: 5, loadKg: 60, isWarmup: true }] },
    ];
    expect(currentLoad('weighted', 30, h)).toBe(45);
    expect(currentLoad('weighted', 30, [{ date: '2026-11-05', exerciseId: 'a', sets: [{ reps: 8, loadKg: 0 }] }])).toBe(30);
  });

  it('today: sin perfil 409, sin plan 404', async () => {
    const { prisma, sessions } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValueOnce(null);
    await rejectsWithCode(sessions.today(UID), 'PROFILE_REQUIRED', 409);
    prisma.trainingProfile.findUnique.mockResolvedValue(profileRow());
    prisma.planVersion.findFirst.mockResolvedValueOnce(null);
    await rejectsWithCode(sessions.today(UID), 'PLAN_REQUIRED', 404);
  });

  const slot = (over: Record<string, unknown> = {}) => ({
    id: 'pe1', order: 0, exerciseId: 'id:press-banca-barra', role: 'main', sets: 3, repMin: 6, repMax: 10, targetRir: 2,
    restSeconds: 120, initialLoadKg: new Prisma.Decimal(40), warmupSets: [{ reps: 5, loadPct: 50 }],
    exercise: { id: 'id:press-banca-barra', slug: 'press-banca-barra', nameEs: 'Press', cuesEs: ['a', 'b'], movementPattern: 'horizontal_push', loadType: 'weighted' },
    ...over,
  });
  const planSession = { id: 'ps1', order: 1, dayIndex: 2, kind: 'full_body', name: 'Día 2', targetMinutes: 45, estimatedMinutes: 44, rationale: ['r'], exercises: [slot()] };

  it('today sin entrenamiento: siguiente sesión pendiente y prescripción inicial', async () => {
    const { prisma, sessions } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValue(profileRow());
    prisma.planVersion.findFirst.mockResolvedValue({
      id: 'v1', plan: { createdAt: new Date('2026-11-01T00:00:00Z') },
      sessions: [{ id: 'ps0', order: 0 }, { id: 'ps1', order: 1 }, { id: 'ps2', order: 2 }],
    });
    prisma.workoutSession.findFirst.mockResolvedValue(null);
    prisma.workoutSession.findMany.mockResolvedValue([{ planSession: { order: 0 } }]);
    prisma.planSession.findFirstOrThrow.mockResolvedValue(planSession);
    const res = await sessions.today(UID);
    expect(prisma.planSession.findFirstOrThrow.mock.calls[0][0].where.id).toBe('ps1');
    expect(res.workout).toBeNull();
    expect(res.today).toBe('2026-11-09');
    expect(res.exercises[0].prescription).toMatchObject({ action: 'start', loadKg: 40 });
    expect(res.exercises[0].warmupSets).toEqual([{ reps: 5, loadPct: 50, loadKg: 20 }]);
    expect(res.exercises[0].substitutedFrom).toBeNull();
  });

  it('today con entrenamiento en curso y sustitución aplicada', async () => {
    const { prisma, sessions } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValue(profileRow());
    prisma.planVersion.findFirst.mockResolvedValue({ id: 'v1', plan: { createdAt: NOW }, sessions: [{ id: 'ps1', order: 1 }] });
    prisma.workoutSession.findFirst.mockResolvedValue({
      ...workoutRow({ planSessionId: 'ps1' }),
      setLogs: [setRow({ exerciseId: 'id:press-banca-mancuernas' })],
      substitutions: [{ planExerciseId: 'pe1', exerciseId: 'id:press-banca-mancuernas' }],
    });
    prisma.planSession.findFirstOrThrow.mockResolvedValue({ ...planSession, rationale: null });
    const res = await sessions.today(UID);
    expect(res.workout?.id).toBe(W);
    expect(res.rationale).toEqual([]);
    const ex = res.exercises[0];
    expect(ex.substitutedFrom?.id).toBe('id:press-banca-barra');
    expect(ex.exercise.id).toBe('id:press-banca-mancuernas');
    expect(ex.prescription.loadKg).toBeNull();
    expect(ex.loggedSets).toHaveLength(1);
  });
});
