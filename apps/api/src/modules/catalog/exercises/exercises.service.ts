import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import type { ExerciseFilterQuery } from '@pipos/contracts';
import { CurationStatus } from '@prisma/client';

@Injectable()
export class ExercisesService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: ExerciseFilterQuery) {
    const { page, limit, muscleId, equipmentId, difficulty, movementPattern, place, search } =
      query;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = {};
    if (difficulty != null) where.difficulty = difficulty;
    if (movementPattern != null) where.movementPattern = movementPattern;
    if (place != null) where.place = place;
    if (search != null && search.trim()) {
      where.OR = [
        { name: { contains: search.trim(), mode: 'insensitive' } },
        { description: { contains: search.trim(), mode: 'insensitive' } },
        { slug: { contains: search.trim(), mode: 'insensitive' } },
      ];
    }
    if (muscleId != null) {
      where.muscles = { some: { muscleId } };
    }
    if (equipmentId != null) {
      where.equipment = { some: { equipmentItemId: equipmentId } };
    }

    const [items, totalCount] = await Promise.all([
      this.prisma.exercise.findMany({
        where,
        skip,
        take: limit,
        orderBy: { name: 'asc' },
      }),
      this.prisma.exercise.count({ where }),
    ]);

    return { items, page, limit, totalCount };
  }

  async findOne(id: string) {
    const exercise = await this.prisma.exercise.findUnique({
      where: { id },
      include: {
        muscles: { include: { muscle: true } },
        variants: { include: { variantExercise: { select: { id: true, slug: true, name: true } } } },
        media: true,
      },
    });
    if (!exercise) {
      throw new NotFoundException('Exercise not found');
    }
    return exercise;
  }

  async getMedia(exerciseId: string) {
    const exercise = await this.prisma.exercise.findUnique({
      where: { id: exerciseId },
      select: { id: true },
    });
    if (!exercise) {
      throw new NotFoundException('Exercise not found');
    }
    return this.prisma.exerciseMediaYouTube.findMany({
      where: { exerciseId, curationStatus: CurationStatus.approved },
      orderBy: [{ isPrimary: 'desc' }, { id: 'asc' }],
    });
  }
}
