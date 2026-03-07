/**
 * Training engine. Pure functions only. Phase 4 + 7.
 */

export { generateTrainingPlan, getTrainingEngineVersion } from './engine.js';
export { validatePlan, buildCatalogMap, getCompatibleExercises } from './constraints.js';
export {
  computeE1RM,
  getBestE1RMPerExercise,
  computeVolumePerExercise,
  computeAdherence,
  detectFatigue,
  fatigueScorePerExercise,
  volumeTrend,
} from './progress.js';
export { adaptPlanToProgress } from './adaptation.js';
