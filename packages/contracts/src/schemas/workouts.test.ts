import { describe, it, expect } from 'vitest';
import {
  StartWorkoutRequestSchema,
  WorkoutSessionSchema,
  WorkoutExerciseSchema,
  WorkoutSetSchema,
  AddExerciseToWorkoutRequestSchema,
  LogSetRequestSchema,
  FinishWorkoutRequestSchema,
} from './workouts.js';

describe('StartWorkoutRequestSchema', () => {
  it('accepts empty body', () => {
    expect(StartWorkoutRequestSchema.safeParse({}).success).toBe(true);
  });
  it('accepts planSessionId', () => {
    expect(
      StartWorkoutRequestSchema.safeParse({
        planSessionId: '550e8400-e29b-41d4-a716-446655440000',
      }).success,
    ).toBe(true);
  });
  it('rejects invalid uuid', () => {
    expect(StartWorkoutRequestSchema.safeParse({ planSessionId: 'x' }).success).toBe(false);
  });
});

describe('WorkoutSetSchema', () => {
  it('accepts valid set', () => {
    expect(
      WorkoutSetSchema.safeParse({
        id: '550e8400-e29b-41d4-a716-446655440000',
        workoutExerciseId: '550e8400-e29b-41d4-a716-446655440001',
        setIndex: 0,
        weightKg: 80,
        reps: 10,
        rir: 2,
        completed: true,
      }).success,
    ).toBe(true);
  });
  it('accepts nulls for optional fields', () => {
    expect(
      WorkoutSetSchema.safeParse({
        id: '550e8400-e29b-41d4-a716-446655440000',
        workoutExerciseId: '550e8400-e29b-41d4-a716-446655440001',
        setIndex: 0,
        weightKg: null,
        reps: null,
        rir: null,
        completed: false,
      }).success,
    ).toBe(true);
  });
});

describe('LogSetRequestSchema', () => {
  it('accepts empty body', () => {
    expect(LogSetRequestSchema.safeParse({}).success).toBe(true);
  });
  it('accepts full body', () => {
    expect(
      LogSetRequestSchema.safeParse({
        weightKg: 60,
        reps: 12,
        rir: 1,
        completed: true,
      }).success,
    ).toBe(true);
  });
  it('rejects rir > 10', () => {
    expect(LogSetRequestSchema.safeParse({ rir: 11 }).success).toBe(false);
  });
});

describe('AddExerciseToWorkoutRequestSchema', () => {
  it('requires exerciseId', () => {
    expect(AddExerciseToWorkoutRequestSchema.safeParse({}).success).toBe(false);
    expect(
      AddExerciseToWorkoutRequestSchema.safeParse({ exerciseId: 'ex-1' }).success,
    ).toBe(true);
  });
});

describe('FinishWorkoutRequestSchema', () => {
  it('accepts empty body', () => {
    expect(FinishWorkoutRequestSchema.safeParse({}).success).toBe(true);
  });
  it('accepts duration and notes', () => {
    expect(
      FinishWorkoutRequestSchema.safeParse({
        durationMinutes: 45,
        notes: 'Felt good',
      }).success,
    ).toBe(true);
  });
});

describe('WorkoutSessionSchema', () => {
  it('accepts minimal session with exercises and sets', () => {
    expect(
      WorkoutSessionSchema.safeParse({
        id: '550e8400-e29b-41d4-a716-446655440000',
        userId: '550e8400-e29b-41d4-a716-446655440001',
        planSessionId: null,
        startedAt: '2025-01-01T12:00:00.000Z',
        completedAt: null,
        durationMinutes: null,
        notes: null,
        exercises: [
          {
            id: '550e8400-e29b-41d4-a716-446655440002',
            workoutSessionId: '550e8400-e29b-41d4-a716-446655440000',
            exerciseId: 'ex-1',
            order: 0,
            sets: [],
          },
        ],
      }).success,
    ).toBe(true);
  });
});
