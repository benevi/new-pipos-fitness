/**
 * Training plan generator: greedy initial + local search. Deterministic.
 */

import { TrainingEngineInputSchema, type TrainingEngineOutput } from '@pipos/contracts';

export function getTrainingEngineVersion(): string {
  return '0.0.1';
}
import { buildInitialPlan } from './initial-solution.js';
import { improvePlan } from './local-search.js';
import { validatePlan } from './constraints.js';
import { buildCatalogMap } from './constraints.js';
import { scorePlan } from './scoring.js';
import { adaptPlanToProgress } from './adaptation.js';

export function generateTrainingPlan(input: unknown): TrainingEngineOutput {
  const parsed = TrainingEngineInputSchema.safeParse(input);
  if (!parsed.success) {
    return {
      metadata: {
        engineVersion: '0.0.1',
        objectiveScore: 0,
        constraintViolations: [
          { code: 'INVALID_INPUT', message: parsed.error.message ?? 'Validation failed' },
        ],
      },
      weekPlan: { sessions: [] },
    };
  }

  const catalog = buildCatalogMap(parsed.data.catalog.exercises);
  let plan = buildInitialPlan(parsed.data);
  plan = improvePlan(plan, parsed.data);
  plan = adaptPlanToProgress(plan, parsed.data.progress, catalog);

  const validation = validatePlan(plan, parsed.data, catalog);
  const score = scorePlan(plan, parsed.data, catalog);

  return {
    ...plan,
    metadata: {
      engineVersion: '0.0.1',
      objectiveScore: score,
      constraintViolations: validation.violations,
    },
  };
}
