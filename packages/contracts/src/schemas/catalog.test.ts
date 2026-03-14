import { describe, it, expect } from 'vitest';
import {
  MuscleSchema,
  EquipmentItemSchema,
  ExerciseSchema,
  ExerciseFilterQuerySchema,
  ExerciseListResponseSchema,
  ExerciseMediaYouTubeSchema,
  CreateExerciseRequestSchema,
} from './catalog.js';
import { MuscleRole, CurationStatus } from '../enums/index.js';

describe('MuscleSchema', () => {
  it('accepts valid muscle', () => {
    expect(MuscleSchema.safeParse({ id: '1', name: 'Chest', region: 'upper' }).success).toBe(true);
  });
});

describe('EquipmentItemSchema', () => {
  it('accepts valid equipment', () => {
    expect(
      EquipmentItemSchema.safeParse({ id: '1', name: 'Dumbbell', category: 'free_weights' }).success,
    ).toBe(true);
  });
});

describe('ExerciseSchema', () => {
  it('accepts valid exercise', () => {
    expect(
      ExerciseSchema.safeParse({
        id: '1',
        slug: 'bench-press',
        name: 'Bench Press',
        description: 'Push',
        difficulty: 2,
        movementPattern: 'push',
        place: 'gym',
      }).success,
    ).toBe(true);
  });
});

describe('ExerciseFilterQuerySchema', () => {
  it('accepts empty and applies defaults', () => {
    const r = ExerciseFilterQuerySchema.safeParse({});
    expect(r.success).toBe(true);
    if (r.success) {
      expect(r.data.page).toBe(1);
      expect(r.data.limit).toBe(20);
    }
  });
  it('accepts all filters', () => {
    expect(
      ExerciseFilterQuerySchema.safeParse({
        muscleId: 'm1',
        equipmentId: 'e1',
        difficulty: 2,
        place: 'gym',
        search: 'press',
        page: 2,
        limit: 10,
      }).success,
    ).toBe(true);
  });
});

describe('ExerciseListResponseSchema', () => {
  it('accepts paginated list', () => {
    expect(
      ExerciseListResponseSchema.safeParse({
        items: [],
        page: 1,
        limit: 20,
        totalCount: 0,
      }).success,
    ).toBe(true);
  });
});

describe('ExerciseMediaYouTubeSchema', () => {
  it('accepts valid media', () => {
    expect(
      ExerciseMediaYouTubeSchema.safeParse({
        id: '1',
        exerciseId: 'e1',
        youtubeVideoId: 'abc123',
        channelName: 'Channel',
        isPrimary: true,
        startSeconds: 0,
        endSeconds: 60,
        curationStatus: CurationStatus.APPROVED,
      }).success,
    ).toBe(true);
  });
});

describe('CreateExerciseRequestSchema', () => {
  it('accepts minimal and full request', () => {
    expect(
      CreateExerciseRequestSchema.safeParse({
        slug: 'squat',
        name: 'Squat',
        difficulty: 2,
        place: 'gym',
      }).success,
    ).toBe(true);
    expect(
      CreateExerciseRequestSchema.safeParse({
        slug: 'squat',
        name: 'Squat',
        difficulty: 2,
        place: 'gym',
        muscleIds: [{ muscleId: 'm1', role: MuscleRole.PRIMARY }],
      }).success,
    ).toBe(true);
  });
});
