import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { AnalyticsService } from '../analytics/analytics.service';
import { generateTrainingPlan } from '@pipos/engine-rules';
import type {
  TrainingEngineInput,
  CatalogExerciseSnapshot,
} from '@pipos/contracts';
import { TrainingLevel, TrainingLocation } from '@pipos/contracts';

type UserId = string;

@Injectable()
export class TrainingPlansService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly usersService: UsersService,
    private readonly analyticsService: AnalyticsService,
  ) {}

  async generatePlan(userId: UserId) {
    const user = await this.usersService.getMe(userId);
    const preferences = this.mapPreferences(user);
    const catalog = await this.loadCatalogSnapshot();
    const progressResponse = await this.analyticsService.getProgress(userId);
    const progress = {
      exerciseHistory: progressResponse.exercises.map((e) => ({
        exerciseId: e.exerciseId,
        estimated1RM: e.estimated1RM,
        volumeLastWeek: e.volumeLastWeek,
        volumeTrend: e.volumeTrend,
        fatigueScore: e.fatigueScore,
      })),
      adherenceScore: progressResponse.adherenceScore ?? undefined,
      fatigueScore: progressResponse.fatigueDetected ? 1 : 0,
    };
    const engineInput: TrainingEngineInput = {
      user: {
        trainingLevel: (user.trainingLevel as TrainingLevel) ?? TrainingLevel.BEGINNER,
        sex: user.sex ?? undefined,
        heightCm: user.heightCm ?? undefined,
        weightKg: user.weightKg ?? undefined,
        age: user.age ?? undefined,
      },
      preferences,
      goals: Array.isArray(user.goals)
        ? (user.goals as TrainingEngineInput['goals'])
        : undefined,
      muscleFocus: Array.isArray(user.muscleFocus)
        ? (user.muscleFocus as TrainingEngineInput['muscleFocus'])
        : undefined,
      catalog,
      progress,
    };

    const output = generateTrainingPlan(engineInput);

    if (output.metadata.constraintViolations.length > 0) {
      throw new BadRequestException({
        code: 'PLAN_CONSTRAINT_VIOLATIONS',
        message: 'Training plan has constraint violations',
        constraintViolations: output.metadata.constraintViolations,
      });
    }

    let plan = await this.prisma.trainingPlan.findFirst({
      where: { userId },
    });
    if (!plan) {
      plan = await this.prisma.trainingPlan.create({
        data: { userId },
      });
    }

    const nextVersion = await this.getNextVersionNumber(plan.id);
    const version = await this.prisma.trainingPlanVersion.create({
      data: {
        planId: plan.id,
        version: nextVersion,
        engineVersion: output.metadata.engineVersion,
        objectiveScore: output.metadata.objectiveScore,
      },
    });

    for (const session of output.weekPlan.sessions) {
      const created = await this.prisma.trainingSession.create({
        data: {
          planVersionId: version.id,
          sessionIndex: session.sessionIndex,
          name: session.name,
          targetDurationMinutes: session.targetDurationMinutes,
        },
      });
      for (const ex of session.exercises) {
        await this.prisma.trainingSessionExercise.create({
          data: {
            sessionId: created.id,
            exerciseId: ex.exerciseId,
            sets: ex.sets,
            repRangeMin: ex.repRangeMin,
            repRangeMax: ex.repRangeMax,
            restSeconds: ex.restSeconds,
            rirTarget: ex.rirTarget,
          },
        });
      }
    }

    await this.prisma.trainingPlan.update({
      where: { id: plan.id },
      data: { currentVersionId: version.id },
    });

    const versionWithSessions = await this.prisma.trainingPlanVersion.findUnique({
      where: { id: version.id },
      include: {
        sessions: { orderBy: { sessionIndex: 'asc' }, include: { exercises: true } },
      },
    });
    if (!versionWithSessions) throw new Error('Version not found after create');
    return this.toGenerateResponse(plan, versionWithSessions);
  }

  private mapPreferences(user: Awaited<ReturnType<UsersService['getMe']>>): TrainingEngineInput['preferences'] {
    const days = user.preferredTrainingDays != null ? Math.min(7, Math.max(1, user.preferredTrainingDays)) : 3;
    const location = (user.trainingLocation as TrainingLocation) ?? TrainingLocation.GYM;
    const equipment = Array.isArray(user.availableEquipment)
      ? (user.availableEquipment as string[])
      : [];
    return {
      daysPerWeek: days,
      minutesPerSession: 45,
      trainingLocation: location,
      availableEquipmentIds: equipment,
    };
  }

  private async loadCatalogSnapshot(): Promise<{ exercises: CatalogExerciseSnapshot[] }> {
    const rows = await this.prisma.exercise.findMany({
      include: {
        muscles: true,
        equipment: true,
      },
    });
    const exercises: CatalogExerciseSnapshot[] = rows.map((e) => ({
      id: e.id,
      name: e.name,
      difficulty: e.difficulty,
      movementPattern: e.movementPattern,
      place: e.place as 'home' | 'gym' | 'calisthenics',
      equipmentIds: e.equipment.map((eq) => eq.equipmentItemId),
      muscles: e.muscles.map((m) => ({ muscleId: m.muscleId, role: m.role as 'primary' | 'secondary' | 'stabilizer' })),
    }));
    return { exercises };
  }

  private async getNextVersionNumber(planId: string): Promise<number> {
    const last = await this.prisma.trainingPlanVersion.findFirst({
      where: { planId },
      orderBy: { version: 'desc' },
      select: { version: true },
    });
    return (last?.version ?? 0) + 1;
  }

  private async toGenerateResponse(
    plan: { id: string; userId: string; createdAt: Date; currentVersionId: string | null },
    version: {
      id: string;
      planId: string;
      version: number;
      createdAt: Date;
      engineVersion: string;
      objectiveScore: number;
      sessions: Array<{
        id: string;
        sessionIndex: number;
        name: string;
        targetDurationMinutes: number;
        exercises: Array<{
          id: string;
          sessionId: string;
          exerciseId: string;
          sets: number;
          repRangeMin: number;
          repRangeMax: number;
          restSeconds: number;
          rirTarget: number;
        }>;
      }>;
    },
  ) {
    return {
      plan: {
        id: plan.id,
        userId: plan.userId,
        createdAt: plan.createdAt.toISOString(),
        currentVersionId: plan.currentVersionId,
      },
      version: {
        id: version.id,
        planId: version.planId,
        version: version.version,
        createdAt: version.createdAt.toISOString(),
        engineVersion: version.engineVersion,
        objectiveScore: version.objectiveScore,
        sessions: version.sessions.map((s) => ({
          id: s.id,
          planVersionId: version.id,
          sessionIndex: s.sessionIndex,
          name: s.name,
          targetDurationMinutes: s.targetDurationMinutes,
          exercises: s.exercises,
        })),
      },
    };
  }

  async getCurrent(userId: UserId) {
    const plan = await this.prisma.trainingPlan.findFirst({
      where: { userId },
      include: {
        currentVersion: {
          include: {
            sessions: {
              orderBy: { sessionIndex: 'asc' },
              include: { exercises: true },
            },
          },
        },
      },
    });
    if (!plan || !plan.currentVersionId || !plan.currentVersion) {
      throw new NotFoundException('No current training plan');
    }
    const v = plan.currentVersion;
    return {
      plan: {
        id: plan.id,
        userId: plan.userId,
        createdAt: plan.createdAt.toISOString(),
        currentVersionId: plan.currentVersionId,
      },
      version: {
        id: v.id,
        planId: v.planId,
        version: v.version,
        createdAt: v.createdAt.toISOString(),
        engineVersion: v.engineVersion,
        objectiveScore: v.objectiveScore,
        sessions: v.sessions.map((s: { id: string; planVersionId: string; sessionIndex: number; name: string; targetDurationMinutes: number; exercises: unknown[] }) => ({
          id: s.id,
          planVersionId: v.id,
          sessionIndex: s.sessionIndex,
          name: s.name,
          targetDurationMinutes: s.targetDurationMinutes,
          exercises: s.exercises,
        })),
      },
    };
  }

  async getVersions(userId: UserId) {
    const plan = await this.prisma.trainingPlan.findFirst({
      where: { userId },
      include: {
        versions: {
          orderBy: { version: 'desc' },
          select: {
            id: true,
            planId: true,
            version: true,
            createdAt: true,
            engineVersion: true,
            objectiveScore: true,
          },
        },
      },
    });
    if (!plan) return [];
    return plan.versions.map((v: { id: string; planId: string; version: number; createdAt: Date; engineVersion: string; objectiveScore: number }) => ({
      id: v.id,
      planId: v.planId,
      version: v.version,
      createdAt: v.createdAt.toISOString(),
      engineVersion: v.engineVersion,
      objectiveScore: v.objectiveScore,
    }));
  }

  async getVersionById(userId: UserId, versionId: string) {
    const version = await this.prisma.trainingPlanVersion.findFirst({
      where: { id: versionId, plan: { userId } },
      include: {
        sessions: {
          orderBy: { sessionIndex: 'asc' },
          include: { exercises: true },
        },
      },
    });
    if (!version) throw new NotFoundException('Version not found');
    return {
      id: version.id,
      planId: version.planId,
      version: version.version,
      createdAt: version.createdAt.toISOString(),
      engineVersion: version.engineVersion,
      objectiveScore: version.objectiveScore,
      sessions: version.sessions.map((s) => ({
        id: s.id,
        planVersionId: version.id,
        sessionIndex: s.sessionIndex,
        name: s.name,
        targetDurationMinutes: s.targetDurationMinutes,
        exercises: s.exercises,
      })),
    };
  }
}
