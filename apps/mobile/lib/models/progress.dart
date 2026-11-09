/// Progreso, nutrición, catálogo y exportación
/// (contracts/src/schemas/progress.ts, nutrition.ts, catalog.ts, account.ts).
library;

import 'enums.dart';
import 'json.dart';

class E1rmPoint {
  const E1rmPoint({
    required this.date,
    required this.e1rmKg,
    required this.workoutId,
  });

  /// Fecha de calendario `YYYY-MM-DD`.
  final String date;
  final double e1rmKg;
  final String workoutId;

  factory E1rmPoint.fromJson(Json j) => E1rmPoint(
    date: j.str('date'),
    e1rmKg: j.number('e1rmKg'),
    workoutId: j.str('workoutId'),
  );

  Json toJson() => {
    'date': date,
    'e1rmKg': jsonNum(e1rmKg),
    'workoutId': workoutId,
  };
}

class E1rmSeries {
  const E1rmSeries({
    required this.exerciseId,
    required this.slug,
    required this.nameEs,
    required this.latestE1rmKg,
    required this.points,
  });

  final String exerciseId;
  final String slug;
  final String nameEs;
  final double latestE1rmKg;
  final List<E1rmPoint> points;

  factory E1rmSeries.fromJson(Json j) => E1rmSeries(
    exerciseId: j.str('exerciseId'),
    slug: j.str('slug'),
    nameEs: j.str('nameEs'),
    latestE1rmKg: j.number('latestE1rmKg'),
    points: j.objList('points', E1rmPoint.fromJson),
  );

  Json toJson() => {
    'exerciseId': exerciseId,
    'slug': slug,
    'nameEs': nameEs,
    'latestE1rmKg': jsonNum(latestE1rmKg),
    'points': points.map((p) => p.toJson()).toList(),
  };
}

class E1rmResponse {
  const E1rmResponse({required this.formulaVersion, required this.series});

  final String formulaVersion;
  final List<E1rmSeries> series;

  factory E1rmResponse.fromJson(Json j) => E1rmResponse(
    formulaVersion: j.str('formulaVersion'),
    series: j.objList('series', E1rmSeries.fromJson),
  );

  Json toJson() => {
    'formulaVersion': formulaVersion,
    'series': series.map((s) => s.toJson()).toList(),
  };
}

class MuscleVolume {
  const MuscleVolume({
    required this.muscle,
    required this.effectiveSets,
    required this.tonnageKg,
  });

  final Muscle muscle;
  final double effectiveSets;
  final double tonnageKg;

  factory MuscleVolume.fromJson(Json j) => MuscleVolume(
    muscle: j.enumValue('muscle', Muscle.values),
    effectiveSets: j.number('effectiveSets'),
    tonnageKg: j.number('tonnageKg'),
  );

  Json toJson() => {
    'muscle': muscle.wire,
    'effectiveSets': jsonNum(effectiveSets),
    'tonnageKg': jsonNum(tonnageKg),
  };
}

class GroupWeekVolume {
  const GroupWeekVolume({
    required this.group,
    required this.effectiveSets,
    required this.targetMin,
    required this.targetMax,
    required this.status,
  });

  final VolumeGroup group;
  final double effectiveSets;
  final double? targetMin;
  final double? targetMax;
  final VolumeStatus status;

  factory GroupWeekVolume.fromJson(Json j) => GroupWeekVolume(
    group: j.enumValue('group', VolumeGroup.values),
    effectiveSets: j.number('effectiveSets'),
    targetMin: j.numOrNull('targetMin'),
    targetMax: j.numOrNull('targetMax'),
    status: j.enumValue('status', VolumeStatus.values),
  );

  Json toJson() => {
    'group': group.wire,
    'effectiveSets': jsonNum(effectiveSets),
    'targetMin': targetMin == null ? null : jsonNum(targetMin!),
    'targetMax': targetMax == null ? null : jsonNum(targetMax!),
    'status': status.wire,
  };
}

class VolumeWeek {
  const VolumeWeek({
    required this.weekStart,
    required this.muscles,
    required this.groups,
  });

