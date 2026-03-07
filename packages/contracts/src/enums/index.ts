/**
 * Shared enums. Expand in later phases.
 */
export const PlanStatus = {
  DRAFT: 'draft',
  ACTIVE: 'active',
  ARCHIVED: 'archived',
} as const;

export type PlanStatus = (typeof PlanStatus)[keyof typeof PlanStatus];

export const Sex = {
  MALE: 'male',
  FEMALE: 'female',
  OTHER: 'other',
} as const;

export type Sex = (typeof Sex)[keyof typeof Sex];

export const TrainingLevel = {
  BEGINNER: 'beginner',
  INTERMEDIATE: 'intermediate',
  ADVANCED: 'advanced',
} as const;

export type TrainingLevel = (typeof TrainingLevel)[keyof typeof TrainingLevel];

export const TrainingLocation = {
  HOME: 'home',
  GYM: 'gym',
  CALISTHENICS: 'calisthenics',
} as const;

export type TrainingLocation = (typeof TrainingLocation)[keyof typeof TrainingLocation];

export const GoalType = {
  FAT_LOSS: 'fat_loss',
  MUSCLE_GAIN: 'muscle_gain',
  STRENGTH: 'strength',
  ENDURANCE: 'endurance',
  HEALTH: 'health',
  CUSTOM: 'custom',
} as const;

export type GoalType = (typeof GoalType)[keyof typeof GoalType];

export const MusclePriority = {
  AVOID: 'avoid',
  MAINTAIN: 'maintain',
  GROW: 'grow',
} as const;

export type MusclePriority = (typeof MusclePriority)[keyof typeof MusclePriority];

export const MuscleRole = {
  PRIMARY: 'primary',
  SECONDARY: 'secondary',
  STABILIZER: 'stabilizer',
} as const;

export type MuscleRole = (typeof MuscleRole)[keyof typeof MuscleRole];

export const CurationStatus = {
  APPROVED: 'approved',
  PENDING: 'pending',
  REJECTED: 'rejected',
  UNAVAILABLE: 'unavailable',
} as const;

export type CurationStatus = (typeof CurationStatus)[keyof typeof CurationStatus];

export const NutritionGoalType = {
  LOSE_FAT: 'lose_fat',
  BUILD_MUSCLE: 'build_muscle',
  MAINTAIN: 'maintain',
} as const;

export type NutritionGoalType = (typeof NutritionGoalType)[keyof typeof NutritionGoalType];
