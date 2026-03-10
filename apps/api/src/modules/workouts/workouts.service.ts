import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class WorkoutsService {
  constructor(private readonly prisma: PrismaService) {}

  async startSession(userId: string, planSessionId?: string) {
    let planVersionId: string | null = null;
    if (planSessionId) {
      const planSession = await this.prisma.trainingSession.findUnique({
        where: { id: planSessionId },
        select: { planVersionId: true },
      });
      if (!planSession) throw new NotFoundException('Training session not found');
      planVersionId = planSession.planVersionId;
    }

    const session = await this.prisma.workoutSession.create({
      data: {
        userId,
        planSessionId: planSessionId ?? null,
        planVersionId,
      },
      include: {
        exercises: { include: { sets: true }, orderBy: { order: 'asc' } },
      },
    });
    return this.toWorkoutSession(session);
  }

  async addExercise(userId: string, workoutSessionId: string, exerciseId: string) {
    const session = await this.findSessionForUser(workoutSessionId, userId);
    const exerciseExists = await this.prisma.exercise.findUnique({
      where: { id: exerciseId },
    });
    if (!exerciseExists) throw new NotFoundException('Exercise not found');
    const count = await this.prisma.workoutExercise.count({
      where: { workoutSessionId },
    });
    const exercise = await this.prisma.workoutExercise.create({
      data: {
        workoutSessionId,
        exerciseId,
        order: count,
      },
      include: { sets: true },
    });
    const updated = await this.prisma.workoutSession.findUnique({
      where: { id: workoutSessionId },
      include: {
        exercises: { include: { sets: true }, orderBy: { order: 'asc' } },
      },
    });
    return this.toWorkoutSession(updated!);
  }

  /**
   * Log a set. Validates in order: (1) workout session exists and belongs to user (404/403),
   * (2) workout exercise exists, belongs to that session, and session belongs to user.
   * Returns 404 "Workout exercise not found" when exercise is missing or belongs to another session (no info leak).
   */
  async logSet(
    userId: string,
    workoutSessionId: string,
    workoutExerciseId: string,
    body: { weightKg?: number; reps?: number; rir?: number; completed?: boolean },
  ) {
    const session = await this.findSessionForUser(workoutSessionId, userId);
    const workoutExercise = await this.prisma.workoutExercise.findFirst({
      where: {
        id: workoutExerciseId,
        workoutSessionId: session.id,
        workoutSession: { userId },
      },
      include: { sets: { orderBy: { setIndex: 'asc' } } },
    });
    if (!workoutExercise) throw new NotFoundException('Workout exercise not found');
    const setIndex = workoutExercise.sets.length;
    await this.prisma.workoutSet.create({
      data: {
        workoutExerciseId: workoutExercise.id,
        setIndex,
        weightKg: body.weightKg ?? null,
        reps: body.reps ?? null,
        rir: body.rir ?? null,
        completed: body.completed ?? true,
      },
    });
    const updated = await this.prisma.workoutSession.findUnique({
      where: { id: workoutSessionId },
      include: {
        exercises: { include: { sets: true }, orderBy: { order: 'asc' } },
      },
    });
    return this.toWorkoutSession(updated!);
  }

  async finishSession(
    userId: string,
    workoutSessionId: string,
    body: { durationMinutes?: number; notes?: string },
  ) {
    const session = await this.findSessionForUser(workoutSessionId, userId);
    if (session.completedAt) throw new ForbiddenException('Workout already completed');

    const updated = await this.prisma.workoutSession.update({
      where: { id: workoutSessionId },
      data: {
        completedAt: new Date(),
        durationMinutes: body.durationMinutes ?? null,
        notes: body.notes ?? null,
      },
      include: {
        exercises: { include: { sets: true }, orderBy: { order: 'asc' } },
      },
    });
    return this.toWorkoutSession(updated);
  }

  async getById(userId: string, workoutSessionId: string) {
    const session = await this.prisma.workoutSession.findUnique({
      where: { id: workoutSessionId },
      include: {
        exercises: { include: { sets: true }, orderBy: { order: 'asc' } },
      },
    });
    if (!session) throw new NotFoundException('Workout session not found');
    if (session.userId !== userId) throw new ForbiddenException('Not your workout session');
    return this.toWorkoutSession(session);
  }

  async getHistory(userId: string) {
    const sessions = await this.prisma.workoutSession.findMany({
      where: { userId },
      include: {
        exercises: { include: { sets: true }, orderBy: { order: 'asc' } },
      },
      orderBy: { startedAt: 'desc' },
      take: 50,
    });
    return sessions.map((s) => this.toWorkoutSession(s));
  }

  private async findSessionForUser(workoutSessionId: string, userId: string) {
    const session = await this.prisma.workoutSession.findUnique({
      where: { id: workoutSessionId },
    });
    if (!session) throw new NotFoundException('Workout session not found');
    if (session.userId !== userId) throw new ForbiddenException('Not your workout session');
    if (session.completedAt) throw new ForbiddenException('Workout already completed');
    return session;
  }

  private toWorkoutSession(row: {
    id: string;
    userId: string;
    planSessionId: string | null;
    planVersionId: string | null;
    startedAt: Date;
    completedAt: Date | null;
    durationMinutes: number | null;
    notes: string | null;
    exercises: Array<{
      id: string;
      workoutSessionId: string;
      exerciseId: string;
      order: number;
      sets: Array<{
        id: string;
        workoutExerciseId: string;
        setIndex: number;
        weightKg: number | null;
        reps: number | null;
        rir: number | null;
        completed: boolean;
      }>;
    }>;
  }) {
    return {
      id: row.id,
      userId: row.userId,
      planSessionId: row.planSessionId,
      planVersionId: row.planVersionId,
      startedAt: row.startedAt.toISOString(),
      completedAt: row.completedAt?.toISOString() ?? null,
      durationMinutes: row.durationMinutes,
      notes: row.notes,
      exercises: row.exercises.map((e) => ({
        id: e.id,
        workoutSessionId: e.workoutSessionId,
        exerciseId: e.exerciseId,
        order: e.order,
        sets: e.sets.map((s) => ({
          id: s.id,
          workoutExerciseId: s.workoutExerciseId,
          setIndex: s.setIndex,
          weightKg: s.weightKg,
          reps: s.reps,
          rir: s.rir,
          completed: s.completed,
        })),
      })),
    };
  }
}
