import { describe, expect, it } from 'vitest';
import { Prisma } from '@prisma/client';
import { addDays, isoWeekStart, localDate, weekRange, weekStartOf, zonedStartOfDay } from '../../common/time';
import { FixedClock, prismaMock, UID } from '../../test/unit/support';
import type { PrismaService } from '../../prisma/prisma.service';
import { ProgressService, lastWeeks, volumeStatus } from '../progress/progress.service';
import { bestE1rm, groupVolume, muscleVolume, plannedOf, versionForWeek } from './analytics-calc';
import { groupFractions, PROGRAMMING } from '@pipos/engine-rules';
import { AnalyticsService } from './analytics.service';

const workout = { id: 'w1', userId: UID, startedAt: new Date('2026-11-08T23:30:00Z') }; // lunes 9 en Madrid

describe('time (zona horaria del usuario)', () => {
  it('fechas locales y semanas ISO', () => {
    expect(localDate(workout.startedAt, 'Europe/Madrid')).toBe('2026-11-09');
    expect(localDate(workout.startedAt, 'UTC')).toBe('2026-11-08');
    expect(isoWeekStart('2026-11-08')).toBe('2026-11-02'); // domingo → lunes anterior
    expect(isoWeekStart('2026-11-09')).toBe('2026-11-09');
    expect(weekStartOf(workout.startedAt, 'Europe/Madrid')).toBe('2026-11-09');
    expect(weekStartOf(workout.startedAt, 'America/New_York')).toBe('2026-11-02');
    expect(addDays('2026-12-31', 1)).toBe('2027-01-01');
  });

  it('medianoche local en UTC, también en el cambio de hora', () => {
    expect(zonedStartOfDay('2026-11-09', 'Europe/Madrid').toISOString()).toBe('2026-11-08T23:00:00.000Z');
    expect(zonedStartOfDay('2026-07-01', 'Europe/Madrid').toISOString()).toBe('2026-06-30T22:00:00.000Z');
    // Semana con el cambio de horario de octubre: 7 días de 24 h salvo uno de 25.
    const r = weekRange('2026-10-19', 'Europe/Madrid');
    expect(r.from.toISOString()).toBe('2026-10-18T22:00:00.000Z');
    const dst = weekRange('2026-10-26', 'Europe/Madrid');
    expect((dst.from.getTime() - r.from.getTime()) / 3_600_000).toBe(7 * 24 + 1);
  });
});

describe('cálculos de analítica', () => {
  it('bestE1rm ignora calentamiento y series sin carga o con demasiadas reps', () => {
    expect(bestE1rm([])).toBeNull();
    expect(bestE1rm([{ id: 'a', reps: 20, loadKg: 40, rir: 0, isWarmup: false }])).toBeNull();
    const best = bestE1rm([
      { id: 'w', reps: 5, loadKg: 100, rir: 0, isWarmup: true },
      { id: 'a', reps: 8, loadKg: 40, rir: 2, isWarmup: false },
      { id: 'b', reps: 6, loadKg: 45, rir: null, isWarmup: false },
    ]);
    expect(best).toEqual({ e1rmKg: 54, setId: 'b' });
  });

  it('volumen por músculo y por grupo', () => {
    const v = muscleVolume([
      { reps: 10, loadKg: 20, muscles: [{ muscle: 'chest', fraction: 1 }, { muscle: 'triceps', fraction: 0.5 }] },
      { reps: 10, loadKg: 20, muscles: [{ muscle: 'chest', fraction: 1 }] },
    ]);
    expect(v.get('chest')).toEqual({ effectiveSets: 2, tonnageKg: 400 });
    expect(v.get('triceps')).toEqual({ effectiveSets: 0.5, tonnageKg: 100 });
  });

  it('volumen por grupo = regla del motor: máxima fracción por ejercicio y grupo, no la suma (§16.1)', () => {
    // Un remo (dorsal 1 + espalda alta 1) es UNA serie de espalda; un press de banca suma 1 a
    // pecho y 0,5 a tríceps; un curl femoral con gemelo 0,5 suma 1 a isquios y 0,5 a gemelo.
    const row = { reps: 10, loadKg: 50, muscles: [{ muscle: 'lats' as const, fraction: 1 }, { muscle: 'upper_back' as const, fraction: 1 }, { muscle: 'biceps' as const, fraction: 0.5 }] };
    const bench = { reps: 8, loadKg: 60, muscles: [{ muscle: 'chest' as const, fraction: 1 }, { muscle: 'triceps' as const, fraction: 0.5 }, { muscle: 'front_delts' as const, fraction: 0.5 }] };
    const g = groupVolume([row, row, bench]);
    expect(g.get('back')).toBe(2);
    expect(g.get('biceps')).toBe(1);
    expect(g.get('chest')).toBe(1);
    expect(g.get('triceps')).toBe(0.5);
    // Coincide con lo que cuenta el motor para el mismo ejercicio.
    expect(Object.fromEntries(groupFractions(row.muscles, PROGRAMMING))).toEqual({ back: 1, biceps: 0.5 });
  });
});

