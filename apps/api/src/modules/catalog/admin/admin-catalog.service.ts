import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import type {
  AddExerciseMediaRequest,
  CreateExerciseRequest,
  UpdateExerciseRequest,
} from '@pipos/contracts';
import { CurationStatus } from '@prisma/client';
import { TrainingLocation } from '@prisma/client';

@Injectable()
export class AdminCatalogService {
  constructor(private readonly prisma: PrismaService) {}

  async createExercise(body: CreateExerciseRequest) {
    const existing = await this.prisma.exercise.findUnique({ where: { slug: body.slug } });
    if (existing) {
      throw new ConflictException('Exercise with this slug already exists');
    }
    const { muscleIds, ...data } = body;
    const exercise = await this.prisma.exercise.create({
      data: {
        slug: data.slug,
        name: data.name,
        description: data.description ?? null,
        difficulty: data.difficulty,
        movementPattern: data.movementPattern ?? null,
        place: data.place as TrainingLocation,
      },
    });
    if (muscleIds?.length) {
      await this.prisma.exerciseMuscle.createMany({
        data: muscleIds.map((m) => ({
          exerciseId: exercise.id,
          muscleId: m.muscleId,
          role: m.role,
        })),
      });
    }
    return this.prisma.exercise.findUniqueOrThrow({
      where: { id: exercise.id },
      include: { muscles: { include: { muscle: true } } },
    });
  }

  async updateExercise(id: string, body: UpdateExerciseRequest) {
    const exercise = await this.prisma.exercise.findUnique({ where: { id } });
    if (!exercise) {
      throw new NotFoundException('Exercise not found');
    }
    if (body.slug != null && body.slug !== exercise.slug) {
      const existing = await this.prisma.exercise.findUnique({ where: { slug: body.slug } });
      if (existing) {
        throw new ConflictException('Exercise with this slug already exists');
      }
    }
    const { muscleIds, ...data } = body;
    await this.prisma.exercise.update({
      where: { id },
      data: {
        ...(data.slug != null && { slug: data.slug }),
        ...(data.name != null && { name: data.name }),
        ...(data.description !== undefined && { description: data.description }),
        ...(data.difficulty != null && { difficulty: data.difficulty }),
        ...(data.movementPattern !== undefined && { movementPattern: data.movementPattern }),
        ...(data.place != null && { place: data.place as TrainingLocation }),
      },
    });
    if (muscleIds !== undefined) {
      await this.prisma.exerciseMuscle.deleteMany({ where: { exerciseId: id } });
      if (muscleIds.length > 0) {
        await this.prisma.exerciseMuscle.createMany({
          data: muscleIds.map((m) => ({ exerciseId: id, muscleId: m.muscleId, role: m.role })),
        });
      }
    }
    return this.prisma.exercise.findUniqueOrThrow({
      where: { id },
      include: { muscles: { include: { muscle: true } } },
    });
  }

  async addExerciseMedia(exerciseId: string, body: AddExerciseMediaRequest) {
    const exercise = await this.prisma.exercise.findUnique({ where: { id: exerciseId } });
    if (!exercise) {
      throw new NotFoundException('Exercise not found');
    }
    return this.prisma.exerciseMediaYouTube.create({
      data: {
        exerciseId,
        youtubeVideoId: body.youtubeVideoId,
        channelName: body.channelName ?? null,
        isPrimary: body.isPrimary ?? false,
        startSeconds: body.startSeconds ?? null,
        endSeconds: body.endSeconds ?? null,
        curationStatus: CurationStatus.pending,
      },
    });
  }

  async approveMedia(id: string) {
    const media = await this.prisma.exerciseMediaYouTube.findUnique({ where: { id } });
    if (!media) {
      throw new NotFoundException('Exercise media not found');
    }
    return this.prisma.exerciseMediaYouTube.update({
      where: { id },
      data: { curationStatus: CurationStatus.approved },
    });
  }

  async rejectMedia(id: string) {
    const media = await this.prisma.exerciseMediaYouTube.findUnique({ where: { id } });
    if (!media) {
      throw new NotFoundException('Exercise media not found');
    }
    return this.prisma.exerciseMediaYouTube.update({
      where: { id },
      data: { curationStatus: CurationStatus.rejected },
    });
  }
}
