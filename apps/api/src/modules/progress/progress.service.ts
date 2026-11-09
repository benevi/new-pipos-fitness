import { Injectable } from '@nestjs/common';
import { plannedSessionsForWeek } from '@pipos/engine-rules';
import type { AdherenceResponse, E1rmQuery, E1rmResponse, engineV2, VolumeResponse } from '@pipos/contracts';
import { Clock } from '../../common/clock';
import { addDays, dateColumn, fromDateColumn, weekStartOf } from '../../common/time';
import { PrismaService } from '../../prisma/prisma.service';
import { E1RM_FORMULA_VERSION } from '../analytics/analytics-calc';
import { readRationale } from '../plans/plan-mapper';

export function lastWeeks(currentWeek: string, count: number): string[] {
  return Array.from({ length: count }, (_, i) => addDays(currentWeek, -7 * (count - 1 - i)));
}

export function volumeStatus(sets: number, target: { min: number; max: number } | undefined) {
  if (!target) return 'no_target' as const;
  return sets < target.min ? ('below' as const) : sets > target.max ? ('above' as const) : ('within' as const);
}

/**
 * Lecturas de progreso (CUJ-7). SOLO LEEN las tablas resumen que se mantienen al escribir
 * (ADR-0008); un e2e comprueba que estos GET no ejecutan ninguna escritura.
 */
