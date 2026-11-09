/// Borrador del cuestionario (CUJ-1) y su validación por campo.
///
/// Nada se rellena por defecto (SPEC_V1 P0: «datos inválidos → error en el
/// campo, nunca valores por defecto»): objetivo, nivel, días y minutos
/// empiezan vacíos y son obligatorios. La validación replica los límites de
/// `ProfileUpsertRequestSchema`; los 422 de la API se mapean a los mismos
/// campos ([OnboardingField.fromApiPath]).
library;

import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/profile.dart';

/// Pasos del cuestionario, en orden.
enum OnboardingStep {
  goal,
  schedule,
  equipment,
  consent,
  limitations,
  preferences,
  body,
  review,
}

/// Campos del formulario (mismo nombre que en la API).
enum OnboardingField {
  goal(OnboardingStep.goal),
  level(OnboardingStep.goal),
  daysPerWeek(OnboardingStep.schedule),
  minutesPerSession(OnboardingStep.schedule),
  equipment(OnboardingStep.equipment),
  limitations(OnboardingStep.limitations),
  priorityMuscles(OnboardingStep.preferences),
  favouriteExerciseSlugs(OnboardingStep.preferences),
  bannedExerciseSlugs(OnboardingStep.preferences),
  birthYear(OnboardingStep.body),
  sex(OnboardingStep.body),
  activityLevel(OnboardingStep.body),
  weightKg(OnboardingStep.body),
  heightCm(OnboardingStep.body),
  timezone(OnboardingStep.body);

  const OnboardingField(this.step);
  final OnboardingStep step;

  static OnboardingField? fromApiPath(String path) {
    final head = path.split('.').first;
    for (final f in values) {
      if (f.name == head) return f;
    }
    return null;
  }
}

/// Mensaje de error diferido (se traduce al pintar).
typedef FieldMessage = String Function(AppLocalizations l10n);

/// Ejercicio elegido como favorito o vetado (slug + nombre para mostrar).
class PickedExercise {
  const PickedExercise({required this.slug, required this.name});
  final String slug;
  final String name;
}

/// Opciones de minutos por sesión que ofrece la UI (la API acepta 30–90).
const minuteChoices = [30, 45, 60, 75, 90];

class ProfileDraft {
  ProfileDraft({
    this.goal,
    this.level,
    this.daysPerWeek,
    this.minutesPerSession,
    Set<Equipment>? equipment,
    this.consent,
    Set<BodyZone>? limitations,
    List<Muscle>? priorityMuscles,
    List<PickedExercise>? favourites,
    List<PickedExercise>? banned,
    this.birthYear = '',
    this.sex,
    this.activityLevel,
    this.weightKg = '',
    this.heightCm = '',
    this.timezone,
  }) : equipment = equipment ?? {},
       limitations = limitations ?? {},
       priorityMuscles = priorityMuscles ?? [],
       favourites = favourites ?? [],
       banned = banned ?? [];

  /// Borrador a partir del perfil guardado (edición desde Ajustes).
  factory ProfileDraft.fromProfile(ProfileResponse p) => ProfileDraft(
    goal: p.goal,
    level: p.level,
    daysPerWeek: p.daysPerWeek,
    minutesPerSession: p.minutesPerSession,
    equipment: p.equipment.toSet(),
    consent: p.healthConsent.isValid,
    limitations: p.limitations.toSet(),
    priorityMuscles: [...p.priorityMuscles],
    favourites: [
      for (final s in p.favouriteExerciseSlugs)
        PickedExercise(slug: s, name: s),
    ],
    banned: [
      for (final s in p.bannedExerciseSlugs) PickedExercise(slug: s, name: s),
    ],
    birthYear: p.birthYear?.toString() ?? '',
    sex: p.sex,
    activityLevel: p.activityLevel,
    weightKg: p.weightKg == null ? '' : _trim(p.weightKg!),
    heightCm: p.heightCm == null ? '' : _trim(p.heightCm!),
    timezone: p.timezone,
  );

  TrainingGoal? goal;
  TrainingLevel? level;
  int? daysPerWeek;
  int? minutesPerSession;
  final Set<Equipment> equipment;

  /// `true` acepta, `false` lo salta, `null` sin responder.
  bool? consent;
  final Set<BodyZone> limitations;
  final List<Muscle> priorityMuscles;
  final List<PickedExercise> favourites;
  final List<PickedExercise> banned;
  String birthYear;
  Sex? sex;
  ActivityLevel? activityLevel;
  String weightKg;
  String heightCm;
  String? timezone;

