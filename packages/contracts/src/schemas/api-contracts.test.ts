import { describe, expect, it } from 'vitest';
import {
  CalendarDateSchema,
  ExerciseListQuerySchema,
  GrantHealthConsentRequestSchema,
  HEALTH_CONSENT_POLICY,
  PaginationQuerySchema,
  PatchSetRequestSchema,
  ProfileUpsertRequestSchema,
  StartWorkoutRequestSchema,
  TimezoneSchema,
  UpsertSetRequestSchema,
  WeeksQuerySchema,
  isValidTimeZone,
} from '../index.js';

const uuid = '7b0c4a4e-2d0b-4c39-9a51-0f4d2f6f2b11';
const profile = {
  goal: 'hypertrophy',
  level: 'beginner',
  daysPerWeek: 3,
  minutesPerSession: 45,
  equipment: ['dumbbell', 'bench'],
  timezone: 'Europe/Madrid',
};

describe('ProfileUpsertRequestSchema', () => {
  it('acepta un perfil mínimo y deja vacíos (no inventa) los opcionales', () => {
    const p = ProfileUpsertRequestSchema.parse(profile);
    expect(p).toMatchObject({
      priorityMuscles: [],
      limitations: [],
      weightKg: null,
      heightCm: null,
      birthYear: null,
      sex: null,
      activityLevel: null,
      bannedExerciseSlugs: [],
      favouriteExerciseSlugs: [],
    });
  });

  it('rechaza días, minutos y material fuera de rango o repetidos', () => {
    expect(ProfileUpsertRequestSchema.safeParse({ ...profile, daysPerWeek: 7 }).success).toBe(false);
    expect(ProfileUpsertRequestSchema.safeParse({ ...profile, minutesPerSession: 20 }).success).toBe(false);
    expect(ProfileUpsertRequestSchema.safeParse({ ...profile, equipment: ['bench', 'bench'] }).success).toBe(false);
    expect(ProfileUpsertRequestSchema.safeParse({ ...profile, equipment: ['laser'] }).success).toBe(false);
  });

  it('rechaza campos desconocidos y vetado+favorito a la vez', () => {
    expect(ProfileUpsertRequestSchema.safeParse({ ...profile, age: 30 }).success).toBe(false);
    const r = ProfileUpsertRequestSchema.safeParse({
      ...profile,
      bannedExerciseSlugs: ['press-banca'],
      favouriteExerciseSlugs: ['press-banca'],
    });
    expect(r.success).toBe(false);
  });

  it('rechaza zonas horarias inexistentes', () => {
    expect(isValidTimeZone('Europe/Madrid')).toBe(true);
    expect(isValidTimeZone('Mars/Olympus')).toBe(false);
    expect(TimezoneSchema.safeParse('Mars/Olympus').success).toBe(false);
  });
});

describe('consentimiento de salud', () => {
  it('la política tiene versión y texto', () => {
    expect(HEALTH_CONSENT_POLICY.version).toMatch(/^health-/);
    expect(HEALTH_CONSENT_POLICY.textEs.length).toBeGreaterThan(50);
  });
  it('locale por defecto es', () => {
    expect(GrantHealthConsentRequestSchema.parse({ version: 'v1' }).locale).toBe('es');
  });
});

describe('registro de entrenamientos', () => {
  it('StartWorkout exige UUIDs y fecha ISO', () => {
    expect(
      StartWorkoutRequestSchema.safeParse({ clientId: uuid, planSessionId: uuid, startedAt: new Date().toISOString() })
        .success,
    ).toBe(true);
    expect(StartWorkoutRequestSchema.safeParse({ clientId: 'x', planSessionId: uuid, startedAt: 'ayer' }).success).toBe(
      false,
    );
  });

  it('UpsertSet aplica valores por defecto explícitos y límites', () => {
    const s = UpsertSetRequestSchema.parse({
      clientId: uuid,
      exerciseId: uuid,
      setIndex: 0,
      reps: 8,
      loadKg: 40,
      completedAt: '2026-11-09T10:00:00.000Z',
    });
    expect(s).toMatchObject({ planExerciseId: null, rir: null, isWarmup: false });
    expect(UpsertSetRequestSchema.safeParse({ ...s, reps: 101 }).success).toBe(false);
    expect(UpsertSetRequestSchema.safeParse({ ...s, loadKg: -1 }).success).toBe(false);
  });

  it('PatchSet exige al menos un campo y clientUpdatedAt', () => {
    expect(PatchSetRequestSchema.safeParse({ clientUpdatedAt: '2026-11-09T10:00:00.000Z' }).success).toBe(false);
    expect(PatchSetRequestSchema.safeParse({ reps: 5 }).success).toBe(false);
    expect(PatchSetRequestSchema.safeParse({ reps: 5, clientUpdatedAt: '2026-11-09T10:00:00.000Z' }).success).toBe(
      true,
    );
  });
});

describe('queries', () => {
  it('paginación acotada con coerción', () => {
    expect(PaginationQuerySchema.parse({ page: '2', pageSize: '10' })).toEqual({ page: 2, pageSize: 10 });
    expect(PaginationQuerySchema.parse({})).toEqual({ page: 1, pageSize: 20 });
    expect(PaginationQuerySchema.safeParse({ pageSize: '1000' }).success).toBe(false);
  });

  it('lista de material separada por comas', () => {
    expect(ExerciseListQuerySchema.parse({ equipment: 'dumbbell, bench' }).equipment).toEqual(['dumbbell', 'bench']);
    expect(ExerciseListQuerySchema.safeParse({ equipment: 'laser' }).success).toBe(false);
  });

  it('semanas y fechas', () => {
    expect(WeeksQuerySchema.parse({}).weeks).toBe(8);
    expect(WeeksQuerySchema.safeParse({ weeks: '53' }).success).toBe(false);
    expect(CalendarDateSchema.safeParse('2026-11-09').success).toBe(true);
    expect(CalendarDateSchema.safeParse('2026-13-40').success).toBe(false);
  });
});