@Injectable()
export class ProgressService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  private async timezone(userId: string): Promise<string> {
    const p = await this.prisma.trainingProfile.findUnique({ where: { userId }, select: { timezone: true } });
    return p?.timezone ?? 'UTC';
  }

  async e1rm(userId: string, query: E1rmQuery): Promise<E1rmResponse> {
    const rows = await this.prisma.exerciseE1rm.findMany({
      where: {
        userId,
        ...(query.exerciseId ? { exerciseId: query.exerciseId } : {}),
        ...(query.from || query.to
          ? {
              performedOn: {
                ...(query.from ? { gte: dateColumn(query.from) } : {}),
                ...(query.to ? { lte: dateColumn(query.to) } : {}),
              },
            }
          : {}),
      },
      orderBy: [{ performedOn: 'asc' }, { computedAt: 'asc' }],
      include: { exercise: { select: { slug: true, nameEs: true } } },
      take: 5000,
    });
    const series = new Map<string, E1rmResponse['series'][number]>();
    for (const r of rows) {
      let s = series.get(r.exerciseId);
      if (!s) {
        s = { exerciseId: r.exerciseId, slug: r.exercise.slug, nameEs: r.exercise.nameEs, latestE1rmKg: 0, points: [] };
        series.set(r.exerciseId, s);
      }
      const value = Number(r.e1rmKg);
      s.points.push({ date: fromDateColumn(r.performedOn), e1rmKg: value, workoutId: r.workoutSessionId });
      s.latestE1rmKg = value;
    }
    return {
      formulaVersion: E1RM_FORMULA_VERSION,
      series: [...series.values()].sort((a, b) => (a.slug < b.slug ? -1 : a.slug > b.slug ? 1 : 0)),
    };
  }

  async volume(userId: string, weeks: number): Promise<VolumeResponse> {
    const tz = await this.timezone(userId);
    const range = lastWeeks(weekStartOf(this.clock.now(), tz), weeks);
    const inRange = { userId, weekStart: { gte: dateColumn(range[0]), lte: dateColumn(range[range.length - 1]) } };
    const [rows, groupRows, version] = await Promise.all([
      this.prisma.weeklyMuscleVolume.findMany({ where: inRange, orderBy: [{ weekStart: 'asc' }, { muscle: 'asc' }] }),
      this.prisma.weeklyGroupVolume.findMany({ where: inRange }),
      this.prisma.planVersion.findFirst({
        where: { userId, plan: { status: 'active' } },
        orderBy: { version: 'desc' },
        select: { rationale: true },
      }),
    ]);
    const targets = new Map<engineV2.VolumeGroup, { min: number; max: number }>(
      (version ? readRationale(version.rationale).weeklyVolume : []).map((g) => [g.group, { min: g.min, max: g.max }]),
    );
    return {
      timezone: tz,
      weeks: range.map((weekStart) => {
        const own = rows.filter((r) => fromDateColumn(r.weekStart) === weekStart);
        const muscles = new Map(own.map((r) => [r.muscle, { effectiveSets: Number(r.effectiveSets), tonnageKg: Number(r.tonnageKg) }]));
        const groups = new Map(
          groupRows.filter((r) => fromDateColumn(r.weekStart) === weekStart).map((r) => [r.group, Number(r.effectiveSets)]),
        );
        const allGroups = new Set<engineV2.VolumeGroup>([...targets.keys(), ...groups.keys()]);
        return {
          weekStart,
          muscles: [...muscles].map(([muscle, v]) => ({ muscle, ...v })),
          groups: [...allGroups].sort().map((group) => {
            const sets = groups.get(group) ?? 0;
            const target = targets.get(group);
            return {
              group,
              effectiveSets: sets,
              targetMin: target?.min ?? null,
              targetMax: target?.max ?? null,
              status: volumeStatus(sets, target),
            };
          }),
        };
      }),
    };
  }

  async adherence(userId: string, weeks: number): Promise<AdherenceResponse> {
    const tz = await this.timezone(userId);
    const range = lastWeeks(weekStartOf(this.clock.now(), tz), weeks);
    const [rows, version, breaks, profile] = await Promise.all([
      this.prisma.weeklyAdherence.findMany({
        where: { userId, weekStart: { gte: dateColumn(range[0]), lte: dateColumn(range[range.length - 1]) } },
      }),
      this.prisma.planVersion.findFirst({
        where: { userId, plan: { status: 'active' } },
        orderBy: { version: 'asc' },
        select: {
          createdAt: true,
          plan: {
            select: {
              versions: {
                orderBy: { version: 'desc' },
                take: 1,
                select: { sessions: { select: { exercises: { select: { sets: true } } } } },
              },
            },
          },
        },
      }),
      this.prisma.trainingBreak.findMany({
        where: { userId, startsOn: { lte: dateColumn(addDays(range[range.length - 1], 6)) }, endsOn: { gte: dateColumn(range[0]) } },
        select: { startsOn: true, endsOn: true },
      }),
      this.prisma.trainingProfile.findUnique({ where: { userId }, select: { trainingWeekdays: true } }),
    ]);
    const plannedBreaks = breaks.map((b) => ({ startsOn: fromDateColumn(b.startsOn), endsOn: fromDateColumn(b.endsOn) }));
    // Semanas sin actividad: planificado = plan vigente (desde la semana en que se creó el primero).
    const firstWeek = version ? weekStartOf(version.createdAt, tz) : null;
    const latest = version?.plan.versions[0];
    const planned = {
      sessions: latest?.sessions.length ?? 0,
      sets: latest?.sessions.reduce((n, s) => n + s.exercises.reduce((m, e) => m + e.sets, 0), 0) ?? 0,
    };
    const byWeek = new Map(rows.map((r) => [fromDateColumn(r.weekStart), r]));
    const out = range.map((weekStart) => {
      const r = byWeek.get(weekStart);
      const active = firstWeek !== null && weekStart >= firstWeek;
      // Pausas planificadas (idea 6): sus días no cuentan como previstos (§16.18).
      const week = plannedSessionsForWeek(planned.sessions, weekStart, plannedBreaks, profile?.trainingWeekdays ?? []);
      const plannedSessions = r?.plannedSessions ?? (active ? week.planned : 0);
      const completedSessions = r?.completedSessions ?? 0;
      const setsIfIdle = planned.sessions > 0 ? Math.round((planned.sets * week.planned) / planned.sessions) : 0;
      return {
        weekStart,
        plannedSessions,
        completedSessions,
        plannedSets: r?.plannedSets ?? (active ? setsIfIdle : 0),
        completedSets: r?.completedSets ?? 0,
        sessionRatio: plannedSessions > 0 ? Math.round((completedSessions / plannedSessions) * 1000) / 1000 : 0,
        breakDays: week.breakDays,
      };
    });
    const totalPlanned = out.reduce((n, w) => n + w.plannedSessions, 0);
    const totalDone = out.reduce((n, w) => n + w.completedSessions, 0);
    return {
      timezone: tz,
      weeks: out,
      totals: {
        plannedSessions: totalPlanned,
        completedSessions: totalDone,
        sessionRatio: totalPlanned > 0 ? Math.round((totalDone / totalPlanned) * 1000) / 1000 : 0,
      },
    };
  }
}
