/// Perfil y consentimiento de salud (contracts/src/schemas/profile.ts).
library;

import 'enums.dart';
import 'json.dart';
import 'plan.dart';

/// Versión vigente del texto de consentimiento de salud
/// (`HEALTH_CONSENT_POLICY.version` en los contratos). El texto se muestra
/// desde los ARB (`healthConsentText`), que deben corresponder a esta
/// versión; si cambia, hay que actualizar ambos.
const healthConsentPolicyVersion = 'health-2026-11';

/// Límites del formulario (los mismos que valida Zod).
class ProfileLimits {
  ProfileLimits._();
  static const minDays = 2;
  static const maxDays = 6;
  static const minMinutes = 30;
  static const maxMinutes = 90;
  static const maxPriorityMuscles = 3;
  static const minBirthYear = 1900;
  static const minWeightKg = 25.0;
  static const maxWeightKg = 400.0;
  static const minHeightCm = 100.0;
  static const maxHeightCm = 250.0;

  /// v1 excluye menores de edad (SPEC_V1, no-objetivos).
  static const minAge = 18;
}

/// PUT /me/profile (sustitución completa).
class ProfileUpsertRequest {
  const ProfileUpsertRequest({
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.minutesPerSession,
    required this.equipment,
    required this.timezone,
    this.priorityMuscles = const [],
    this.activityLevel,
    this.birthYear,
    this.sex,
    this.bannedExerciseSlugs = const [],
    this.favouriteExerciseSlugs = const [],
    this.limitations = const [],
    this.weightKg,
    this.heightCm,
  });

  final TrainingGoal goal;
  final TrainingLevel level;
  final int daysPerWeek;
  final int minutesPerSession;
  final List<Equipment> equipment;
  final List<Muscle> priorityMuscles;
  final String timezone;
  final ActivityLevel? activityLevel;
  final int? birthYear;
  final Sex? sex;
  final List<String> bannedExerciseSlugs;
  final List<String> favouriteExerciseSlugs;
  final List<BodyZone> limitations;
  final double? weightKg;
  final double? heightCm;

  Json toJson() => {
    'goal': goal.wire,
    'level': level.wire,
    'daysPerWeek': daysPerWeek,
    'minutesPerSession': minutesPerSession,
    'equipment': wires(equipment),
    'priorityMuscles': wires(priorityMuscles),
    'timezone': timezone,
    'activityLevel': activityLevel?.wire,
    'birthYear': birthYear,
    'sex': sex?.wire,
    'bannedExerciseSlugs': bannedExerciseSlugs,
    'favouriteExerciseSlugs': favouriteExerciseSlugs,
    'limitations': wires(limitations),
    'weightKg': weightKg == null ? null : jsonNum(weightKg!),
    'heightCm': heightCm == null ? null : jsonNum(heightCm!),
  };
}

class HealthConsentStatus {
  const HealthConsentStatus({
    required this.granted,
    required this.version,
    required this.grantedAt,
    required this.currentVersion,
  });

  final bool granted;
  final String? version;
  final DateTime? grantedAt;
  final String currentVersion;

  /// Concedido y para la versión vigente del texto.
  bool get isValid => granted && version == currentVersion;

  factory HealthConsentStatus.fromJson(Json j) => HealthConsentStatus(
    granted: j.boolean('granted'),
    version: j.strOrNull('version'),
    grantedAt: j.dateTimeOrNull('grantedAt'),
    currentVersion: j.str('currentVersion'),
  );

  Json toJson() => {
    'granted': granted,
    'version': version,
    'grantedAt': grantedAt == null ? null : isoUtc(grantedAt!),
    'currentVersion': currentVersion,
  };
}

class ProfileResponse {
  const ProfileResponse({
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.minutesPerSession,
    required this.equipment,
    required this.priorityMuscles,
    required this.timezone,
    required this.activityLevel,
    required this.birthYear,
    required this.sex,
    required this.bannedExerciseSlugs,
    required this.favouriteExerciseSlugs,
    required this.limitations,
    required this.weightKg,
    required this.heightCm,
    required this.healthConsent,
    required this.updatedAt,
  });

