/**
 * Context Minimization Policy
 *
 * This builder gathers ONLY the fields needed for AI reasoning.
 * It explicitly EXCLUDES:
 *   - passwordHash, tokenHash, and any auth credentials
 *   - email and other PII not required for fitness reasoning
 *   - internal database IDs beyond those needed for proposal references
 *   - full plan details (only summary counts and exercise ID lists)
 *   - full workout history (only aggregated metrics)
 *
 * Lists are trimmed to reasonable caps to prevent oversized payloads.
 */
import { Injectable, NotFoundException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { TrainingPlansService } from '../training-plans/training-plans.service';
import { NutritionPlansService } from '../nutrition-plans/nutrition-plans.service';
import { AnalyticsService } from '../analytics/analytics.service';

const MAX_EXERCISE_IDS = 50;

export type AICoachContext = {
  profile: {
    id: string;
    sex: string | null;
    age: number | null;
    heightCm: number | null;
    weightKg: number | null;
    trainingLevel: string | null;
    preferredTrainingDays: number | null;
    trainingLocation: string | null;
    availableEquipmentIds: string[];
    goalsCount: number;
    muscleFocusCount: number;
  };
  trainingPlanSummary: {
    versionId: string;
    sessionsCount: number;
    exercisesCount: number;
    exerciseIds: string[];
  } | null;
  nutritionPlanSummary: {
    versionId: string;
    daysCount: number;
    mealsCount: number;
  } | null;
  progressMetrics: {
    adherenceScore: number | null;
    fatigueDetected: boolean;
    trackedExercisesCount: number;
  };
};

@Injectable()
export class ContextBuilderService {
  constructor(
    private readonly usersService: UsersService,
    private readonly trainingPlansService: TrainingPlansService,
    private readonly nutritionPlansService: NutritionPlansService,
    private readonly analyticsService: AnalyticsService,
  ) {}

  async build(userId: string): Promise<AICoachContext> {
    const user = await this.usersService.getMe(userId);
    const [trainingPlanSummary, nutritionPlanSummary, progressMetrics] = await Promise.all([
      this.loadTrainingPlanSummary(userId),
      this.loadNutritionPlanSummary(userId),
      this.loadProgressMetrics(userId),
    ]);

    // Only fitness-relevant profile fields; no email, passwordHash, tokens
    return {
      profile: {
        id: user.id,
        sex: user.sex,
        age: user.age,
        heightCm: user.heightCm,
        weightKg: user.weightKg,
        trainingLevel: user.trainingLevel,
        preferredTrainingDays: user.preferredTrainingDays,
        trainingLocation: user.trainingLocation,
        availableEquipmentIds: Array.isArray(user.availableEquipment)
          ? (user.availableEquipment as string[])
          : [],
        goalsCount: Array.isArray(user.goals) ? user.goals.length : 0,
        muscleFocusCount: Array.isArray(user.muscleFocus) ? user.muscleFocus.length : 0,
      },
      trainingPlanSummary,
      nutritionPlanSummary,
      progressMetrics,
    };
  }

  private async loadTrainingPlanSummary(userId: string): Promise<AICoachContext['trainingPlanSummary']> {
    try {
      const current = await this.trainingPlansService.getCurrent(userId);
      const exerciseIds = current.version.sessions
        .flatMap((session) => session.exercises.map((exercise) => exercise.exerciseId))
        .filter((id, index, arr) => arr.indexOf(id) === index)
        .sort((a, b) => a.localeCompare(b))
        .slice(0, MAX_EXERCISE_IDS);

      return {
        versionId: current.version.id,
        sessionsCount: current.version.sessions.length,
        exercisesCount: current.version.sessions.reduce(
          (sum, session) => sum + session.exercises.length,
          0,
        ),
        exerciseIds,
      };
    } catch (error) {
      if (error instanceof NotFoundException) return null;
      throw error;
    }
  }

  private async loadNutritionPlanSummary(userId: string): Promise<AICoachContext['nutritionPlanSummary']> {
    try {
      const current = await this.nutritionPlansService.getCurrent(userId);
      return {
        versionId: current.version.id,
        daysCount: current.version.days.length,
        mealsCount: current.version.days.reduce((sum, day) => sum + day.meals.length, 0),
      };
    } catch (error) {
      if (error instanceof NotFoundException) return null;
      throw error;
    }
  }

  private async loadProgressMetrics(userId: string): Promise<AICoachContext['progressMetrics']> {
    const progress = await this.analyticsService.getProgress(userId);
    return {
      adherenceScore: progress.adherenceScore,
      fatigueDetected: progress.fatigueDetected,
      trackedExercisesCount: progress.exercises.length,
    };
  }
}
