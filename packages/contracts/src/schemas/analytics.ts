import { z } from 'zod';

/** Single set for progress computation (no DB). */
export const SetRecordSchema = z.object({
  weightKg: z.number().positive().nullable(),
  reps: z.number().int().min(0).nullable(),
  rir: z.number().int().min(0).max(10).nullable(),
  completed: z.boolean(),
});
export type SetRecord = z.infer<typeof SetRecordSchema>;

export const ExerciseProgressItemSchema = z.object({
  exerciseId: z.string(),
  estimated1RM: z.number().positive().nullable(),
  volumeLastWeek: z.number().min(0).nullable(),
  volumeTrend: z.enum(['up', 'down', 'stable']).nullable(),
  fatigueScore: z.number().min(0).max(1).nullable(),
  lastUpdated: z.string().datetime().nullable(),
});
export type ExerciseProgressItem = z.infer<typeof ExerciseProgressItemSchema>;

export const ProgressResponseSchema = z.object({
  exercises: z.array(ExerciseProgressItemSchema),
  adherenceScore: z.number().min(0).max(1).nullable(),
  fatigueDetected: z.boolean(),
});
export type ProgressResponse = z.infer<typeof ProgressResponseSchema>;

export const VolumeByExerciseSchema = z.object({
  exerciseId: z.string(),
  volume: z.number().min(0),
});
export const VolumeByMuscleSchema = z.object({
  muscleId: z.string(),
  volume: z.number().min(0),
});

export const VolumeResponseSchema = z.object({
  byExercise: z.array(VolumeByExerciseSchema),
  byMuscle: z.array(VolumeByMuscleSchema),
  weekStart: z.string().datetime().optional(),
  weekEnd: z.string().datetime().optional(),
});
export type VolumeResponse = z.infer<typeof VolumeResponseSchema>;
