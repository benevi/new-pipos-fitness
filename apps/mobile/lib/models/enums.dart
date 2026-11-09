/// Enums cerrados de la API v1 (packages/contracts/src/enums y engine-v2).
/// Valores de cable idénticos a los de Zod/Prisma. Escritos desde los
/// contratos: si cambia un enum allí, el test de contrato falla.
library;

import 'json.dart';

enum TrainingGoal implements WireEnum {
  strength('strength'),
  hypertrophy('hypertrophy'),
  generalHealth('general_health'),
  fatLoss('fat_loss'),
  muscularEndurance('muscular_endurance');

  const TrainingGoal(this.wire);

  @override
  final String wire;
}

enum TrainingLevel implements WireEnum {
  beginner('beginner'),
  intermediate('intermediate'),
  advanced('advanced');

  const TrainingLevel(this.wire);

  @override
  final String wire;
}

enum Equipment implements WireEnum {
  bodyweight('bodyweight'),
  barbell('barbell'),
  ezBar('ez_bar'),
  trapBar('trap_bar'),
  dumbbell('dumbbell'),
  kettlebell('kettlebell'),
  weightPlate('weight_plate'),
  bench('bench'),
  squatRack('squat_rack'),
  cable('cable'),
  machine('machine'),
  smithMachine('smith_machine'),
  pullUpBar('pull_up_bar'),
  dipStation('dip_station'),
  gymnasticRings('gymnastic_rings'),
  suspensionTrainer('suspension_trainer'),
  resistanceBand('resistance_band'),
  medicineBall('medicine_ball'),
  plyoBox('plyo_box');

  const Equipment(this.wire);

  @override
  final String wire;
}

enum BodyZone implements WireEnum {
  shoulder('shoulder'),
  elbow('elbow'),
  wrist('wrist'),
  lumbar('lumbar'),
  hip('hip'),
  knee('knee'),
  ankle('ankle');

  const BodyZone(this.wire);

  @override
  final String wire;
}

enum Muscle implements WireEnum {
  chest('chest'),
  frontDelts('front_delts'),
  sideDelts('side_delts'),
  rearDelts('rear_delts'),
  lats('lats'),
  upperBack('upper_back'),
  traps('traps'),
  biceps('biceps'),
  triceps('triceps'),
  forearms('forearms'),
  abs('abs'),
  obliques('obliques'),
  lowerBack('lower_back'),
  glutes('glutes'),
  quads('quads'),
  hamstrings('hamstrings'),
  adductors('adductors'),
  abductors('abductors'),
  calves('calves');

  const Muscle(this.wire);

  @override
  final String wire;
}

enum MuscleRole implements WireEnum {
  primary('primary'),
  secondary('secondary');

  const MuscleRole(this.wire);

  @override
  final String wire;
}

enum MovementPattern implements WireEnum {
  squat('squat'),
  hinge('hinge'),
  lunge('lunge'),
  horizontalPush('horizontal_push'),
  verticalPush('vertical_push'),
  horizontalPull('horizontal_pull'),
  verticalPull('vertical_pull'),
  elbowFlexion('elbow_flexion'),
  elbowExtension('elbow_extension'),
  shoulderIsolation('shoulder_isolation'),
  kneeExtension('knee_extension'),
  kneeFlexion('knee_flexion'),
  hipIsolation('hip_isolation'),
  calfRaise('calf_raise'),
  coreAntiExtension('core_anti_extension'),
  coreAntiRotation('core_anti_rotation'),
  coreFlexion('core_flexion'),
  carry('carry');

  const MovementPattern(this.wire);

  @override
  final String wire;
}

enum RiskLevel implements WireEnum {
  caution('caution'),
  avoid('avoid');

  const RiskLevel(this.wire);

  @override
  final String wire;
}

enum Sex implements WireEnum {
  male('male'),
  female('female'),
  other('other');

  const Sex(this.wire);

  @override
  final String wire;
}

enum VolumeGroup implements WireEnum {
  chest('chest'),
  back('back'),
  shoulders('shoulders'),
  biceps('biceps'),
  triceps('triceps'),
  quads('quads'),
  hamstrings('hamstrings'),
  glutes('glutes'),
  calves('calves'),
  core('core');

  const VolumeGroup(this.wire);

  @override
  final String wire;
}

enum ActivityLevel implements WireEnum {
  sedentaryLight('sedentary_light'),
  active('active'),
  vigorous('vigorous');

  const ActivityLevel(this.wire);

  @override
  final String wire;
}

enum NutritionGoal implements WireEnum {
  fatLoss('fat_loss'),
  maintenance('maintenance'),
  muscleGain('muscle_gain');

  const NutritionGoal(this.wire);

  @override
  final String wire;
}

enum SplitType implements WireEnum {
  fullBody('full_body'),
  upperLower('upper_lower'),
  hybridUlPpl('hybrid_ul_ppl'),
  pushPullLegs('push_pull_legs');

  const SplitType(this.wire);

  @override
  final String wire;
}

enum SessionKind implements WireEnum {
  fullBody('full_body'),
  upper('upper'),
  lower('lower'),
  push('push'),
  pull('pull'),
  legs('legs');

  const SessionKind(this.wire);

  @override
  final String wire;
}

enum ExerciseRole implements WireEnum {
  main('main'),
  secondary('secondary'),
  accessory('accessory'),
  core('core');

  const ExerciseRole(this.wire);

  @override
  final String wire;
}

