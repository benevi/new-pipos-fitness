import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { generateNutritionPlan } from '@pipos/engine-rules';
import type {
  NutritionEngineInput,
  FoodSnapshot,
  MealTemplateSnapshot,
} from '@pipos/contracts';
import { NutritionGoalType } from '@pipos/contracts';

type UserId = string;

@Injectable()
export class NutritionPlansService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly usersService: UsersService,
  ) {}

  async generatePlan(userId: UserId, goal?: 'lose_fat' | 'build_muscle' | 'maintain') {
    const user = await this.usersService.getMe(userId);
    const catalog = await this.loadCatalogSnapshot();
    const goalResolved = goal ?? this.deriveGoal(user.goals);
    const dislikedFoodIds = Array.isArray(user.dislikedFoodIds)
      ? (user.dislikedFoodIds as string[])
      : [];

    const engineInput: NutritionEngineInput = {
      user: {
        sex: user.sex ?? undefined,
        heightCm: user.heightCm ?? undefined,
        weightKg: user.weightKg ?? undefined,
        age: user.age ?? undefined,
        preferredTrainingDays: user.preferredTrainingDays ?? undefined,
      },
      goal: goalResolved,
      dislikedFoodIds: dislikedFoodIds.length > 0 ? dislikedFoodIds : undefined,
      catalog,
    };

    const output = generateNutritionPlan(engineInput);

    let plan = await this.prisma.nutritionPlan.findUnique({
      where: { userId },
    });
    if (!plan) {
      plan = await this.prisma.nutritionPlan.create({
        data: { userId },
      });
    }

    const nextVersion = await this.getNextVersionNumber(plan.id);
    const version = await this.prisma.nutritionPlanVersion.create({
      data: {
        planId: plan.id,
        version: nextVersion,
        engineVersion: output.metadata.engineVersion,
      },
    });

    for (const day of output.weekPlan.days) {
      const nutritionDay = await this.prisma.nutritionDay.create({
        data: {
          planVersionId: version.id,
          dayIndex: day.dayIndex,
        },
      });
      for (const meal of day.meals) {
        const nutritionMeal = await this.prisma.nutritionMeal.create({
          data: {
            nutritionDayId: nutritionDay.id,
            mealIndex: meal.mealIndex,
            name: meal.name,
            templateId: meal.templateId ?? undefined,
          },
        });
        for (const item of meal.items) {
          await this.prisma.nutritionMealItem.create({
            data: {
              nutritionMealId: nutritionMeal.id,
              foodId: item.foodId,
              quantityG: item.quantityG,
            },
          });
        }
      }
    }

    await this.prisma.nutritionPlan.update({
      where: { id: plan.id },
      data: { currentVersionId: version.id },
    });

    const versionWithDays = await this.prisma.nutritionPlanVersion.findUnique({
      where: { id: version.id },
      include: {
        days: {
          orderBy: { dayIndex: 'asc' },
          include: {
            meals: {
              orderBy: { mealIndex: 'asc' },
              include: { items: true },
            },
          },
        },
      },
    });
    if (!versionWithDays) throw new Error('Version not found after create');
    return this.toGenerateResponse(plan, versionWithDays, output.metadata);
  }

  private deriveGoal(goals: unknown): 'lose_fat' | 'build_muscle' | 'maintain' {
    if (!Array.isArray(goals) || goals.length === 0) return NutritionGoalType.MAINTAIN;
    const first = goals[0] as { type?: string };
    if (first.type === 'fat_loss') return NutritionGoalType.LOSE_FAT;
    if (first.type === 'muscle_gain') return NutritionGoalType.BUILD_MUSCLE;
    return NutritionGoalType.MAINTAIN;
  }

  private async loadCatalogSnapshot(): Promise<{
    foods: FoodSnapshot[];
    mealTemplates: MealTemplateSnapshot[];
  }> {
    const foods = await this.prisma.food.findMany();
    const templates = await this.prisma.mealTemplate.findMany({
      include: { mealTemplateFoods: true },
    });
    return {
      foods: foods.map((f) => ({
        id: f.id,
        name: f.name,
        caloriesPer100g: f.caloriesPer100g,
        proteinPer100g: f.proteinPer100g,
        carbsPer100g: f.carbsPer100g,
        fatPer100g: f.fatPer100g,
      })),
      mealTemplates: templates.map((t) => ({
        id: t.id,
        name: t.name,
        foods: t.mealTemplateFoods.map((mf) => ({
          foodId: mf.foodId,
          quantityG: mf.quantityG,
        })),
      })),
    };
  }

  private async getNextVersionNumber(planId: string): Promise<number> {
    const last = await this.prisma.nutritionPlanVersion.findFirst({
      where: { planId },
      orderBy: { version: 'desc' },
      select: { version: true },
    });
    return (last?.version ?? 0) + 1;
  }

  private toGenerateResponse(
    plan: { id: string; userId: string; createdAt: Date; currentVersionId: string | null },
    version: {
      id: string;
      planId: string;
      version: number;
      createdAt: Date;
      engineVersion: string;
      days: Array<{
        id: string;
        planVersionId: string;
        dayIndex: number;
        meals: Array<{
          id: string;
          nutritionDayId: string;
          mealIndex: number;
          name: string;
          templateId: string | null;
          items: Array<{
            id: string;
            nutritionMealId: string;
            foodId: string;
            quantityG: number;
          }>;
        }>;
      }>;
    },
    metadata: { dailyCalorieTarget: number; dailyMacroTarget: { proteinG: number; carbsG: number; fatG: number }; macrosClamped?: boolean },
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
        dailyCalorieTarget: metadata.dailyCalorieTarget,
        dailyMacroTarget: metadata.dailyMacroTarget,
        ...(metadata.macrosClamped !== undefined && { macrosClamped: metadata.macrosClamped }),
        days: version.days.map((d) => ({
          id: d.id,
          planVersionId: version.id,
          dayIndex: d.dayIndex,
          meals: d.meals.map((m) => ({
            id: m.id,
            nutritionDayId: d.id,
            mealIndex: m.mealIndex,
            name: m.name,
            templateId: m.templateId,
            items: m.items,
          })),
        })),
      },
    };
  }

  async getCurrent(userId: UserId) {
    const plan = await this.prisma.nutritionPlan.findUnique({
      where: { userId },
      include: {
        currentVersion: {
          include: {
            days: {
              orderBy: { dayIndex: 'asc' },
              include: {
                meals: {
                  orderBy: { mealIndex: 'asc' },
                  include: { items: true },
                },
              },
            },
          },
        },
      },
    });
    if (!plan || !plan.currentVersionId || !plan.currentVersion) {
      throw new NotFoundException('No current nutrition plan');
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
        days: v.days.map((d) => ({
          id: d.id,
          planVersionId: v.id,
          dayIndex: d.dayIndex,
          meals: d.meals.map((m) => ({
            id: m.id,
            nutritionDayId: d.id,
            mealIndex: m.mealIndex,
            name: m.name,
            templateId: m.templateId,
            items: m.items,
          })),
        })),
      },
    };
  }

  async getVersions(userId: UserId) {
    const plan = await this.prisma.nutritionPlan.findUnique({
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
          },
        },
      },
    });
    if (!plan) return [];
    return plan.versions.map((v) => ({
      id: v.id,
      planId: v.planId,
      version: v.version,
      createdAt: v.createdAt.toISOString(),
      engineVersion: v.engineVersion,
    }));
  }
}