  final String weekStart;
  final List<MuscleVolume> muscles;
  final List<GroupWeekVolume> groups;

  factory VolumeWeek.fromJson(Json j) => VolumeWeek(
    weekStart: j.str('weekStart'),
    muscles: j.objList('muscles', MuscleVolume.fromJson),
    groups: j.objList('groups', GroupWeekVolume.fromJson),
  );

  Json toJson() => {
    'weekStart': weekStart,
    'muscles': muscles.map((m) => m.toJson()).toList(),
    'groups': groups.map((g) => g.toJson()).toList(),
  };
}

class VolumeResponse {
  const VolumeResponse({required this.timezone, required this.weeks});

  final String timezone;
  final List<VolumeWeek> weeks;

  factory VolumeResponse.fromJson(Json j) => VolumeResponse(
    timezone: j.str('timezone'),
    weeks: j.objList('weeks', VolumeWeek.fromJson),
  );

  Json toJson() => {
    'timezone': timezone,
    'weeks': weeks.map((w) => w.toJson()).toList(),
  };
}

class AdherenceWeek {
  const AdherenceWeek({
    required this.weekStart,
    required this.plannedSessions,
    required this.completedSessions,
    required this.plannedSets,
    required this.completedSets,
    required this.sessionRatio,
    this.breakDays = 0,
  });

  final String weekStart;
  final int plannedSessions;
  final int completedSessions;
  final int plannedSets;
  final int completedSets;
  final double sessionRatio;

  /// Días en pausa planificada (ya descontados de `plannedSessions`).
  final int breakDays;

  factory AdherenceWeek.fromJson(Json j) => AdherenceWeek(
    weekStart: j.str('weekStart'),
    plannedSessions: j.integer('plannedSessions'),
    completedSessions: j.integer('completedSessions'),
    plannedSets: j.integer('plannedSets'),
    completedSets: j.integer('completedSets'),
    sessionRatio: j.number('sessionRatio'),
    breakDays: j.orDefault('breakDays', 0, j.integer),
  );

  Json toJson() => {
    'weekStart': weekStart,
    'plannedSessions': plannedSessions,
    'completedSessions': completedSessions,
    'plannedSets': plannedSets,
    'completedSets': completedSets,
    'sessionRatio': jsonNum(sessionRatio),
    'breakDays': breakDays,
  };
}

class AdherenceResponse {
  const AdherenceResponse({
    required this.timezone,
    required this.weeks,
    required this.plannedSessions,
    required this.completedSessions,
    required this.sessionRatio,
  });

  final String timezone;
  final List<AdherenceWeek> weeks;
  final int plannedSessions;
  final int completedSessions;
  final double sessionRatio;

  factory AdherenceResponse.fromJson(Json j) {
    final totals = j.obj('totals');
    return AdherenceResponse(
      timezone: j.str('timezone'),
      weeks: j.objList('weeks', AdherenceWeek.fromJson),
      plannedSessions: totals.integer('plannedSessions'),
      completedSessions: totals.integer('completedSessions'),
      sessionRatio: totals.number('sessionRatio'),
    );
  }

  Json toJson() => {
    'timezone': timezone,
    'weeks': weeks.map((w) => w.toJson()).toList(),
    'totals': {
      'plannedSessions': plannedSessions,
      'completedSessions': completedSessions,
      'sessionRatio': jsonNum(sessionRatio),
    },
  };
}

class NutritionWarning {
  const NutritionWarning({required this.code, required this.message});

  final String code;
  final String message;

  factory NutritionWarning.fromJson(Json j) =>
      NutritionWarning(code: j.str('code'), message: j.str('message'));

  Json toJson() => {'code': code, 'message': message};
}

/// GET /me/nutrition-targets.
class NutritionTargets {
  const NutritionTargets({
    required this.engineVersion,
    required this.kcal,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.reeKcal,
    required this.tdeeKcal,
    required this.pal,
    required this.adjustmentKcal,
    required this.warnings,
    required this.rationale,
    required this.nutritionGoal,
  });

