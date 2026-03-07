import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type {
  UserGoalsUpdateRequest,
  UserMuscleFocusUpdateRequest,
  UserPreferencesUpdateRequest,
  UserProfileUpdateRequest,
} from '@pipos/contracts';
import { TrainingLocation } from '@prisma/client';

type UserId = string;

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: UserId) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        createdAt: true,
        updatedAt: true,
        heightCm: true,
        weightKg: true,
        age: true,
        sex: true,
        trainingLevel: true,
        preferredTrainingDays: true,
        availableEquipment: true,
        trainingLocation: true,
        goals: true,
        muscleFocus: true,
      },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  async updateProfile(userId: UserId, input: UserProfileUpdateRequest) {
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        heightCm: input.heightCm,
        weightKg: input.weightKg,
        age: input.age,
        sex: input.sex ?? undefined,
      },
    });
    return this.getMe(userId);
  }

  async updatePreferences(userId: UserId, input: UserPreferencesUpdateRequest) {
    const data: Record<string, unknown> = {};
    if (input.trainingLevel !== undefined) data.trainingLevel = input.trainingLevel;
    if (input.preferredTrainingDays !== undefined)
      data.preferredTrainingDays = input.preferredTrainingDays;
    if (input.availableEquipment !== undefined) data.availableEquipment = input.availableEquipment;
    if (input.trainingLocation !== undefined)
      data.trainingLocation = input.trainingLocation as TrainingLocation | undefined;
    await this.prisma.user.update({
      where: { id: userId },
      data,
    });
    return this.getMe(userId);
  }

  async updateGoals(userId: UserId, input: UserGoalsUpdateRequest) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { goals: input.goals ?? undefined },
    });
    return this.getMe(userId);
  }

  async updateMuscleFocus(userId: UserId, input: UserMuscleFocusUpdateRequest) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { muscleFocus: input.muscleFocus ?? undefined },
    });
    return this.getMe(userId);
  }
}
