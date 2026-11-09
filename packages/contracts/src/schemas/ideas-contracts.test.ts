import { describe, expect, it } from 'vitest';
import {
  AccountExportSchema,
  CalendarDateSchema,
  CreateTrainingBreakRequestSchema,
  ExerciseNoteRequestSchema,
  ProfileScheduleRequestSchema,
  StartWorkoutRequestSchema,
  TodaySessionQuerySchema,
} from '../index.js';

const ID = '11111111-1111-4111-8111-111111111111';

describe('contratos de ADR-0013', () => {
  it('CalendarDate rechaza fechas que no existen', () => {
    expect(CalendarDateSchema.safeParse('2026-11-30').success).toBe(true);
    expect(CalendarDateSchema.safeParse('2026-11-31').success).toBe(false);
    expect(CalendarDateSchema.safeParse('2026-02-29').success).toBe(false);
    expect(CalendarDateSchema.safeParse('2028-02-29').success).toBe(true);
  });

  it('nota: recorta espacios, 1-280 caracteres', () => {
    expect(ExerciseNoteRequestSchema.parse({ text: '  a  ', clientUpdatedAt: '2026-11-09T10:00:00.000Z' }).text).toBe('a');
    expect(ExerciseNoteRequestSchema.safeParse({ text: '   ', clientUpdatedAt: '2026-11-09T10:00:00.000Z' }).success).toBe(false);
    expect(ExerciseNoteRequestSchema.safeParse({ text: 'x'.repeat(281), clientUpdatedAt: '2026-11-09T10:00:00.000Z' }).success).toBe(false);
  });

  it('ajuste de hoy: minutos 15-90 y modo normal/reduced', () => {
    expect(TodaySessionQuerySchema.parse({ minutes: '30', mode: 'reduced' })).toEqual({ minutes: 30, mode: 'reduced' });
    expect(TodaySessionQuerySchema.safeParse({ minutes: '14' }).success).toBe(false);
    expect(TodaySessionQuerySchema.safeParse({ mode: 'turbo' }).success).toBe(false);
    const start = StartWorkoutRequestSchema.parse({
      clientId: ID, planSessionId: ID, startedAt: '2026-11-09T10:00:00.000Z', adjustment: { reducedVolume: true },
    });
    expect(start.adjustment).toEqual({ availableMinutes: null, reducedVolume: true });
  });

  it('días de entreno: 1-7 sin repetir, como mucho 6', () => {
    expect(ProfileScheduleRequestSchema.safeParse({ trainingWeekdays: [1, 3, 5] }).success).toBe(true);
    expect(ProfileScheduleRequestSchema.safeParse({ trainingWeekdays: [1, 1] }).success).toBe(false);
    expect(ProfileScheduleRequestSchema.safeParse({ trainingWeekdays: [8] }).success).toBe(false);
    expect(ProfileScheduleRequestSchema.safeParse({ trainingWeekdays: [1, 2, 3, 4, 5, 6, 7] }).success).toBe(false);
  });

  it('pausa: fin ≥ inicio y como mucho 60 días', () => {
    const b = (startsOn: string, endsOn: string) => CreateTrainingBreakRequestSchema.safeParse({ clientId: ID, startsOn, endsOn }).success;
    expect(b('2026-08-01', '2026-08-01')).toBe(true);
    expect(b('2026-08-01', '2026-09-29')).toBe(true); // 60 días
    expect(b('2026-08-01', '2026-09-30')).toBe(false); // 61 días
    expect(b('2026-08-02', '2026-08-01')).toBe(false);
  });

  it('los campos nuevos de respuesta tienen valor por defecto (clientes y exportaciones anteriores)', () => {
    const parsed = AccountExportSchema.shape.exerciseNotes.parse(undefined);
    expect(parsed).toEqual([]);
    expect(AccountExportSchema.shape.trainingBreaks.parse(undefined)).toEqual([]);
  });
});