  bool get hasConsent => consent == true;

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  static double? _parseNum(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  /// Errores de los campos de [step]. Vacío = se puede avanzar.
  Map<OnboardingField, FieldMessage> validateStep(
    OnboardingStep step, {
    required int currentYear,
  }) {
    final e = <OnboardingField, FieldMessage>{};
    switch (step) {
      case OnboardingStep.goal:
        if (goal == null) e[OnboardingField.goal] = (l) => l.validationRequired;
        if (level == null) {
          e[OnboardingField.level] = (l) => l.validationRequired;
        }
      case OnboardingStep.schedule:
        final d = daysPerWeek;
        if (d == null) {
          e[OnboardingField.daysPerWeek] = (l) => l.validationRequired;
        } else if (d < ProfileLimits.minDays || d > ProfileLimits.maxDays) {
          e[OnboardingField.daysPerWeek] = (l) => l.validationRange(
            '${ProfileLimits.minDays}',
            '${ProfileLimits.maxDays}',
          );
        }
        final m = minutesPerSession;
        if (m == null) {
          e[OnboardingField.minutesPerSession] = (l) => l.validationRequired;
        } else if (m < ProfileLimits.minMinutes ||
            m > ProfileLimits.maxMinutes) {
          e[OnboardingField.minutesPerSession] = (l) => l.validationRange(
            '${ProfileLimits.minMinutes}',
            '${ProfileLimits.maxMinutes}',
          );
        }
      case OnboardingStep.equipment:
        if (equipment.isEmpty) {
          e[OnboardingField.equipment] = (l) => l.validationEquipmentRequired;
        }
      case OnboardingStep.consent:
      case OnboardingStep.limitations:
      case OnboardingStep.review:
        break;
      case OnboardingStep.preferences:
        if (priorityMuscles.length > ProfileLimits.maxPriorityMuscles) {
          e[OnboardingField.priorityMuscles] = (l) =>
              l.validationPriorityMax(ProfileLimits.maxPriorityMuscles);
        }
        final bannedSlugs = banned.map((b) => b.slug).toSet();
        if (favourites.any((f) => bannedSlugs.contains(f.slug))) {
          e[OnboardingField.favouriteExerciseSlugs] = (l) =>
              l.validationBannedFavourite;
        }
      case OnboardingStep.body:
        if (birthYear.trim().isNotEmpty) {
          final y = int.tryParse(birthYear.trim());
          final maxYear = currentYear - ProfileLimits.minAge;
          if (y == null) {
            e[OnboardingField.birthYear] = (l) => l.validationNumber;
          } else if (y < ProfileLimits.minBirthYear) {
            e[OnboardingField.birthYear] = (l) =>
                l.validationRange('${ProfileLimits.minBirthYear}', '$maxYear');
          } else if (y > maxYear) {
            e[OnboardingField.birthYear] = (l) =>
                l.validationAdult(ProfileLimits.minAge);
          }
        }
        if (hasConsent) {
          _checkNum(
            e,
            OnboardingField.weightKg,
            weightKg,
            ProfileLimits.minWeightKg,
            ProfileLimits.maxWeightKg,
          );
          _checkNum(
            e,
            OnboardingField.heightCm,
            heightCm,
            ProfileLimits.minHeightCm,
            ProfileLimits.maxHeightCm,
          );
        }
    }
    return e;
  }

  static void _checkNum(
    Map<OnboardingField, FieldMessage> e,
    OnboardingField field,
    String raw,
    double min,
    double max,
  ) {
    if (raw.trim().isEmpty) return;
    final v = _parseNum(raw);
    if (v == null) {
      e[field] = (l) => l.validationNumber;
    } else if (v < min || v > max) {
      e[field] = (l) => l.validationRange(_trim(min), _trim(max));
    }
  }

  /// Valida todos los pasos aplicables.
  Map<OnboardingField, FieldMessage> validateAll({required int currentYear}) =>
      {
        for (final s in OnboardingStep.values)
          ...validateStep(s, currentYear: currentYear),
      };

  /// Petición para `PUT /me/profile`. Sin consentimiento, los campos de salud
  /// van vacíos (la API los rechazaría con 409 HEALTH_CONSENT_REQUIRED).
  ProfileUpsertRequest toRequest({required String fallbackTimezone}) {
    return ProfileUpsertRequest(
      goal: goal!,
      level: level!,
      daysPerWeek: daysPerWeek!,
      minutesPerSession: minutesPerSession!,
      equipment: Equipment.values.where(equipment.contains).toList(),
      priorityMuscles: [...priorityMuscles],
      timezone: timezone ?? fallbackTimezone,
      activityLevel: activityLevel,
      birthYear: int.tryParse(birthYear.trim()),
      sex: sex,
      bannedExerciseSlugs: banned.map((b) => b.slug).toList(),
      favouriteExerciseSlugs: favourites.map((f) => f.slug).toList(),
      limitations: hasConsent
          ? BodyZone.values.where(limitations.contains).toList()
          : const [],
      weightKg: hasConsent ? _parseNum(weightKg) : null,
      heightCm: hasConsent ? _parseNum(heightCm) : null,
    );
  }
}

/// Atajos de material.
class EquipmentPresets {
  EquipmentPresets._();

  static const bodyweight = {Equipment.bodyweight};
  static const home = {
    Equipment.bodyweight,
    Equipment.dumbbell,
    Equipment.bench,
    Equipment.pullUpBar,
    Equipment.resistanceBand,
  };
  static final gym = Equipment.values.toSet();
}
