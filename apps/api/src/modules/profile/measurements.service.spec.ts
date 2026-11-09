import { Prisma } from '@prisma/client';
import { describe, expect, it } from 'vitest';
import { UpsertBodyMeasurementRequestSchema } from '@pipos/contracts';
import { scopesFor, toMeasurementResponse } from './measurements.service';

describe('medidas corporales (idea 7)', () => {
  const parse = (b: Record<string, unknown>) => UpsertBodyMeasurementRequestSchema.parse({ measuredOn: '2026-11-01', ...b });

  it('ámbitos del consentimiento que necesita cada medida', () => {
    expect(scopesFor(parse({ weightKg: 80 }))).toEqual(['weight']);
    expect(scopesFor(parse({ waistCm: 85 }))).toEqual(['body_measurements']);
    expect(scopesFor(parse({ weightKg: 80, thighCm: 55 }))).toEqual(['weight', 'body_measurements']);
  });

  it('el contrato exige al menos una medida y rangos plausibles', () => {
    expect(UpsertBodyMeasurementRequestSchema.safeParse({ measuredOn: '2026-11-01' }).success).toBe(false);
    expect(UpsertBodyMeasurementRequestSchema.safeParse({ measuredOn: '2026-11-01', neckCm: 19 }).success).toBe(false);
    expect(UpsertBodyMeasurementRequestSchema.safeParse({ measuredOn: '2026-11-01', chestCm: 221 }).success).toBe(false);
  });

  it('mapea decimales a números y fechas a YYYY-MM-DD', () => {
    const at = new Date('2026-11-01T08:00:00.000Z');
    expect(
      toMeasurementResponse({
        id: 'm1',
        userId: 'u1',
        measuredOn: new Date('2026-11-01T00:00:00.000Z'),
        weightKg: new Prisma.Decimal('80.25'),
        waistCm: new Prisma.Decimal('85.5'),
        neckCm: null,
        hipCm: null,
        chestCm: null,
        armCm: null,
        thighCm: null,
        createdAt: at,
        updatedAt: at,
      }),
    ).toEqual({
      measuredOn: '2026-11-01',
      weightKg: 80.25,
      waistCm: 85.5,
      neckCm: null,
      hipCm: null,
      chestCm: null,
      armCm: null,
      thighCm: null,
      updatedAt: at.toISOString(),
    });
  });
});
