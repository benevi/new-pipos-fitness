import { Injectable } from '@nestjs/common';
import type { ExerciseNoteListResponse, ExerciseNoteRequest, ExerciseNoteResponse } from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { PrismaService } from '../../prisma/prisma.service';
import type { Db } from '../plans/engine-input.service';

type NoteRow = {
  exerciseId: string;
  text: string;
  clientUpdatedAt: Date;
  updatedAt: Date;
  exercise: { slug: string };
};

export function toNoteResponse(row: NoteRow): ExerciseNoteResponse {
  return {
    exerciseId: row.exerciseId,
    slug: row.exercise.slug,
    text: row.text,
    clientUpdatedAt: row.clientUpdatedAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}

const noteSelect = {
  exerciseId: true,
  text: true,
  clientUpdatedAt: true,
  updatedAt: true,
  exercise: { select: { slug: true } },
} as const;

/**
 * Nota fija por ejercicio (idea 2, ADR-0013). Es del ejercicio, no del hueco del plan: se
 * mantiene al sustituir y entre versiones del plan. El texto nunca se registra en logs.
 */
@Injectable()
export class NotesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string): Promise<ExerciseNoteListResponse> {
    const rows = await this.prisma.userExerciseNote.findMany({
      where: { userId },
      orderBy: { exerciseId: 'asc' },
      select: noteSelect,
    });
    return { items: rows.map(toNoteResponse) };
  }

  /** Notas de varios ejercicios (para la sesión de hoy). Solo lectura. */
  async byExercise(userId: string, exerciseIds: string[], db: Db = this.prisma): Promise<Map<string, string>> {
    if (exerciseIds.length === 0) return new Map();
    const rows = await db.userExerciseNote.findMany({
      where: { userId, exerciseId: { in: exerciseIds } },
      select: { exerciseId: true, text: true },
    });
    return new Map(rows.map((r) => [r.exerciseId, r.text]));
  }

  /** Upsert con «última escritura gana» por `clientUpdatedAt` (ADR-0007). */
  async put(userId: string, exerciseId: string, input: ExerciseNoteRequest): Promise<ExerciseNoteResponse> {
    const exercise = await this.prisma.exercise.findFirst({ where: { id: exerciseId, deletedAt: null }, select: { id: true } });
    if (!exercise) throw ApiError.notFound('Exercise not found');
    const incoming = new Date(input.clientUpdatedAt);
    return this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT 1 AS locked FROM pg_advisory_xact_lock(hashtextextended(${userId}, 0))`;
      const existing = await tx.userExerciseNote.findUnique({
        where: { userId_exerciseId: { userId, exerciseId } },
        select: noteSelect,
      });
      if (existing && incoming <= existing.clientUpdatedAt) return toNoteResponse(existing);
      const row = await tx.userExerciseNote.upsert({
        where: { userId_exerciseId: { userId, exerciseId } },
        create: { userId, exerciseId, text: input.text, clientUpdatedAt: incoming },
        update: { text: input.text, clientUpdatedAt: incoming },
        select: noteSelect,
      });
      return toNoteResponse(row);
    });
  }

  /** Borrado idempotente (borrar una nota que no existe no es un error). */
  async remove(userId: string, exerciseId: string): Promise<void> {
    await this.prisma.userExerciseNote.deleteMany({ where: { userId, exerciseId } });
  }
}
