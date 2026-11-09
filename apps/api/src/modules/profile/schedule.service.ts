import { HttpStatus, Injectable } from '@nestjs/common';
import type {
  CreateTrainingBreakRequest,
  ProfileResponse,
  ProfileScheduleRequest,
  TrainingBreakListQuery,
  TrainingBreakListResponse,
  TrainingBreakResponse,
} from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { dateColumn, fromDateColumn } from '../../common/time';
import { PrismaService } from '../../prisma/prisma.service';
import { AnalyticsService } from '../analytics/analytics.service';
import { ProfileService } from './profile.service';

type BreakRow = { id: string; clientId: string; startsOn: Date; endsOn: Date; createdAt: Date };

export function toBreakResponse(row: BreakRow): TrainingBreakResponse {
  return {
    id: row.id,
    clientId: row.clientId,
    startsOn: fromDateColumn(row.startsOn),
    endsOn: fromDateColumn(row.endsOn),
    createdAt: row.createdAt.toISOString(),
  };
}

/**
 * Días de entreno y pausas planificadas (idea 6, ADR-0013; PROGRAMACION.md §16.18).
 * Ninguna de las dos cosas es una entrada del motor: no crean versiones del plan. Las pausas
 * recalculan, en la misma transacción, la adherencia de las semanas afectadas (ADR-0008).
 * El recordatorio del día de entreno es LOCAL en el móvil: la API solo expone los días.
 */
@Injectable()
export class ScheduleService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly analytics: AnalyticsService,
    private readonly profiles: ProfileService,
  ) {}

  async setWeekdays(userId: string, input: ProfileScheduleRequest): Promise<ProfileResponse> {
    await this.prisma.$transaction(async (tx) => {
      await this.analytics.lockUser(tx, userId);
      const profile = await tx.trainingProfile.findUnique({ where: { userId }, select: { daysPerWeek: true } });
      if (!profile) throw new ApiError(HttpStatus.NOT_FOUND, 'PROFILE_REQUIRED', 'No training profile yet');
      if (input.trainingWeekdays.length > profile.daysPerWeek) {
        throw new ApiError(HttpStatus.UNPROCESSABLE_ENTITY, 'VALIDATION_FAILED', 'More training days than daysPerWeek', [
          { path: 'body.trainingWeekdays', message: `At most ${profile.daysPerWeek} days (your daysPerWeek)` },
        ]);
      }
      await tx.trainingProfile.update({
        where: { userId },
        data: { trainingWeekdays: [...input.trainingWeekdays].sort((a, b) => a - b) },
      });
      // Con días elegidos, las semanas con pausa cuentan los días elegidos fuera de la pausa.
      const breaks = await tx.trainingBreak.findMany({ where: { userId }, select: { startsOn: true, endsOn: true } });
      for (const b of breaks) {
        await this.analytics.recomputeWeeksBetween(tx, userId, fromDateColumn(b.startsOn), fromDateColumn(b.endsOn));
      }
    });
    return this.profiles.get(userId);
  }

  async listBreaks(userId: string, query: TrainingBreakListQuery): Promise<TrainingBreakListResponse> {
    const rows = await this.prisma.trainingBreak.findMany({
      where: { userId, ...(query.from ? { endsOn: { gte: dateColumn(query.from) } } : {}) },
      orderBy: [{ startsOn: 'asc' }, { id: 'asc' }],
      take: 200,
    });
    return { items: rows.map(toBreakResponse) };
  }

  /** Idempotente por clientId; una pausa no puede solaparse con otra (409 CONFLICT). */
  async createBreak(userId: string, input: CreateTrainingBreakRequest): Promise<{ value: TrainingBreakResponse; created: boolean }> {
    return this.prisma.$transaction(async (tx) => {
      await this.analytics.lockUser(tx, userId);
      const existing = await tx.trainingBreak.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (existing) {
        if (fromDateColumn(existing.startsOn) !== input.startsOn || fromDateColumn(existing.endsOn) !== input.endsOn) {
          throw new ApiError(HttpStatus.CONFLICT, 'CLIENT_ID_CONFLICT', 'clientId already used for another break');
        }
        return { value: toBreakResponse(existing), created: false };
      }
      const overlap = await tx.trainingBreak.findFirst({
        where: { userId, startsOn: { lte: dateColumn(input.endsOn) }, endsOn: { gte: dateColumn(input.startsOn) } },
        select: { id: true },
      });
      if (overlap) throw new ApiError(HttpStatus.CONFLICT, 'CONFLICT', 'The break overlaps another planned break');
      const row = await tx.trainingBreak.create({
        data: { userId, clientId: input.clientId, startsOn: dateColumn(input.startsOn), endsOn: dateColumn(input.endsOn) },
      });
      await this.analytics.recomputeWeeksBetween(tx, userId, input.startsOn, input.endsOn);
      return { value: toBreakResponse(row), created: true };
    });
  }

  /** Borrado idempotente (la cola offline puede reenviarlo); una pausa ajena no se toca. */
  async deleteBreak(userId: string, id: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      await this.analytics.lockUser(tx, userId);
      const row = await tx.trainingBreak.findFirst({ where: { id, userId } });
      if (!row) return;
      await tx.trainingBreak.delete({ where: { id } });
      await this.analytics.recomputeWeeksBetween(tx, userId, fromDateColumn(row.startsOn), fromDateColumn(row.endsOn));
    });
  }
}
