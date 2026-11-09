/**
 * Motor de entrenamiento v2 (Fase 2). Funciones puras y deterministas.
 */
export { generatePlan, type GenerateOptions } from './generate.js';
export { nextPrescription, nextPendingSession, daysBetween } from './progression.js';
export { substitutes, muscleSimilarity, type Substitute, type SubstitutesResult } from './substitutes.js';
export { estimateSessionMinutes, type SessionEstimateItem } from './estimate.js';
export { e1rmOfSet, latestE1rm } from './prescription.js';
export { filterCatalog, exclusionReason, availableEquipment, type ExclusionReason } from './filter.js';
export { groupFractions } from './model.js';
export {
  loadImplement,
  loadStepKg,
  roundLoad,
  isLoadStepMultiple,
  barKgFor,
  plateBreakdown,
  type LoadImplement,
  type RoundDirection,
} from './load.js';
export { resolvePins, pinDropReason, type PinDropReason, type ResolvedPins } from './pins.js';
export {
  adjustSession,
  adjustedPrescription,
  type AdjustItem,
  type AdjustResult,
  type AdjustedItem,
  type SessionAdjustment,
} from './adjust.js';
export {
  activeBreak,
  breakDaysInRange,
  daysAwayExcludingBreaks,
  inBreak,
  isoWeekday,
  isScheduledDay,
  plannedSessionsForWeek,
  type PlannedBreak,
  type WeekPlan,
} from './schedule.js';
