import { z } from 'zod';

/**
 * Placeholder schemas. Expand in later phases.
 */
export const HealthResponseSchema = z.object({
  status: z.literal('ok'),
  timestamp: z.string(),
});

export type HealthResponse = z.infer<typeof HealthResponseSchema>;

export * from './auth.js';
export * from './user.js';
export * from './catalog.js';
export * from './training-engine.js';
export * from './workouts.js';
export * from './analytics.js';