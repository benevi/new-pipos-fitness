import { z } from 'zod';

export const AIQuestionRequestSchema = z.object({
  question: z.string().min(1).max(2000),
});
export type AIQuestionRequest = z.infer<typeof AIQuestionRequestSchema>;

export const AIExerciseSwapProposalSchema = z.object({
  type: z.literal('exercise_swap'),
  fromExerciseId: z.string(),
  toExerciseId: z.string(),
});
export type AIExerciseSwapProposal = z.infer<typeof AIExerciseSwapProposalSchema>;

export const AIExerciseRemoveProposalSchema = z.object({
  type: z.literal('exercise_remove'),
  exerciseId: z.string(),
});
export type AIExerciseRemoveProposal = z.infer<typeof AIExerciseRemoveProposalSchema>;

export const AIExerciseAddProposalSchema = z.object({
  type: z.literal('exercise_add'),
  exerciseId: z.string(),
  sessionIndex: z.number().int().min(0),
});
export type AIExerciseAddProposal = z.infer<typeof AIExerciseAddProposalSchema>;

export const AINutritionSwapProposalSchema = z.object({
  type: z.literal('nutrition_swap'),
  fromFoodId: z.string(),
  toFoodId: z.string(),
});
export type AINutritionSwapProposal = z.infer<typeof AINutritionSwapProposalSchema>;

export const AIVolumeAdjustmentProposalSchema = z.object({
  type: z.literal('volume_adjustment'),
  exerciseId: z.string(),
  newSets: z.number().int().min(1).max(10),
});
export type AIVolumeAdjustmentProposal = z.infer<typeof AIVolumeAdjustmentProposalSchema>;

export const AIProposalSchema = z.discriminatedUnion('type', [
  AIExerciseSwapProposalSchema,
  AIExerciseRemoveProposalSchema,
  AIExerciseAddProposalSchema,
  AINutritionSwapProposalSchema,
  AIVolumeAdjustmentProposalSchema,
]);
export type AIProposal = z.infer<typeof AIProposalSchema>;

export const AIProposalStatusSchema = z.enum(['valid', 'rejected']);
export type AIProposalStatus = z.infer<typeof AIProposalStatusSchema>;

export const AIResponseTypeSchema = z.enum(['explanation', 'answer', 'proposal']);
export type AIResponseType = z.infer<typeof AIResponseTypeSchema>;

export const AIResponseSchema = z
  .object({
    responseType: AIResponseTypeSchema,
    content: z.string().min(1),
    proposal: AIProposalSchema.optional(),
    proposalStatus: AIProposalStatusSchema.optional(),
    /** Present when proposalStatus is 'rejected'; human-readable reason from validator. */
    rejectionReason: z.string().optional(),
  })
  .superRefine((value, ctx) => {
    if (value.responseType === 'proposal' && !value.proposal) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'proposal is required when responseType is proposal',
        path: ['proposal'],
      });
    }
    if (value.responseType !== 'proposal' && value.proposal) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'proposal must be omitted unless responseType is proposal',
        path: ['proposal'],
      });
    }
    if (value.responseType === 'proposal' && !value.proposalStatus) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'proposalStatus is required when responseType is proposal',
        path: ['proposalStatus'],
      });
    }
    if (value.responseType !== 'proposal' && value.proposalStatus) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'proposalStatus must be omitted unless responseType is proposal',
        path: ['proposalStatus'],
      });
    }
  });
export type AIResponse = z.infer<typeof AIResponseSchema>;
