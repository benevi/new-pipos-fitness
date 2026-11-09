import { Injectable } from '@nestjs/common';
import { dateColumn, localDate, weekRange, weekStartOf } from '../../common/time';
import type { TransactionClient } from '../../prisma/prisma.service';
import { bestE1rm, E1RM_FORMULA_VERSION, muscleVolume, VOLUME_FORMULA_VERSION } from './analytics-calc';

export interface WorkoutForAnalytics {
  id: string;
  userId: string;
  startedAt: Date;
}

/**
 * Analítica calculada AL ESCRIBIR (ADR-0008): se llama dentro de la misma transacción que
 * guarda la serie o cierra el entrenamiento. Cada recálculo es idempotente (recalcula la
 * proyección completa de esa sesión/semana a partir de SetLog), así que repetirlo no deriva.
 * Las lecturas (/progress/*) solo leen estas tablas.
 */
@Injectable()
export class AnalyticsService {
  /** Serializa las escrituras de un usuario: evita perder un recálculo en escrituras concurrentes. */
  async lockUser(tx: TransactionClient, userId: string): Promise<void> {
    await tx.$queryRaw`SELECT 1 AS locked FROM pg_advisory_xact_lock(hashtextextended(${userId}, 0))`;
  }

  async timezoneOf(tx: TransactionClient, userId: string): Promise<string> {
    const profile = await tx.trainingProfile.findUnique({ where: { userId }, select: { timezone: true } });
    return profile?.timezone ?? 'UTC';
  }

  /** Tras guardar/editar/borrar una serie: e1RM de ese ejercicio en esa sesión + semana. */
  async onSetChanged(tx: TransactionClient, workout: WorkoutForAnalytics, exerciseId: string): Promise<void> {
    const tz = await this.timezoneOf(tx, workout.userId);
    await this.recomputeE1rm(tx, workout, exerciseId, tz);
    await this.recomputeWeek(tx, workout.userId, weekStartOf(workout.startedAt, tz), tz);
  }

  /** Tras cerrar un entrenamiento: la adherencia de su semana. */
  async onWorkoutFinished(tx: TransactionClient, workout: WorkoutForAnalytics): Promise<void> {
    const tz = await this.timezoneOf(tx, workout.userId);
    await this.recomputeWeek(tx, workout.userId, weekStartOf(workout.startedAt, tz), tz);
  }

  async recomputeE1rm(tx: TransactionClient, workout: WorkoutForAnalytics, exerciseId: string, tz: string): Promise<void> {
    const sets = await tx.setLog.findMany({
      where: { workoutSessionId: workout.id, exerciseId, deletedAt: null, isWarmup: false },
      select: { id: true, reps: true, loadKg: true, rir: true, isWarmup: true },
    });
    const best = bestE1rm(sets.map((s) => ({ ...s, loadKg: Number(s.loadKg) })));
    const key = { userId: workout.userId, exerciseId, workoutSessionId: workout.id };
    if (!best) {
      await tx.exerciseE1rm.deleteMany({ where: key });
      return;
    }
    const data = {
      performedOn: dateColumn(localDate(workout.startedAt, tz)),
      e1rmKg: best.e1rmKg,
      sourceSetLogId: best.setId,
      formulaVersion: E1RM_FORMULA_VERSION,
    };
    await tx.exerciseE1rm.upsert({
      where: { userId_exerciseId_workoutSessionId: key },
      create: { ...key, ...data },
      update: { ...data, computedAt: new Date() },
    });
  }

  /** Volumen por músculo y adherencia de la semana ISO (zona del usuario) que empieza en `weekStart`. */
  async recomputeWeek(tx: TransactionClient, userId: string, weekStart: string, tz: string): Promise<void> {
    const { from, to } = weekRange(weekStart, tz);
    const inWeek = { userId, status: { not: 'abandoned' as const }, startedAt: { gte: from, lt: to } };
    const sets = await tx.setLog.findMany({
      where: { userId, deletedAt: null, isWarmup: false, workoutSession: inWeek },
      select: { reps: true, loadKg: true, exercise: { select: { muscles: { select: { muscle: true, fraction: true } } } } },
    });
    const volume = muscleVolume(
      sets.map((s) => ({
        reps: s.reps,
        loadKg: Number(s.loadKg),
        muscles: s.exercise.muscles.map((m) => ({ muscle: m.muscle, fraction: Number(m.fraction) })),
      })),
    );
    const week = dateColumn(weekStart);
    await tx.weeklyMuscleVolume.deleteMany({ where: { userId, weekStart: week } });
    if (volume.size > 0) {
      await tx.weeklyMuscleVolume.createMany({
        data: [...volume].map(([muscle, v]) => ({
          userId,
          weekStart: week,
          muscle,
          effectiveSets: v.effectiveSets,
          tonnageKg: v.tonnageKg,
          formulaVersion: VOLUME_FORMULA_VERSION,
        })),
      });
    }

    const [completedSessions, version] = await Promise.all([
      tx.workoutSession.count({ where: { ...inWeek, status: 'completed' } }),
      tx.planVersion.findFirst({
        where: { userId, plan: { status: 'active' } },
        orderBy: { version: 'desc' },
        select: { id: true, sessions: { select: { exercises: { select: { sets: true } } } } },
      }),
    ]);
    const adherence = {
      plannedSessions: version?.sessions.length ?? 0,
      completedSessions,
      plannedSets: version?.sessions.reduce((n, s) => n + s.exercises.reduce((m, e) => m + e.sets, 0), 0) ?? 0,
      completedSets: sets.length,
      planVersionId: version?.id ?? null,
      computedAt: new Date(),
    };
    await tx.weeklyAdherence.upsert({
      where: { userId_weekStart: { userId, weekStart: week } },
      create: { userId, weekStart: week, ...adherence },
      update: adherence,
    });
  }

  /** Reconstruye todas las proyecciones de un usuario desde SetLog (script analytics:rebuild). */
  async rebuildUser(tx: TransactionClient, userId: string): Promise<{ workouts: number; weeks: number }> {
    const tz = await this.timezoneOf(tx, userId);
    await tx.exerciseE1rm.deleteMany({ where: { userId } });
    await tx.weeklyMuscleVolume.deleteMany({ where: { userId } });
    await tx.weeklyAdherence.deleteMany({ where: { userId } });
    const workouts = await tx.workoutSession.findMany({
      where: { userId, status: { not: 'abandoned' } },
      select: { id: true, userId: true, startedAt: true, setLogs: { where: { deletedAt: null }, select: { exerciseId: true }, distinct: ['exerciseId'] } },
    });
    const weeks = new Set<string>();
    for (const w of workouts) {
      for (const s of w.setLogs) await this.recomputeE1rm(tx, w, s.exerciseId, tz);
      weeks.add(weekStartOf(w.startedAt, tz));
    }
    for (const week of weeks) await this.recomputeWeek(tx, userId, week, tz);
    return { workouts: workouts.length, weeks: weeks.size };
  }
}
