import { z } from 'zod';
import { NutritionGoalType } from '../enums/index.js';

export const FoodSnapshotSchema = z.object({
  id: z.string(),
  name: z.string(),
  caloriesPer100g: z.number().min(0),
  proteinPer100g: z.number().min(0),
  carbsPer100g: z.number().min(0),
  fatPer100g: z.number().min(0),
});
export type FoodSnapshot = z.infer<typeof FoodSnapshotSchema>;

export const MealTemplateFoodSnapshotSchema = z.object({
  foodId: z.string(),
  quantityG: z.number().positive(),
});
export type MealTemplateFoodSnapshot = z.infer<typeof MealTemplateFoodSnapshotSchema>;

export const MealTemplateSnapshotSchema = z.object({
  id: z.string(),
  name: z.string(),
  foods: z.array(MealTemplateFoodSnapshotSchema),
});
export type MealTemplateSnapshot = z.infer<typeof MealTemplateSnapshotSchema>;

export const NutritionEngineUserSchema = z.object({
  sex: z.string().optional(),
  heightCm: z.number().positive().nullable().optional(),
  weightKg: z.number().positive().nullable().optional(),
  age: z.number().int().positive().nullable().optional(),
  preferredTrainingDays: z.number().int().min(0).max(7).optional(),
});
export type NutritionEngineUser = z.infer<typeof NutritionEngineUserSchema>;

export const NutritionEngineCatalogSnapshotSchema = z.object({
  foods: z.array(FoodSnapshotSchema),
  mealTemplates: z.array(MealTemplateSnapshotSchema),
});
export type NutritionEngineCatalogSnapshot = z.infer<typeof NutritionEngineCatalogSnapshotSchema>;

export const NutritionEngineInputSchema = z.object({
  user: NutritionEngineUserSchema,
  goal: z.nativeEnum(NutritionGoalType),
  dislikedFoodIds: z.array(z.string()).optional(),
  catalog: NutritionEngineCatalogSnapshotSchema,
});
export type NutritionEngineInput = z.infer<typeof NutritionEngineInputSchema>;

export const NutritionMealItemOutputSchema = z.object({
  foodId: z.string(),
  quantityG: z.number().positive(),
});
export type NutritionMealItemOutput = z.infer<typeof NutritionMealItemOutputSchema>;

export const NutritionMealOutputSchema = z.object({
  mealIndex: z.number().int().min(0),
  name: z.string(),
  templateId: z.string().nullable(),
  items: z.array(NutritionMealItemOutputSchema),
});
export type NutritionMealOutput = z.infer<typeof NutritionMealOutputSchema>;

export const NutritionDayOutputSchema = z.object({
  dayIndex: z.number().int().min(0).max(6),
  meals: z.array(NutritionMealOutputSchema),
});
export type NutritionDayOutput = z.infer<typeof NutritionDayOutputSchema>;

export const NutritionEngineOutputMetadataSchema = z.object({
  engineVersion: z.string(),
  dailyCalorieTarget: z.number().min(0),
  dailyMacroTarget: z.object({
    proteinG: z.number().min(0),
    carbsG: z.number().min(0),
    fatG: z.number().min(0),
  }),
  macrosClamped: z.boolean().optional(),
});
export type NutritionEngineOutputMetadata = z.infer<typeof NutritionEngineOutputMetadataSchema>;

export const NutritionEngineOutputSchema = z.object({
  metadata: NutritionEngineOutputMetadataSchema,
  weekPlan: z.object({
    days: z.array(NutritionDayOutputSchema),
  }),
});
export type NutritionEngineOutput = z.infer<typeof NutritionEngineOutputSchema>;
