import { z } from 'zod';

/**
 * Enums cerrados del motor v2. Nombres alineados 1:1 con docs/MODELO_DATOS.md.
 */

export const TRAINING_GOALS = [
  'strength',
  'hypertrophy',
  'general_health',
  'fat_loss',
  'muscular_endurance',
] as const;
export const TrainingGoalSchema = z.enum(TRAINING_GOALS);
export type TrainingGoal = z.infer<typeof TrainingGoalSchema>;

export const TRAINING_LEVELS = ['beginner', 'intermediate', 'advanced'] as const;
export const TrainingLevelSchema = z.enum(TRAINING_LEVELS);
export type TrainingLevel = z.infer<typeof TrainingLevelSchema>;

export const EQUIPMENT = [
  'bodyweight',
  'barbell',
  'ez_bar',
  'trap_bar',
  'dumbbell',
  'kettlebell',
  'weight_plate',
  'bench',
  'squat_rack',
  'cable',
  'machine',
  'smith_machine',
  'pull_up_bar',
  'dip_station',
  'gymnastic_rings',
  'suspension_trainer',
  'resistance_band',
  'medicine_ball',
  'plyo_box',
] as const;
export const EquipmentSchema = z.enum(EQUIPMENT);
export type Equipment = z.infer<typeof EquipmentSchema>;

export const BODY_ZONES = ['shoulder', 'elbow', 'wrist', 'lumbar', 'hip', 'knee', 'ankle'] as const;
export const BodyZoneSchema = z.enum(BODY_ZONES);
export type BodyZone = z.infer<typeof BodyZoneSchema>;

export const MUSCLES = [
  'chest',
  'front_delts',
  'side_delts',
  'rear_delts',
  'lats',
  'upper_back',
  'traps',
  'biceps',
  'triceps',
  'forearms',
  'abs',
  'obliques',
  'lower_back',
  'glutes',
  'quads',
  'hamstrings',
  'adductors',
  'abductors',
  'calves',
] as const;
export const MuscleSchema = z.enum(MUSCLES);
export type Muscle = z.infer<typeof MuscleSchema>;

export const MUSCLE_ROLES = ['primary', 'secondary'] as const;
export const MuscleRoleSchema = z.enum(MUSCLE_ROLES);
export type MuscleRole = z.infer<typeof MuscleRoleSchema>;

export const MOVEMENT_PATTERNS = [
  'squat',
  'hinge',
  'lunge',
  'horizontal_push',
  'vertical_push',
  'horizontal_pull',
  'vertical_pull',
  'elbow_flexion',
  'elbow_extension',
  'shoulder_isolation',
  'knee_extension',
  'knee_flexion',
  'hip_isolation',
  'calf_raise',
  'core_anti_extension',
  'core_anti_rotation',
  'core_flexion',
  'carry',
] as const;
export const MovementPatternSchema = z.enum(MOVEMENT_PATTERNS);
export type MovementPattern = z.infer<typeof MovementPatternSchema>;

export const RISK_LEVELS = ['caution', 'avoid'] as const;
export const RiskLevelSchema = z.enum(RISK_LEVELS);
export type RiskLevel = z.infer<typeof RiskLevelSchema>;

export const SEXES = ['male', 'female', 'other'] as const;
export const SexSchema = z.enum(SEXES);
export type Sex = z.infer<typeof SexSchema>;

/**
 * Grupos de volumen del motor (agregación de músculos). Ver PROGRAMACION.md §16.1.
 */
export const VOLUME_GROUPS = [
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'quads',
  'hamstrings',
  'glutes',
  'calves',
  'core',
] as const;
export const VolumeGroupSchema = z.enum(VOLUME_GROUPS);
export type VolumeGroup = z.infer<typeof VolumeGroupSchema>;
