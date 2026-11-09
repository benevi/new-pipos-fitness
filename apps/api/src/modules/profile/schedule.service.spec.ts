import { describe, expect, it, vi } from 'vitest';
import type { PrismaService } from '../../prisma/prisma.service';
import { prismaMock, rejectsWithCode, UID } from '../../test/unit/support';
import type { AnalyticsService } from '../analytics/analytics.service';
import type { ProfileService } from './profile.service';
import { ScheduleService, toBreakResponse } from './schedule.service';

const day = (d: string) => new Date(`${d}T00:00:00.000Z`);
const CREATED = new Date('2026-11-01T08:00:00.000Z');
const breakRow = (over: Partial<{ id: string; clientId: string; startsOn: Date; endsOn: Date }> = {}) => ({
  id: 'b1',
  clientId: '22222222-2222-4222-8222-222222222222',
  startsOn: day('2026-11-10'),
  endsOn: day('2026-11-16'),
  createdAt: CREATED,
  ...over,
});

function setup() {
  const prisma = prismaMock();
  const analytics = { lockUser: vi.fn(), recomputeWeeksBetween: vi.fn() };
  const profiles = { get: vi.fn().mockResolvedValue({ profile: 'ok' }) };
  const service = new ScheduleService(
    prisma as unknown as PrismaService,
    analytics as unknown as AnalyticsService,
    profiles as unknown as ProfileService,
  );
  return { prisma, analytics, profiles, service };
}

