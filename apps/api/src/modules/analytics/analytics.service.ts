import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  getBestE1RMPerExercise,
  computeVolumePerExercise,
  computeAdherence,
  fatigueScorePerExercise,
  volumeTrend,
} from '@pipos/engine-rules';
import type { ProgressResponse, VolumeResponse } from '@pipos/contracts';

/**
 * ExerciseProgress is a derived analytics projection. Source of truth remains
 * WorkoutSession, WorkoutExercise, and WorkoutSet. This service recomputes and
 * upserts progress from that source data; it is not authoritative for history.
 */
@Injectable()
export class AnalyticsService {
  constructor(private readonly prisma: PrismaService) {}

  async getProgress(userId: string): Promise<ProgressResponse> {
    const { setsByExerciseLastWeek, setsByExercisePrevWeek, completedSetsLastWeek, plannedSets } =
      await this.loadSetData(userId, 7);

    const bestE1RM = getBestE1RMPerExercise(setsByExerciseLastWeek);
    const volumeLastWeek = computeVolumePerExercise(setsByExerciseLastWeek);
    const volumePrevWeek = computeVolumePerExercise(setsByExercisePrevWeek);
    const fatigue = fatigueScorePerExercise(setsByExerciseLastWeek);

    const adherenceScore = computeAdherence(completedSetsLastWeek, plannedSets);
    const fatigueDetected = [...fatigue.values()].some((s) => s > 0);

    const exercises: ProgressResponse['exercises'] = [];
    const exerciseIds = new Set([
      ...bestE1RM.keys(),
      ...volumeLastWeek.keys(),
      ...volumePrevWeek.keys(),
      ...fatigue.keys(),
    ]);
    for (const exerciseId of exerciseIds) {
      const volL = volumeLastWeek.get(exerciseId) ?? 0;
      const volP = volumePrevWeek.get(exerciseId) ?? 0;
      const trend = volumeTrend(volL, volP);
      const progressRow = await this.prisma.exerciseProgress.upsert({
        where: {
          userId_exerciseId: { userId, exerciseId },
        },
        create: {
          userId,
          exerciseId,
          estimated1RM: bestE1RM.get(exerciseId) ?? null,
          volumeLastWeek: volL > 0 ? volL : null,
          volumeTrend: trend,
          fatigueScore: fatigue.get(exerciseId) ?? null,
        },
        update: {
          estimated1RM: bestE1RM.get(exerciseId) ?? undefined,
          volumeLastWeek: volL > 0 ? volL : undefined,
          volumeTrend: trend,
          fatigueScore: fatigue.get(exerciseId) ?? undefined,
        },
      });
      exercises.push({
        exerciseId,
        estimated1RM: progressRow.estimated1RM,
        volumeLastWeek: progressRow.volumeLastWeek,
        volumeTrend: progressRow.volumeTrend as 'up' | 'down' | 'stable' | null,
        fatigueScore: progressRow.fatigueScore,
        lastUpdated: progressRow.lastUpdated.toISOString(),
      });
    }

    return {
      exercises: exercises.sort((a, b) => a.exerciseId.localeCompare(b.exerciseId)),
      adherenceScore: adherenceScore ?? null,
      fatigueDetected,
    };
  }

  async getVolume(userId: string): Promise<VolumeResponse> {
    const { setsByExerciseLastWeek } = await this.loadSetData(userId, 7);
    const byExercise = computeVolumePerExercise(setsByExerciseLastWeek);

    const exerciseIds = [...byExercise.keys()];
    if (exerciseIds.length === 0) {
      return { byExercise: [], byMuscle: [], weekStart: undefined, weekEnd: undefined };
    }

    const muscleRows = await this.prisma.exerciseMuscle.findMany({
      where: { exerciseId: { in: exerciseIds } },
    });

    const byMuscle = new Map<string, number>();
    for (const row of muscleRows) {
      const vol = byExercise.get(row.exerciseId) ?? 0;
      const weight = row.role === 'primary' ? 1 : row.role === 'secondary' ? 0.5 : 0.25;
      byMuscle.set(row.muscleId, (byMuscle.get(row.muscleId) ?? 0) + vol * weight);
    }

    const now = new Date();
    const weekEnd = new Date(now);
    weekEnd.setHours(0, 0, 0, 0);
    const weekStart = new Date(weekEnd);
    weekStart.setDate(weekStart.getDate() - 7);

    return {
      byExercise: [...byExercise.entries()].map(([exerciseId, volume]) => ({ exerciseId, volume })),
      byMuscle: [...byMuscle.entries()].map(([muscleId, volume]) => ({ muscleId, volume })),
      weekStart: weekStart.toISOString(),
      weekEnd: weekEnd.toISOString(),
    };
  }

