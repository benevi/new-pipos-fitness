/**
 * @deprecated Exportaciones del motor v1 que `apps/api` aún importa. Se congelan aquí sin cambios
 * de comportamiento (salvo nutrición, ver nutrition.ts) y se borran en la Fase 3, cuando la API
 * consuma `generatePlan`, `nextPrescription`, `substitutes` y `dailyTargets`.
 */
export * from './training/index.js';
export {
  generateNutritionPlan,
  getNutritionEngineVersion,
  NUTRITION_ENGINE_VERSION,
  NutritionInputError,
} from './nutrition.js';
