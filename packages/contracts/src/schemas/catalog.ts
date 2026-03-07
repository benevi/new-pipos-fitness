import { z } from 'zod';
import { CurationStatus, MuscleRole, TrainingLocation } from '../enums/index.js';

export const MuscleSchema = z.object({
  id: z.string(),
  name: z.string(),
  region: z.string(),
  meshRegionId: z.string().nullable().optional(),
});

export type Muscle = z.infer<typeof MuscleSchema>;

export const EquipmentItemSchema = z.object({
  id: z.string(),
  name: z.string(),
  category: z.string(),
});

export type EquipmentItem = z.infer<typeof EquipmentItemSchema>;

export const ExercisePlaceSchema = z.nativeEnum(TrainingLocation);
export type ExercisePlace = z.infer<typeof ExercisePlaceSchema>;

export const ExerciseSchema = z.object({
  id: z.string(),
  slug: z.string(),
  name: z.string(),
  description: z.string().nullable(),
  difficulty: z.number().int().min(1).max(5),
  movementPattern: z.string().nullable(),
  place: ExercisePlaceSchema,
});

export type Exercise = z.infer<typeof ExerciseSchema>;

export const ExerciseMuscleSchema = z.object({
  exerciseId: z.string(),
  muscleId: z.string(),
  role: z.nativeEnum(MuscleRole),
  muscle: MuscleSchema.optional(),
});

export const ExerciseVariantSchema = z.object({
  id: z.string(),
  exerciseId: z.string(),
  variantExerciseId: z.string(),
  reason: z.string().nullable(),
});

export const ExerciseMediaYouTubeSchema = z.object({
  id: z.string(),
  exerciseId: z.string(),
  youtubeVideoId: z.string(),
  channelName: z.string().nullable(),
  isPrimary: z.boolean(),
  startSeconds: z.number().int().nullable(),
  endSeconds: z.number().int().nullable(),
  curationStatus: z.nativeEnum(CurationStatus),
});

export type ExerciseMediaYouTube = z.infer<typeof ExerciseMediaYouTubeSchema>;

export const ExerciseDetailSchema = ExerciseSchema.extend({
  muscles: z.array(ExerciseMuscleSchema).optional(),
  variants: z.array(ExerciseVariantSchema).optional(),
  media: z.array(ExerciseMediaYouTubeSchema).optional(),
});

export type ExerciseDetail = z.infer<typeof ExerciseDetailSchema>;

export const ExerciseListResponseSchema = z.object({
  items: z.array(ExerciseSchema),
  page: z.number().int().min(1),
  limit: z.number().int().min(1),
  totalCount: z.number().int().min(0),
});

export type ExerciseListResponse = z.infer<typeof ExerciseListResponseSchema>;

export const ExerciseFilterQuerySchema = z.object({
  muscleId: z.string().optional(),
  equipmentId: z.string().optional(),
  difficulty: z.coerce.number().int().min(1).max(5).optional(),
  movementPattern: z.string().optional(),
  place: ExercisePlaceSchema.optional(),
  search: z.string().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export type ExerciseFilterQuery = z.infer<typeof ExerciseFilterQuerySchema>;

export const CreateExerciseRequestSchema = z.object({
  slug: z.string().min(1),
  name: z.string().min(1),
  description: z.string().nullable().optional(),
  difficulty: z.number().int().min(1).max(5),
  movementPattern: z.string().nullable().optional(),
  place: ExercisePlaceSchema,
  muscleIds: z.array(z.object({ muscleId: z.string(), role: z.nativeEnum(MuscleRole) })).optional(),
});

export type CreateExerciseRequest = z.infer<typeof CreateExerciseRequestSchema>;

export const UpdateExerciseRequestSchema = CreateExerciseRequestSchema.partial();

export type UpdateExerciseRequest = z.infer<typeof UpdateExerciseRequestSchema>;

export const AddExerciseMediaRequestSchema = z.object({
  youtubeVideoId: z.string().min(1),
  channelName: z.string().nullable().optional(),
  isPrimary: z.boolean().default(false),
  startSeconds: z.number().int().min(0).nullable().optional(),
  endSeconds: z.number().int().min(0).nullable().optional(),
});

export type AddExerciseMediaRequest = z.infer<typeof AddExerciseMediaRequestSchema>;