  private async loadSetData(
    userId: string,
    lastDays: number,
  ): Promise<{
    setsByExerciseLastWeek: Map<string, Array<{ weightKg: number | null; reps: number | null; rir: number | null; completed?: boolean }>>;
    setsByExercisePrevWeek: Map<string, Array<{ weightKg: number | null; reps: number | null }>>;
    completedSetsLastWeek: number;
    plannedSets: number;
  }> {
    const now = new Date();
    const weekAgo = new Date(now);
    weekAgo.setDate(weekAgo.getDate() - lastDays);
    const twoWeeksAgo = new Date(now);
    twoWeeksAgo.setDate(twoWeeksAgo.getDate() - lastDays * 2);

    const sessions = await this.prisma.workoutSession.findMany({
      where: {
        userId,
        completedAt: { not: null },
        startedAt: { gte: twoWeeksAgo },
      },
      include: {
        exercises: { include: { sets: { orderBy: { setIndex: 'asc' } } } },
      },
      orderBy: { startedAt: 'asc' },
    });

    const setsByExerciseLastWeek = new Map<
      string,
      Array<{ weightKg: number | null; reps: number | null; rir: number | null; completed?: boolean }>
    >();
    const setsByExercisePrevWeek = new Map<
      string,
      Array<{ weightKg: number | null; reps: number | null }>
    >();
    let completedSetsLastWeek = 0;

    for (const sess of sessions) {
      const startedAt = sess.startedAt.getTime();
      const inLastWeek = startedAt >= weekAgo.getTime();
      const inPrevWeek = startedAt >= twoWeeksAgo.getTime() && startedAt < weekAgo.getTime();

      for (const ex of sess.exercises) {
        const arrL = setsByExerciseLastWeek.get(ex.exerciseId) ?? [];
        const arrP = setsByExercisePrevWeek.get(ex.exerciseId) ?? [];
        for (const s of ex.sets) {
          const rec = {
            weightKg: s.weightKg,
            reps: s.reps,
            rir: s.rir,
            completed: s.completed,
          };
          if (inLastWeek) {
            arrL.push(rec);
            if (s.completed) completedSetsLastWeek += 1;
          }
          if (inPrevWeek) arrP.push({ weightKg: s.weightKg, reps: s.reps });
        }
        if (arrL.length) setsByExerciseLastWeek.set(ex.exerciseId, arrL);
        if (arrP.length) setsByExercisePrevWeek.set(ex.exerciseId, arrP);
      }
    }

    // Adherence: session-based. Only workouts in last 7 days with planSessionId.
    const lastWeekSessionsForAdherence = sessions.filter(
      (s) =>
        s.startedAt.getTime() >= weekAgo.getTime() &&
        s.planSessionId != null,
    );
    let plannedSets = 0;
    let completedSetsForAdherence = 0;
    const sessionPlannedCache = new Map<string, number>();
    for (const sess of lastWeekSessionsForAdherence) {
      const planSessionId = sess.planSessionId!;
      let sessionPlanned = sessionPlannedCache.get(planSessionId);
      if (sessionPlanned === undefined) {
        const trainingSession = await this.prisma.trainingSession.findUnique({
          where: { id: planSessionId },
          include: { exercises: true },
        });
        sessionPlanned = trainingSession
          ? trainingSession.exercises.reduce((sum, e) => sum + e.sets, 0)
          : 0;
        sessionPlannedCache.set(planSessionId, sessionPlanned);
      }
      plannedSets += sessionPlanned;
      for (const ex of sess.exercises) {
        for (const s of ex.sets) if (s.completed) completedSetsForAdherence += 1;
      }
    }
    completedSetsLastWeek = completedSetsForAdherence;

    return {
      setsByExerciseLastWeek,
      setsByExercisePrevWeek,
      completedSetsLastWeek,
      plannedSets,
    };
  }
}
