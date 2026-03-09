import { describe, it, expect } from 'vitest';
import {
  AIProposalSchema,
  AIResponseSchema,
  AIQuestionRequestSchema,
} from './ai-coach.js';

describe('AIQuestionRequestSchema', () => {
  it('accepts valid question', () => {
    expect(AIQuestionRequestSchema.safeParse({ question: 'Help me' }).success).toBe(true);
  });

  it('rejects empty question', () => {
    expect(AIQuestionRequestSchema.safeParse({ question: '' }).success).toBe(false);
  });
});

describe('AIProposalSchema — discriminated union', () => {
  it('accepts exercise_swap', () => {
    const result = AIProposalSchema.safeParse({
      type: 'exercise_swap',
      fromExerciseId: 'a',
      toExerciseId: 'b',
    });
    expect(result.success).toBe(true);
  });

  it('accepts exercise_remove', () => {
    const result = AIProposalSchema.safeParse({
      type: 'exercise_remove',
      exerciseId: 'a',
    });
    expect(result.success).toBe(true);
  });

  it('accepts exercise_add', () => {
    const result = AIProposalSchema.safeParse({
      type: 'exercise_add',
      exerciseId: 'a',
      sessionIndex: 0,
    });
    expect(result.success).toBe(true);
  });

  it('accepts nutrition_swap', () => {
    const result = AIProposalSchema.safeParse({
      type: 'nutrition_swap',
      fromFoodId: 'a',
      toFoodId: 'b',
    });
    expect(result.success).toBe(true);
  });

  it('accepts volume_adjustment', () => {
    const result = AIProposalSchema.safeParse({
      type: 'volume_adjustment',
      exerciseId: 'a',
      newSets: 4,
    });
    expect(result.success).toBe(true);
  });

  it('rejects unknown proposal type', () => {
    const result = AIProposalSchema.safeParse({
      type: 'unknown_thing',
      foo: 'bar',
    });
    expect(result.success).toBe(false);
  });

  it('rejects exercise_swap with missing fields', () => {
    const result = AIProposalSchema.safeParse({
      type: 'exercise_swap',
      fromExerciseId: 'a',
    });
    expect(result.success).toBe(false);
  });
});

describe('AIResponseSchema — proposalStatus', () => {
  it('accepts proposal response with proposalStatus valid', () => {
    const result = AIResponseSchema.safeParse({
      responseType: 'proposal',
      content: 'Swap suggestion',
      proposal: { type: 'exercise_swap', fromExerciseId: 'a', toExerciseId: 'b' },
      proposalStatus: 'valid',
    });
    expect(result.success).toBe(true);
  });

  it('accepts proposal response with proposalStatus rejected', () => {
    const result = AIResponseSchema.safeParse({
      responseType: 'proposal',
      content: 'Swap rejected',
      proposal: { type: 'exercise_swap', fromExerciseId: 'a', toExerciseId: 'b' },
      proposalStatus: 'rejected',
    });
    expect(result.success).toBe(true);
  });

  it('rejects proposal response without proposalStatus', () => {
    const result = AIResponseSchema.safeParse({
      responseType: 'proposal',
      content: 'Swap',
      proposal: { type: 'exercise_swap', fromExerciseId: 'a', toExerciseId: 'b' },
    });
    expect(result.success).toBe(false);
  });

  it('rejects non-proposal response with proposalStatus', () => {
    const result = AIResponseSchema.safeParse({
      responseType: 'answer',
      content: 'hello',
      proposalStatus: 'valid',
    });
    expect(result.success).toBe(false);
  });

  it('accepts answer response without proposalStatus', () => {
    const result = AIResponseSchema.safeParse({
      responseType: 'answer',
      content: 'hello',
    });
    expect(result.success).toBe(true);
  });

  it('accepts explanation response without proposalStatus', () => {
    const result = AIResponseSchema.safeParse({
      responseType: 'explanation',
      content: 'because...',
    });
    expect(result.success).toBe(true);
  });

  it('rejects proposal response without proposal object', () => {
    const result = AIResponseSchema.safeParse({
      responseType: 'proposal',
      content: 'swap',
      proposalStatus: 'valid',
    });
    expect(result.success).toBe(false);
  });
});