  final TrainingGoal goal;
  final TrainingLevel level;
  final int daysPerWeek;
  final int minutesPerSession;
  final List<Equipment> equipment;
  final List<Muscle> priorityMuscles;
  final String timezone;
  final ActivityLevel? activityLevel;
  final int? birthYear;
  final Sex? sex;
  final List<String> bannedExerciseSlugs;
  final List<String> favouriteExerciseSlugs;
  final List<BodyZone> limitations;
  final double? weightKg;
  final double? heightCm;
  final HealthConsentStatus healthConsent;
  final DateTime updatedAt;

  factory ProfileResponse.fromJson(Json j) => ProfileResponse(
    goal: j.enumValue('goal', TrainingGoal.values),
    level: j.enumValue('level', TrainingLevel.values),
    daysPerWeek: j.integer('daysPerWeek'),
    minutesPerSession: j.integer('minutesPerSession'),
    equipment: j.enumList('equipment', Equipment.values),
    priorityMuscles: j.enumList('priorityMuscles', Muscle.values),
    timezone: j.str('timezone'),
    activityLevel: j.enumOrNull('activityLevel', ActivityLevel.values),
    birthYear: j.intOrNull('birthYear'),
    sex: j.enumOrNull('sex', Sex.values),
    bannedExerciseSlugs: j.strList('bannedExerciseSlugs'),
    favouriteExerciseSlugs: j.strList('favouriteExerciseSlugs'),
    limitations: j.enumList('limitations', BodyZone.values),
    weightKg: j.numOrNull('weightKg'),
    heightCm: j.numOrNull('heightCm'),
    healthConsent: HealthConsentStatus.fromJson(j.obj('healthConsent')),
    updatedAt: j.dateTime('updatedAt'),
  );

  Json toJson() => {
    'goal': goal.wire,
    'level': level.wire,
    'daysPerWeek': daysPerWeek,
    'minutesPerSession': minutesPerSession,
    'equipment': wires(equipment),
    'priorityMuscles': wires(priorityMuscles),
    'timezone': timezone,
    'activityLevel': activityLevel?.wire,
    'birthYear': birthYear,
    'sex': sex?.wire,
    'bannedExerciseSlugs': bannedExerciseSlugs,
    'favouriteExerciseSlugs': favouriteExerciseSlugs,
    'limitations': wires(limitations),
    'weightKg': weightKg == null ? null : jsonNum(weightKg!),
    'heightCm': heightCm == null ? null : jsonNum(heightCm!),
    'healthConsent': healthConsent.toJson(),
    'updatedAt': isoUtc(updatedAt),
  };
}

class ProfileUpdateResponse {
  const ProfileUpdateResponse({required this.profile, this.planVersion});

  final ProfileResponse profile;

  /// Nueva versión del plan si el cambio lo afecta (CUJ-6).
  final PlanVersionSummary? planVersion;

  factory ProfileUpdateResponse.fromJson(Json j) => ProfileUpdateResponse(
    profile: ProfileResponse.fromJson(j.obj('profile')),
    planVersion: j.objOrNull('planVersion') == null
        ? null
        : PlanVersionSummary.fromJson(j.obj('planVersion')),
  );

  Json toJson() => {
    'profile': profile.toJson(),
    'planVersion': planVersion?.toJson(),
  };
}

class WithdrawHealthConsentResponse {
  const WithdrawHealthConsentResponse({
    required this.healthConsent,
    this.planVersion,
  });

  final HealthConsentStatus healthConsent;
  final PlanVersionSummary? planVersion;

  factory WithdrawHealthConsentResponse.fromJson(Json j) =>
      WithdrawHealthConsentResponse(
        healthConsent: HealthConsentStatus.fromJson(j.obj('healthConsent')),
        planVersion: j.objOrNull('planVersion') == null
            ? null
            : PlanVersionSummary.fromJson(j.obj('planVersion')),
      );

  Json toJson() => {
    'healthConsent': healthConsent.toJson(),
    'planVersion': planVersion?.toJson(),
  };
}
