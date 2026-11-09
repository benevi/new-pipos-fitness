import type { Prisma, SetLog } from '@prisma/client';
import type { SetLogResponse, WorkoutResponse } from '@pipos/contracts';

export const workoutInclude = {
  setLogs: { orderBy: [{ completedAt: 'asc' }, { setIndex: 'asc' }] },
  substitutions: {
    orderBy: { createdAt: 'asc' },
    include: {
      exercise: { select: { id: true, slug: true, nameEs: true } },
      planExercise: { select: { exercise: { select: { id: true, slug: true, nameEs: true } } } },
    },
  },
} satisfies Prisma.WorkoutSessionInclude;

export type WorkoutRow = Prisma.WorkoutSessionGetPayload<{ include: typeof workoutInclude }>;

export function toSetResponse(s: SetLog): SetLogResponse {
  return {
    id: s.id,
    clientId: s.clientId,
    workoutId: s.workoutSessionId,
    planExerciseId: s.planExerciseId,
    exerciseId: s.exerciseId,
    setIndex: s.setIndex,
    reps: s.reps,
    loadKg: Number(s.loadKg),
    rir: s.rir,
    isWarmup: s.isWarmup,
    completedAt: s.completedAt.toISOString(),
    clientUpdatedAt: s.clientUpdatedAt.toISOString(),
    deletedAt: s.deletedAt?.toISOString() ?? null,
  };
}

export function toWorkoutResponse(w: WorkoutRow): WorkoutResponse {
  return {
    id: w.id,
    clientId: w.clientId,
    planSessionId: w.planSessionId,
    status: w.status,
    startedAt: w.startedAt.toISOString(),
    completedAt: w.completedAt?.toISOString() ?? null,
    sets: w.setLogs.map(toSetResponse),
    substitutions: w.substitutions.map((s) => ({
      workoutId: w.id,
      planExerciseId: s.planExerciseId,
      exercise: s.exercise,
      substitutedFrom: s.planExercise.exercise,
    })),
    adjustment:
      w.adjustedMinutes !== null || w.reducedVolume
        ? { availableMinutes: w.adjustedMinutes, reducedVolume: w.reducedVolume }
        : null,
  };
}