describe('AnalyticsService (escritura)', () => {
  function setup() {
    const prisma = prismaMock();
    prisma.trainingProfile.findUnique.mockResolvedValue({ timezone: 'Europe/Madrid' });
    prisma.setLog.findMany.mockResolvedValue([]);
    prisma.workoutSession.count.mockResolvedValue(1);
    prisma.planVersion.findFirst.mockResolvedValue({ id: 'v1', sessions: [{ exercises: [{ sets: 3 }, { sets: 2 }] }, { exercises: [] }] });
    return { prisma, analytics: new AnalyticsService() };
  }

  it('onSetChanged: upsert del e1RM con fecha local y recálculo de la semana', async () => {
    const { prisma, analytics } = setup();
    prisma.setLog.findMany
      .mockResolvedValueOnce([{ id: 's', reps: 8, loadKg: new Prisma.Decimal(40), rir: 2, isWarmup: false }])
      .mockResolvedValueOnce([
        { reps: 8, loadKg: new Prisma.Decimal(40), exercise: { muscles: [{ muscle: 'chest', fraction: new Prisma.Decimal(1) }] } },
      ]);
    await analytics.onSetChanged(prisma as never, workout, 'e1');
    const upsert = prisma.exerciseE1rm.upsert.mock.calls[0][0];
    expect(upsert.create.performedOn.toISOString()).toBe('2026-11-09T00:00:00.000Z');
    expect(upsert.create.e1rmKg).toBeCloseTo(53.33, 2);
    expect(prisma.weeklyMuscleVolume.createMany.mock.calls[0][0].data[0]).toMatchObject({ muscle: 'chest', effectiveSets: 1, tonnageKg: 320 });
    expect(prisma.weeklyGroupVolume.createMany.mock.calls[0][0].data[0]).toMatchObject({ group: 'chest', effectiveSets: 1, formulaVersion: 'group-max-v1' });
    const adherence = prisma.weeklyAdherence.upsert.mock.calls[0][0];
    expect(adherence.create).toMatchObject({ plannedSessions: 2, plannedSets: 5, completedSessions: 1, completedSets: 1, planVersionId: 'v1' });
    // Rango de la semana en UTC desde la medianoche local del lunes.
    const where = prisma.setLog.findMany.mock.calls[1][0].where.workoutSession.startedAt;
    expect(where.gte.toISOString()).toBe('2026-11-08T23:00:00.000Z');
  });

  it('sin series válidas borra el e1RM; sin plan, planificado 0; sin perfil usa UTC', async () => {
    const { prisma, analytics } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValue(null);
    prisma.planVersion.findFirst.mockResolvedValue(null);
    await analytics.onSetChanged(prisma as never, workout, 'e1');
    expect(prisma.exerciseE1rm.deleteMany).toHaveBeenCalled();
    expect(prisma.weeklyMuscleVolume.createMany).not.toHaveBeenCalled();
    expect(prisma.weeklyAdherence.upsert.mock.calls[0][0].create).toMatchObject({ plannedSessions: 0, plannedSets: 0, planVersionId: null });
    expect(prisma.weeklyAdherence.upsert.mock.calls[0][0].create.weekStart.toISOString()).toBe('2026-11-02T00:00:00.000Z');
  });

  it('onWorkoutFinished y rebuildUser', async () => {
    const { prisma, analytics } = setup();
    await analytics.onWorkoutFinished(prisma as never, workout);
    expect(prisma.weeklyAdherence.upsert).toHaveBeenCalledTimes(1);
    prisma.workoutSession.findMany.mockResolvedValueOnce([{ ...workout, setLogs: [{ exerciseId: 'e1' }, { exerciseId: 'e2' }] }]);
    expect(await analytics.rebuildUser(prisma as never, UID)).toEqual({ workouts: 1, weeks: 1 });
    expect(prisma.exerciseE1rm.deleteMany.mock.calls.at(-1)?.[0]).toBeDefined();
    await analytics.lockUser(prisma as never, UID);
    expect(prisma.$queryRaw).toHaveBeenCalled();
  });

  it('recomputeWeek busca la versión creada antes del final de esa semana (issue #14)', async () => {
    const { prisma, analytics } = setup();
    await analytics.recomputeWeek(prisma as never, UID, '2026-11-02', 'Europe/Madrid');
    const where = prisma.planVersion.findFirst.mock.calls[0][0];
    expect(where.where.createdAt.lt.toISOString()).toBe('2026-11-08T23:00:00.000Z');
    expect(where.orderBy).toEqual([{ createdAt: 'desc' }, { version: 'desc' }]);
  });

  it('versionForWeek y plannedOf', () => {
    const a = { id: 'a', createdAt: new Date('2026-11-01T00:00:00Z'), sessions: [{ exercises: [{ sets: 3 }, { sets: 2 }] }] };
    const b = { id: 'b', createdAt: new Date('2026-11-05T00:00:00Z'), sessions: [] };
    expect(versionForWeek([b, a], new Date('2026-11-01T00:00:00Z'))).toBeNull();
    expect(versionForWeek([b, a], new Date('2026-11-03T00:00:00Z'))?.id).toBe('a');
    expect(versionForWeek([a, b], new Date('2026-11-09T00:00:00Z'))?.id).toBe('b');
    expect(plannedOf(a)).toEqual({ sessions: 1, sets: 5 });
    expect(plannedOf(null)).toEqual({ sessions: 0, sets: 0 });
  });

  it('onWorkoutAbandoned: borra el e1RM de ese entrenamiento y recalcula su semana', async () => {
    const { prisma, analytics } = setup();
    await analytics.onWorkoutAbandoned(prisma as never, workout);
    expect(prisma.exerciseE1rm.deleteMany.mock.calls[0][0]).toEqual({ where: { userId: workout.userId, workoutSessionId: workout.id } });
    expect(prisma.weeklyAdherence.upsert).toHaveBeenCalledTimes(1);
  });
});

