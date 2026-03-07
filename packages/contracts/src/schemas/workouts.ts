import { z } from 'zod';

export const StartWorkoutRequestSchema = z.object({
  planSessionId: z.string().uuid().optional(),
});
export type StartWorkoutRequest = z.infer<typeof StartWorkoutRequestSchema>;

export const WorkoutSetSchema = z.object({
  id: z.string().uuid(),
  workoutExerciseId: z.string().uuid(),
  setIndex: z.number().int().min(0),
  weightKg: z.number().positive().nullable(),
  reps: z.number().int().min(0).nullable(),
  rir: z.number().int().min(0).max(10).nullable(),
  completed: z.boolean(),
});
export type WorkoutSet = z.infer<typeof WorkoutSetSchema>;

export const WorkoutExerciseSchema = z.object({
  id: z.string().uuid(),
  workoutSessionId: z.string().uuid(),
  exerciseId: z.string(),
  order: z.number().int().min(0),
  sets: z.array(WorkoutSetSchema),
});
export type WorkoutExercise = z.infer<typeof WorkoutExerciseSchema>;

export const WorkoutSessionSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  planSessionId: z.string().uuid().nullable(),
  planVersionId: z.string().uuid().nullable(),
  startedAt: z.string().datetime(),
  completedAt: z.string().datetime().nullable(),
  durationMinutes: z.number().int().min(0).nullable(),
  notes: z.string().nullable(),
  exercises: z.array(WorkoutExerciseSchema),
});
export type WorkoutSession = z.infer<typeof WorkoutSessionSchema>;

export const StartWorkoutResponseSchema = WorkoutSessionSchema;
export type StartWorkoutResponse = z.infer<typeof StartWorkoutResponseSchema>;

export const AddExerciseToWorkoutRequestSchema = z.object({
  exerciseId: z.string(),
});
export type AddExerciseToWorkoutRequest = z.infer<typeof AddExerciseToWorkoutRequestSchema>;

export const LogSetRequestSchema = z.object({
  weightKg: z.number().positive().optional(),
  reps: z.number().int().min(0).optional(),
  rir: z.number().int().min(0).max(10).optional(),
  completed: z.boolean().optional(),
});
export type LogSetRequest = z.infer<typeof LogSetRequestSchema>;

export const FinishWorkoutRequestSchema = z.object({
  durationMinutes: z.number().int().min(0).optional(),
  notes: z.string().optional(),
});
export type FinishWorkoutRequest = z.infer<typeof FinishWorkoutRequestSchema>;

export const WorkoutHistoryResponseSchema = z.array(WorkoutSessionSchema);
export type WorkoutHistoryResponse = z.infer<typeof WorkoutHistoryResponseSchema>;