describe('ScheduleService (días de entreno y pausas, idea 6)', () => {
  it('toBreakResponse: fechas locales y createdAt ISO', () => {
    expect(toBreakResponse(breakRow())).toEqual({
      id: 'b1',
      clientId: '22222222-2222-4222-8222-222222222222',
      startsOn: '2026-11-10',
      endsOn: '2026-11-16',
      createdAt: CREATED.toISOString(),
    });
  });

  describe('setWeekdays', () => {
    it('sin perfil → 404 PROFILE_REQUIRED', async () => {
      const { prisma, service } = setup();
      prisma.trainingProfile.findUnique.mockResolvedValue(null);
      await rejectsWithCode(service.setWeekdays(UID, { trainingWeekdays: [1] }), 'PROFILE_REQUIRED', 404);
    });

    it('más días que daysPerWeek → 422 con el campo', async () => {
      const { prisma, service } = setup();
      prisma.trainingProfile.findUnique.mockResolvedValue({ daysPerWeek: 2 });
      await rejectsWithCode(service.setWeekdays(UID, { trainingWeekdays: [1, 3, 5] }), 'VALIDATION_FAILED', 422);
      expect(prisma.trainingProfile.update).not.toHaveBeenCalled();
    });

    it('guarda los días ordenados y recalcula las semanas de cada pausa', async () => {
      const { prisma, analytics, profiles, service } = setup();
      prisma.trainingProfile.findUnique.mockResolvedValue({ daysPerWeek: 3 });
      prisma.trainingBreak.findMany.mockResolvedValue([breakRow()]);
      await expect(service.setWeekdays(UID, { trainingWeekdays: [5, 1, 3] })).resolves.toEqual({ profile: 'ok' });
      expect(analytics.lockUser).toHaveBeenCalledWith(prisma, UID);
      expect(prisma.trainingProfile.update).toHaveBeenCalledWith({
        where: { userId: UID },
        data: { trainingWeekdays: [1, 3, 5] },
      });
      expect(analytics.recomputeWeeksBetween).toHaveBeenCalledWith(prisma, UID, '2026-11-10', '2026-11-16');
      expect(profiles.get).toHaveBeenCalledWith(UID);
    });
  });

  describe('listBreaks', () => {
    it('sin `from` lista todas; con `from` filtra por fin', async () => {
      const { prisma, service } = setup();
      prisma.trainingBreak.findMany.mockResolvedValue([breakRow()]);
      await expect(service.listBreaks(UID, {})).resolves.toEqual({ items: [toBreakResponse(breakRow())] });
      expect(prisma.trainingBreak.findMany.mock.calls[0][0].where).toEqual({ userId: UID });
      await service.listBreaks(UID, { from: '2026-11-12' });
      expect(prisma.trainingBreak.findMany.mock.calls[1][0].where).toEqual({
        userId: UID,
        endsOn: { gte: day('2026-11-12') },
      });
    });
  });

  describe('createBreak', () => {
    const input = { clientId: breakRow().clientId, startsOn: '2026-11-10', endsOn: '2026-11-16' };

    it('reenvío con el mismo clientId y fechas → la existente, sin crear', async () => {
      const { prisma, analytics, service } = setup();
      prisma.trainingBreak.findUnique.mockResolvedValue(breakRow());
      await expect(service.createBreak(UID, input)).resolves.toEqual({ value: toBreakResponse(breakRow()), created: false });
      expect(prisma.trainingBreak.create).not.toHaveBeenCalled();
      expect(analytics.recomputeWeeksBetween).not.toHaveBeenCalled();
    });

    it('mismo clientId con otras fechas → 409 CLIENT_ID_CONFLICT', async () => {
      const { prisma, service } = setup();
      prisma.trainingBreak.findUnique.mockResolvedValue(breakRow({ endsOn: day('2026-11-20') }));
      await rejectsWithCode(service.createBreak(UID, input), 'CLIENT_ID_CONFLICT', 409);
    });

    it('solapada con otra → 409 CONFLICT', async () => {
      const { prisma, service } = setup();
      prisma.trainingBreak.findUnique.mockResolvedValue(null);
      prisma.trainingBreak.findFirst.mockResolvedValue({ id: 'otra' });
      await rejectsWithCode(service.createBreak(UID, input), 'CONFLICT', 409);
      expect(prisma.trainingBreak.create).not.toHaveBeenCalled();
    });

    it('nueva → la crea y recalcula sus semanas', async () => {
      const { prisma, analytics, service } = setup();
      prisma.trainingBreak.findUnique.mockResolvedValue(null);
      prisma.trainingBreak.findFirst.mockResolvedValue(null);
      prisma.trainingBreak.create.mockResolvedValue(breakRow());
      await expect(service.createBreak(UID, input)).resolves.toEqual({ value: toBreakResponse(breakRow()), created: true });
      expect(prisma.trainingBreak.create).toHaveBeenCalledWith({
        data: { userId: UID, clientId: input.clientId, startsOn: day('2026-11-10'), endsOn: day('2026-11-16') },
      });
      expect(analytics.recomputeWeeksBetween).toHaveBeenCalledWith(prisma, UID, '2026-11-10', '2026-11-16');
    });
  });

  describe('deleteBreak', () => {
    it('ajena o inexistente → no hace nada (idempotente)', async () => {
      const { prisma, analytics, service } = setup();
      prisma.trainingBreak.findFirst.mockResolvedValue(null);
      await service.deleteBreak(UID, 'b1');
      expect(prisma.trainingBreak.findFirst).toHaveBeenCalledWith({ where: { id: 'b1', userId: UID } });
      expect(prisma.trainingBreak.delete).not.toHaveBeenCalled();
      expect(analytics.recomputeWeeksBetween).not.toHaveBeenCalled();
    });

    it('propia → la borra y recalcula sus semanas', async () => {
      const { prisma, analytics, service } = setup();
      prisma.trainingBreak.findFirst.mockResolvedValue(breakRow());
      await service.deleteBreak(UID, 'b1');
      expect(prisma.trainingBreak.delete).toHaveBeenCalledWith({ where: { id: 'b1' } });
      expect(analytics.recomputeWeeksBetween).toHaveBeenCalledWith(prisma, UID, '2026-11-10', '2026-11-16');
    });
  });
});