  final String engineVersion;
  final int kcal;
  final int proteinG;
  final int fatG;
  final int carbsG;
  final int reeKcal;
  final int tdeeKcal;
  final double pal;
  final int adjustmentKcal;
  final List<NutritionWarning> warnings;
  final List<String> rationale;
  final NutritionGoal nutritionGoal;

  factory NutritionTargets.fromJson(Json j) => NutritionTargets(
    engineVersion: j.str('engineVersion'),
    kcal: j.integer('kcal'),
    proteinG: j.integer('proteinG'),
    fatG: j.integer('fatG'),
    carbsG: j.integer('carbsG'),
    reeKcal: j.integer('reeKcal'),
    tdeeKcal: j.integer('tdeeKcal'),
    pal: j.number('pal'),
    adjustmentKcal: j.integer('adjustmentKcal'),
    warnings: j.objList('warnings', NutritionWarning.fromJson),
    rationale: j.strList('rationale'),
    nutritionGoal: j.enumValue('nutritionGoal', NutritionGoal.values),
  );

  Json toJson() => {
    'engineVersion': engineVersion,
    'kcal': kcal,
    'proteinG': proteinG,
    'fatG': fatG,
    'carbsG': carbsG,
    'reeKcal': reeKcal,
    'tdeeKcal': tdeeKcal,
    'pal': jsonNum(pal),
    'adjustmentKcal': adjustmentKcal,
    'warnings': warnings.map((w) => w.toJson()).toList(),
    'rationale': rationale,
    'nutritionGoal': nutritionGoal.wire,
  };
}

class ExerciseSummary {
  const ExerciseSummary({
    required this.id,
    required this.slug,
    required this.nameEs,
    required this.nameEn,
    required this.movementPattern,
    required this.isCompound,
    required this.isUnilateral,
    required this.minLevel,
    required this.equipment,
    required this.loadType,
    required this.primaryMuscles,
  });

  final String id;
  final String slug;
  final String nameEs;
  final String nameEn;
  final MovementPattern movementPattern;
  final bool isCompound;
  final bool isUnilateral;
  final TrainingLevel minLevel;
  final List<Equipment> equipment;
  final LoadType loadType;
  final List<Muscle> primaryMuscles;

  /// Nombre en el idioma de la UI (el catálogo trae ES y EN).
  String localizedName(String languageCode) =>
      languageCode == 'en' ? nameEn : nameEs;

  factory ExerciseSummary.fromJson(Json j) => ExerciseSummary(
    id: j.str('id'),
    slug: j.str('slug'),
    nameEs: j.str('nameEs'),
    nameEn: j.str('nameEn'),
    movementPattern: j.enumValue('movementPattern', MovementPattern.values),
    isCompound: j.boolean('isCompound'),
    isUnilateral: j.boolean('isUnilateral'),
    minLevel: j.enumValue('minLevel', TrainingLevel.values),
    equipment: j.enumList('equipment', Equipment.values),
    loadType: j.enumValue('loadType', LoadType.values),
    primaryMuscles: j.enumList('primaryMuscles', Muscle.values),
  );

  Json toJson() => {
    'id': id,
    'slug': slug,
    'nameEs': nameEs,
    'nameEn': nameEn,
    'movementPattern': movementPattern.wire,
    'isCompound': isCompound,
    'isUnilateral': isUnilateral,
    'minLevel': minLevel.wire,
    'equipment': wires(equipment),
    'loadType': loadType.wire,
    'primaryMuscles': wires(primaryMuscles),
  };
}

/// GET /me/export: se guarda tal cual (el usuario se lleva el JSON). Solo se
/// validan los campos de cabecera.
class AccountExport {
  const AccountExport({
    required this.formatVersion,
    required this.exportedAt,
    required this.raw,
  });

  final int formatVersion;
  final DateTime exportedAt;
  final Json raw;

  factory AccountExport.fromJson(Json j) {
    final version = j.integer('formatVersion');
    if (version != 1) throw FormatException('formatVersion $version');
    j.obj('user');
    j.list('workouts', (i) => i);
    return AccountExport(
      formatVersion: version,
      exportedAt: j.dateTime('exportedAt'),
      raw: j,
    );
  }
}