enum LoadType implements WireEnum {
  weighted('weighted'),
  unweighted('unweighted');

  const LoadType(this.wire);

  @override
  final String wire;
}

enum WorkoutStatus implements WireEnum {
  inProgress('in_progress'),
  completed('completed'),
  abandoned('abandoned');

  const WorkoutStatus(this.wire);

  @override
  final String wire;
}

enum ProgressionAction implements WireEnum {
  start('start'),
  increaseLoad('increase_load'),
  increaseReps('increase_reps'),
  hold('hold'),
  decreaseLoad('decrease_load'),
  deload('deload'),
  returnAfterBreak('return_after_break'),
  progressVariant('progress_variant');

  const ProgressionAction(this.wire);

  @override
  final String wire;
}

enum WarningCode implements WireEnum {
  patternUncovered('PATTERN_UNCOVERED'),
  volumeBelowFloor('VOLUME_BELOW_FLOOR'),
  frequencyBelowMin('FREQUENCY_BELOW_MIN'),
  timeUnderused('TIME_UNDERUSED'),
  timeOverBudget('TIME_OVER_BUDGET'),
  priorityUncovered('PRIORITY_UNCOVERED'),
  pushPullImbalance('PUSH_PULL_IMBALANCE'),
  daysAboveLevelGuide('DAYS_ABOVE_LEVEL_GUIDE'),
  favouriteExcluded('FAVOURITE_EXCLUDED'),
  pinnedSubstitutionDropped('PINNED_SUBSTITUTION_DROPPED');

  const WarningCode(this.wire);

  @override
  final String wire;
}

enum Role implements WireEnum {
  user('user'),
  admin('admin');

  const Role(this.wire);

  @override
  final String wire;
}

enum AppLocale implements WireEnum {
  es('es'),
  en('en');

  const AppLocale(this.wire);

  @override
  final String wire;
}

enum PlanStatus implements WireEnum {
  active('active'),
  archived('archived');

  const PlanStatus(this.wire);

  @override
  final String wire;
}

enum ConsentPurpose implements WireEnum {
  healthDataProcessing('health_data_processing');

  const ConsentPurpose(this.wire);

  @override
  final String wire;
}

enum ConsentAction implements WireEnum {
  granted('granted'),
  withdrawn('withdrawn');

  const ConsentAction(this.wire);

  @override
  final String wire;
}

enum VolumeStatus implements WireEnum {
  below('below'),
  within('within'),
  above('above'),
  noTarget('no_target');

  const VolumeStatus(this.wire);

  @override
  final String wire;
}

enum PlanVolumeStatus implements WireEnum {
  below('below'),
  within('within'),
  above('above');

  const PlanVolumeStatus(this.wire);

  @override
  final String wire;
}

/// Material que fija el paso real de carga (PROGRAMACION.md §16.16).
enum LoadImplement implements WireEnum {
  barbell('barbell'),
  trapBar('trap_bar'),
  ezBar('ez_bar'),
  smithMachine('smith_machine'),
  dumbbell('dumbbell'),
  kettlebell('kettlebell'),
  machine('machine'),
  cable('cable'),
  weightPlate('weight_plate');

  const LoadImplement(this.wire);

  @override
  final String wire;
}

/// Ámbitos de datos de salud cubiertos por el consentimiento (ADR-0013).
enum HealthDataScope implements WireEnum {
  weight('weight'),
  height('height'),
  limitations('limitations'),
  bodyMeasurements('body_measurements'),
  derivedEstimates('derived_estimates');

  const HealthDataScope(this.wire);

  @override
  final String wire;
}

/// Estado de la tendencia de peso frente al ritmo del objetivo.
enum WeightTrendStatus implements WireEnum {
  onTrack('on_track'),
  tooFast('too_fast'),
  tooSlow('too_slow'),
  noTarget('no_target'),
  insufficientData('insufficient_data');

  const WeightTrendStatus(this.wire);

  @override
  final String wire;
}

/// Categorías de IMC para adultos de la OMS.
enum BmiCategory implements WireEnum {
  underweight('underweight'),
  normal('normal'),
  preObese('pre_obese'),
  obeseClass1('obese_class_1'),
  obeseClass2('obese_class_2'),
  obeseClass3('obese_class_3');

  const BmiCategory(this.wire);

  @override
  final String wire;
}

/// Estado de una estimación de `GET /progress/body` (IMC, % de grasa).
enum EstimateStatus implements WireEnum {
  ok('ok'),
  insufficientData('insufficient_data'),
  consentRequired('consent_required'),
  notApplicable('not_applicable'),
  invalidInput('invalid_input');

  const EstimateStatus(this.wire);

  @override
  final String wire;
}

/// Medidas corporales (nombres de campo del contrato).
enum BodyField implements WireEnum {
  weightKg('weightKg', 25, 400),
  waistCm('waistCm', 40, 250),
  neckCm('neckCm', 20, 70),
  hipCm('hipCm', 50, 250),
  chestCm('chestCm', 50, 220),
  armCm('armCm', 15, 80),
  thighCm('thighCm', 25, 120);

  const BodyField(this.wire, this.min, this.max);

  @override
  final String wire;

  /// Rango válido (BODY_MEASUREMENT_RANGES del contrato).
  final double min;
  final double max;

  /// Los perímetros requieren el ámbito `body_measurements`; el peso, `weight`.
  HealthDataScope get scope => this == weightKg
      ? HealthDataScope.weight
      : HealthDataScope.bodyMeasurements;
}
