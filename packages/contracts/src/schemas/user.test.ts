import { describe, it, expect } from 'vitest';
import {
  UserProfileUpdateRequestSchema,
  UserPreferencesUpdateRequestSchema,
  UserGoalsUpdateRequestSchema,
  UserMuscleFocusUpdateRequestSchema,
  AvailableEquipmentSchema,
  GoalsSchema,
  MuscleFocusSchema,
} from './user.js';
import { GoalType, MusclePriority, Sex, TrainingLevel, TrainingLocation } from '../enums/index.js';

describe('UserProfileUpdateRequestSchema', () => {
  it('accepts valid profile fields', () => {
    expect(
      UserProfileUpdateRequestSchema.safeParse({
        heightCm: 180,
        weightKg: 75,
        age: 30,
        sex: Sex.MALE,
      }).success,
    ).toBe(true);
  });
  it('accepts empty object', () => {
    expect(UserProfileUpdateRequestSchema.safeParse({}).success).toBe(true);
  });
});

describe('UserPreferencesUpdateRequestSchema', () => {
  it('accepts valid preferences', () => {
    expect(
      UserPreferencesUpdateRequestSchema.safeParse({
        trainingLevel: TrainingLevel.INTERMEDIATE,
        preferredTrainingDays: 3,
        availableEquipment: ['dumbbells'],
        trainingLocation: TrainingLocation.GYM,
      }).success,
    ).toBe(true);
  });
  it('rejects availableEquipment over 200 items', () => {
    const arr = Array.from({ length: 201 }, (_, i) => `item-${i}`);
    expect(UserPreferencesUpdateRequestSchema.safeParse({ availableEquipment: arr }).success).toBe(
      false,
    );
  });
});

describe('AvailableEquipmentSchema', () => {
  it('accepts array of strings up to 200', () => {
    expect(AvailableEquipmentSchema.safeParse(['a', 'b']).success).toBe(true);
    expect(AvailableEquipmentSchema.safeParse([]).success).toBe(true);
  });
  it('rejects over 200 items', () => {
    expect(AvailableEquipmentSchema.safeParse(Array(201).fill('x')).success).toBe(false);
  });
});

describe('UserGoalsUpdateRequestSchema', () => {
  it('accepts valid goals array', () => {
    expect(
      UserGoalsUpdateRequestSchema.safeParse({
        goals: [
          { type: GoalType.MUSCLE_GAIN, priority: 1 },
          { type: GoalType.CUSTOM, priority: 2, customText: 'Other' },
        ],
      }).success,
    ).toBe(true);
  });
  it('rejects free-form object', () => {
    expect(
      UserGoalsUpdateRequestSchema.safeParse({ goals: { buildMuscle: true } }).success,
    ).toBe(false);
  });
  it('rejects custom without customText', () => {
    expect(
      UserGoalsUpdateRequestSchema.safeParse({
        goals: [{ type: GoalType.CUSTOM, priority: 1 }],
      }).success,
    ).toBe(false);
  });
  it('rejects more than 10 goals', () => {
    const goals = Array.from({ length: 11 }, (_, i) => ({
      type: GoalType.HEALTH,
      priority: Math.min(5, i + 1),
    }));
    expect(UserGoalsUpdateRequestSchema.safeParse({ goals }).success).toBe(false);
  });
});

describe('GoalsSchema', () => {
  it('accepts valid goal items', () => {
    expect(GoalsSchema.safeParse([{ type: GoalType.FAT_LOSS, priority: 1 }]).success).toBe(true);
  });
});

describe('UserMuscleFocusUpdateRequestSchema', () => {
  it('accepts valid muscleFocus array', () => {
    expect(
      UserMuscleFocusUpdateRequestSchema.safeParse({
        muscleFocus: [
          { muscleId: 'chest', priority: MusclePriority.GROW },
          { muscleId: 'back', priority: MusclePriority.MAINTAIN },
        ],
      }).success,
    ).toBe(true);
  });
  it('rejects free-form object', () => {
    expect(
      UserMuscleFocusUpdateRequestSchema.safeParse({ muscleFocus: { chest: 1 } }).success,
    ).toBe(false);
  });
  it('rejects over 100 items', () => {
    const muscleFocus = Array.from({ length: 101 }, (_, i) => ({
      muscleId: `m-${i}`,
      priority: MusclePriority.MAINTAIN,
    }));
    expect(UserMuscleFocusUpdateRequestSchema.safeParse({ muscleFocus }).success).toBe(false);
  });
});

describe('MuscleFocusSchema', () => {
  it('accepts valid items', () => {
    expect(
      MuscleFocusSchema.safeParse([{ muscleId: 'chest', priority: MusclePriority.AVOID }]).success,
    ).toBe(true);
  });
});
