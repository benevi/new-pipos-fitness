import { z } from 'zod';
import {
  GoalType,
  MusclePriority,
  Sex,
  TrainingLevel,
  TrainingLocation,
} from '../enums/index.js';

const MAX_EQUIPMENT_ITEMS = 200;
const MAX_GOALS = 10;
const MAX_MUSCLE_FOCUS = 100;

export const AvailableEquipmentSchema = z
  .array(z.string())
  .max(MAX_EQUIPMENT_ITEMS)
  .strict();

export const GoalItemSchema = z
  .object({
    type: z.nativeEnum(GoalType),
    priority: z.number().int().min(1).max(5),
    customText: z.string().optional(),
  })
  .strict()
  .refine(
    (data) => (data.type === 'custom' ? data.customText != null && data.customText.length > 0 : true),
    { message: 'customText is required when type is custom', path: ['customText'] },
  );

export const GoalsSchema = z.array(GoalItemSchema).max(MAX_GOALS).strict();

export const MuscleFocusItemSchema = z
  .object({
    muscleId: z.string(),
    priority: z.nativeEnum(MusclePriority),
  })
  .strict();

export const MuscleFocusSchema = z.array(MuscleFocusItemSchema).max(MAX_MUSCLE_FOCUS).strict();

export const UserProfileUpdateRequestSchema = z.object({
  heightCm: z.number().positive().nullable().optional(),
  weightKg: z.number().positive().nullable().optional(),
  age: z.number().int().positive().nullable().optional(),
  sex: z.nativeEnum(Sex).nullable().optional(),
});

export type UserProfileUpdateRequest = z.infer<typeof UserProfileUpdateRequestSchema>;

export const UserPreferencesUpdateRequestSchema = z.object({
  trainingLevel: z.nativeEnum(TrainingLevel).nullable().optional(),
  preferredTrainingDays: z.number().int().min(0).max(7).nullable().optional(),
  availableEquipment: AvailableEquipmentSchema.nullable().optional(),
  trainingLocation: z.nativeEnum(TrainingLocation).nullable().optional(),
});

export type UserPreferencesUpdateRequest = z.infer<
  typeof UserPreferencesUpdateRequestSchema
>;

export const UserGoalsUpdateRequestSchema = z.object({
  goals: GoalsSchema.nullable().optional(),
});

export type UserGoalsUpdateRequest = z.infer<typeof UserGoalsUpdateRequestSchema>;

export const UserMuscleFocusUpdateRequestSchema = z.object({
  muscleFocus: MuscleFocusSchema.nullable().optional(),
});

export type UserMuscleFocusUpdateRequest = z.infer<
  typeof UserMuscleFocusUpdateRequestSchema
>;