describe('ProgressService (lectura)', () => {
  function setup() {
    const prisma = prismaMock();
    prisma.trainingProfile.findUnique.mockResolvedValue({ timezone: 'Europe/Madrid' });
    return { prisma, progress: new ProgressService(prisma as unknown as PrismaService, new FixedClock()) };
  }

  it('helpers', () => {
    expect(lastWeeks('2026-11-09', 3)).toEqual(['2026-10-26', '2026-11-02', '2026-11-09']);
    expect(volumeStatus(5, undefined)).toBe('no_target');
    expect(volumeStatus(5, { min: 10, max: 20 })).toBe('below');
    expect(volumeStatus(25, { min: 10, max: 20 })).toBe('above');
    expect(volumeStatus(15, { min: 10, max: 20 })).toBe('within');
  });

  it('e1rm agrupa series por ejercicio y filtra por fechas', async () => {
    const { prisma, progress } = setup();
    prisma.exerciseE1rm.findMany.mockResolvedValue([
      { exerciseId: 'b', workoutSessionId: 'w1', performedOn: new Date('2026-11-01'), e1rmKg: new Prisma.Decimal(50), exercise: { slug: 'zz', nameEs: 'Z' } },
      { exerciseId: 'a', workoutSessionId: 'w1', performedOn: new Date('2026-11-01'), e1rmKg: new Prisma.Decimal(60), exercise: { slug: 'aa', nameEs: 'A' } },
      { exerciseId: 'a', workoutSessionId: 'w2', performedOn: new Date('2026-11-05'), e1rmKg: new Prisma.Decimal(62.5), exercise: { slug: 'aa', nameEs: 'A' } },
    ]);
    const res = await progress.e1rm(UID, { exerciseId: 'a', from: '2026-10-01', to: '2026-12-01' });
    expect(res.series.map((s) => s.slug)).toEqual(['aa', 'zz']);
    expect(res.series[0]).toMatchObject({ latestE1rmKg: 62.5, points: [{ date: '2026-11-01' }, { date: '2026-11-05' }] });
    expect(prisma.exerciseE1rm.findMany.mock.calls[0][0].where.performedOn.gte).toBeInstanceOf(Date);
    await progress.e1rm(UID, { from: '2026-10-01' });
    await progress.e1rm(UID, {});
  });

  it('volume: semanas con grupos frente al objetivo del plan', async () => {
    const { prisma, progress } = setup();
    prisma.weeklyMuscleVolume.findMany.mockResolvedValue([
      { weekStart: new Date('2026-11-09'), muscle: 'chest', effectiveSets: new Prisma.Decimal(12), tonnageKg: new Prisma.Decimal(1000) },
    ]);
    prisma.weeklyGroupVolume.findMany.mockResolvedValue([
      { weekStart: new Date('2026-11-09'), group: 'chest', effectiveSets: new Prisma.Decimal(12) },
    ]);
    prisma.planVersion.findFirst.mockResolvedValueOnce({
      rationale: { weeklyVolume: [{ group: 'chest', min: 10, max: 20 }, { group: 'back', min: 10, max: 20 }] },
    });
    const res = await progress.volume(UID, 2);
    expect(res.weeks.map((w) => w.weekStart)).toEqual(['2026-11-02', '2026-11-09']);
    expect(res.weeks[1].groups).toEqual([
      { group: 'back', effectiveSets: 0, targetMin: 10, targetMax: 20, status: 'below' },
      { group: 'chest', effectiveSets: 12, targetMin: 10, targetMax: 20, status: 'within' },
    ]);
    prisma.planVersion.findFirst.mockResolvedValueOnce(null);
    prisma.trainingProfile.findUnique.mockResolvedValueOnce(null);
    const noPlan = await progress.volume(UID, 1);
    expect(noPlan.timezone).toBe('UTC');
    expect(noPlan.weeks[0].groups[0].status).toBe('no_target');
  });

  it('adherence: rellena semanas sin actividad con lo planificado desde el primer plan', async () => {
    const { prisma, progress } = setup();
    prisma.weeklyAdherence.findMany.mockResolvedValue([
      { weekStart: new Date('2026-11-09'), plannedSessions: 3, completedSessions: 2, plannedSets: 30, completedSets: 18 },
    ]);
    prisma.planVersion.findMany.mockResolvedValueOnce([
      { createdAt: new Date('2026-11-03T10:00:00Z'), sessions: [{ exercises: [{ sets: 3 }] }, { exercises: [{ sets: 2 }] }, { exercises: [] }] },
    ]);
    const res = await progress.adherence(UID, 3);
    expect(res.weeks).toEqual([
      { weekStart: '2026-10-26', plannedSessions: 0, completedSessions: 0, plannedSets: 0, completedSets: 0, sessionRatio: 0, breakDays: 0 },
      { weekStart: '2026-11-02', plannedSessions: 3, completedSessions: 0, plannedSets: 5, completedSets: 0, sessionRatio: 0, breakDays: 0 },
      { weekStart: '2026-11-09', plannedSessions: 3, completedSessions: 2, plannedSets: 30, completedSets: 18, sessionRatio: 0.667, breakDays: 0 },
    ]);
    expect(res.totals).toEqual({ plannedSessions: 6, completedSessions: 2, sessionRatio: 0.333 });
    prisma.weeklyAdherence.findMany.mockResolvedValueOnce([]);
    prisma.planVersion.findMany.mockResolvedValueOnce([]);
    expect((await progress.adherence(UID, 1)).totals.sessionRatio).toBe(0);
  });

  it('adherence: cada semana sin actividad usa la versión vigente en esa semana (issue #14)', async () => {
    const { prisma, progress } = setup();
    prisma.weeklyAdherence.findMany.mockResolvedValue([]);
    const sessions = (n: number) => Array.from({ length: n }, () => ({ exercises: [{ sets: 4 }] }));
    prisma.planVersion.findMany.mockResolvedValueOnce([
      { createdAt: new Date('2026-10-20T10:00:00Z'), sessions: sessions(3) },
      { createdAt: new Date('2026-11-05T10:00:00Z'), sessions: sessions(5) },
    ]);
    const res = await progress.adherence(UID, 4);
    expect(res.weeks.map((w) => [w.weekStart, w.plannedSessions, w.plannedSets])).toEqual([
      ['2026-10-19', 3, 12],
      ['2026-10-26', 3, 12],
      ['2026-11-02', 5, 20],
      ['2026-11-09', 5, 20],
    ]);
  });
});
