/// Planes (contracts/src/schemas/plans.ts y engine-v2/plan.ts).
library;

import 'enums.dart';
import 'json.dart';
import 'workout.dart' show ExerciseRef;

class WarmupSet {
  const WarmupSet({required this.reps, this.loadPct, this.loadKg});

  final int reps;
  final double? loadPct;
  final double? loadKg;

  factory WarmupSet.fromJson(Json j) => WarmupSet(
    reps: j.integer('reps'),
    loadPct: j.numOrNull('loadPct'),
    loadKg: j.numOrNull('loadKg'),
  );

  Json toJson() => {
    'reps': reps,
    'loadPct': loadPct == null ? null : jsonNum(loadPct!),
    'loadKg': loadKg == null ? null : jsonNum(loadKg!),
  };
}

class PlanExercise {
  const PlanExercise({
    required this.id,
    required this.order,
    required this.exerciseId,
    required this.slug,
    required this.nameEs,
    required this.movementPattern,
    required this.loadType,
    required this.role,
    required this.sets,
    required this.repMin,
    required this.repMax,
    required this.targetRir,
    required this.restSeconds,
    required this.initialLoadKg,
    required this.initialLoadIsEstimate,
    required this.warmupSets,
    required this.estimatedMinutes,
    required this.rationale,
    this.loadImplement,
    this.pinned,
  });

  final String id;
  final int order;
  final String exerciseId;
  final String slug;
  final String nameEs;
  final MovementPattern movementPattern;
  final LoadType loadType;
  final ExerciseRole role;
  final int sets;
  final int repMin;
  final int repMax;
  final int targetRir;
  final int restSeconds;
  final double? initialLoadKg;
  final bool initialLoadIsEstimate;
  final List<WarmupSet> warmupSets;
  final double estimatedMinutes;
  final List<String> rationale;

  /// Material que fija el paso de carga; null sin carga en kg.
  final LoadImplement? loadImplement;

  /// Ejercicio fijado por el usuario para este hueco (idea 3); null = el del
  /// plan.
  final ExerciseRef? pinned;

  factory PlanExercise.fromJson(Json j) => PlanExercise(
    id: j.str('id'),
    order: j.integer('order'),
    exerciseId: j.str('exerciseId'),
    slug: j.str('slug'),
    nameEs: j.str('nameEs'),
    movementPattern: j.enumValue('movementPattern', MovementPattern.values),
    loadType: j.enumValue('loadType', LoadType.values),
    role: j.enumValue('role', ExerciseRole.values),
    sets: j.integer('sets'),
    repMin: j.integer('repMin'),
    repMax: j.integer('repMax'),
    targetRir: j.integer('targetRir'),
    restSeconds: j.integer('restSeconds'),
    initialLoadKg: j.numOrNull('initialLoadKg'),
    initialLoadIsEstimate: j.boolean('initialLoadIsEstimate'),
    warmupSets: j.objList('warmupSets', WarmupSet.fromJson),
    estimatedMinutes: j.number('estimatedMinutes'),
    rationale: j.strList('rationale'),
    loadImplement: j.orDefault(
      'loadImplement',
      null,
      (k) => j.enumOrNull(k, LoadImplement.values),
    ),
    pinned: j.orDefault(
      'pinned',
      null,
      (k) => j.objOrNull(k) == null ? null : ExerciseRef.fromJson(j.obj(k)),
    ),
  );

  Json toJson() => {
    'id': id,
    'order': order,
    'exerciseId': exerciseId,
    'slug': slug,
    'nameEs': nameEs,
    'movementPattern': movementPattern.wire,
    'loadType': loadType.wire,
    'role': role.wire,
    'sets': sets,
    'repMin': repMin,
    'repMax': repMax,
    'targetRir': targetRir,
    'restSeconds': restSeconds,
    'initialLoadKg': initialLoadKg == null ? null : jsonNum(initialLoadKg!),
    'initialLoadIsEstimate': initialLoadIsEstimate,
    'loadImplement': loadImplement?.wire,
    'pinned': pinned?.toJson(),
    'warmupSets': warmupSets.map((w) => w.toJson()).toList(),
    'estimatedMinutes': jsonNum(estimatedMinutes),
    'rationale': rationale,
  };
}

class PlanSession {
  const PlanSession({
    required this.id,
    required this.order,
    required this.dayIndex,
    required this.kind,
    required this.name,
    required this.targetMinutes,
    required this.estimatedMinutes,
    required this.rationale,
    required this.exercises,
  });

  final String id;
  final int order;

  /// 0 = lunes … 6 = domingo (semana del motor).
  final int dayIndex;
  final SessionKind kind;
  final String name;
  final int targetMinutes;
  final double estimatedMinutes;
  final List<String> rationale;
  final List<PlanExercise> exercises;

  factory PlanSession.fromJson(Json j) => PlanSession(
    id: j.str('id'),
    order: j.integer('order'),
    dayIndex: j.integer('dayIndex'),
    kind: j.enumValue('kind', SessionKind.values),
    name: j.str('name'),
    targetMinutes: j.integer('targetMinutes'),
    estimatedMinutes: j.number('estimatedMinutes'),
    rationale: j.strList('rationale'),
    exercises: j.objList('exercises', PlanExercise.fromJson),
  );

  Json toJson() => {
    'id': id,
    'order': order,
    'dayIndex': dayIndex,
    'kind': kind.wire,
    'name': name,
    'targetMinutes': targetMinutes,
    'estimatedMinutes': jsonNum(estimatedMinutes),
    'rationale': rationale,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}

class PlanVersionSummary {
  const PlanVersionSummary({
    required this.id,
    required this.planId,
    required this.version,
    required this.engineVersion,
    required this.splitType,
    required this.mesocycleWeeks,
    required this.objectiveScore,
    required this.sessionCount,
    required this.createdAt,
  });

  final String id;
  final String planId;
  final int version;
  final String engineVersion;
  final SplitType splitType;
  final int mesocycleWeeks;
  final double objectiveScore;
  final int sessionCount;
  final DateTime createdAt;

  factory PlanVersionSummary.fromJson(Json j) => PlanVersionSummary(
    id: j.str('id'),
    planId: j.str('planId'),
    version: j.integer('version'),
    engineVersion: j.str('engineVersion'),
    splitType: j.enumValue('splitType', SplitType.values),
    mesocycleWeeks: j.integer('mesocycleWeeks'),
    objectiveScore: j.number('objectiveScore'),
    sessionCount: j.integer('sessionCount'),
    createdAt: j.dateTime('createdAt'),
  );

  Json toJson() => {
    'id': id,
    'planId': planId,
    'version': version,
    'engineVersion': engineVersion,
    'splitType': splitType.wire,
    'mesocycleWeeks': mesocycleWeeks,
    'objectiveScore': jsonNum(objectiveScore),
    'sessionCount': sessionCount,
    'createdAt': isoUtc(createdAt),
  };
}

class EngineWarning {
  const EngineWarning({required this.code, required this.message, this.data});

  final WarningCode code;
  final String message;
  final Json? data;

  factory EngineWarning.fromJson(Json j) => EngineWarning(
    code: j.enumValue('code', WarningCode.values),
    message: j.str('message'),
    data: j.containsKey('data') ? j.objOrNull('data') : null,
  );

  Json toJson() => {
    'code': code.wire,
    'message': message,
    if (data != null) 'data': data,
  };
}

class GroupVolume {
  const GroupVolume({
    required this.group,
    required this.effectiveSets,
    required this.min,
    required this.max,
    required this.sessions,
    required this.isPriority,
    required this.status,
  });

  final VolumeGroup group;
  final double effectiveSets;
  final double min;
  final double max;
  final int sessions;
  final bool isPriority;
  final PlanVolumeStatus status;

  factory GroupVolume.fromJson(Json j) => GroupVolume(
    group: j.enumValue('group', VolumeGroup.values),
    effectiveSets: j.number('effectiveSets'),
    min: j.number('min'),
    max: j.number('max'),
    sessions: j.integer('sessions'),
    isPriority: j.boolean('isPriority'),
    status: j.enumValue('status', PlanVolumeStatus.values),
  );

  Json toJson() => {
    'group': group.wire,
    'effectiveSets': jsonNum(effectiveSets),
    'min': jsonNum(min),
    'max': jsonNum(max),
    'sessions': sessions,
    'isPriority': isPriority,
    'status': status.wire,
  };
}

class PlanVersion {
  const PlanVersion({
    required this.summary,
    required this.splitRationale,
    required this.rationale,
    required this.warnings,
    required this.weeklyVolume,
    required this.sessions,
  });

  final PlanVersionSummary summary;
  final List<String> splitRationale;
  final List<String> rationale;
  final List<EngineWarning> warnings;
  final List<GroupVolume> weeklyVolume;
  final List<PlanSession> sessions;

  String get id => summary.id;
  int get version => summary.version;
  SplitType get splitType => summary.splitType;

  factory PlanVersion.fromJson(Json j) {
    final split = j.obj('split');
    return PlanVersion(
      summary: PlanVersionSummary.fromJson(j),
      splitRationale: split.strList('rationale'),
      rationale: j.strList('rationale'),
      warnings: j.objList('warnings', EngineWarning.fromJson),
      weeklyVolume: j.objList('weeklyVolume', GroupVolume.fromJson),
      sessions: j.objList('sessions', PlanSession.fromJson),
    );
  }

  Json toJson() => {
    ...summary.toJson(),
    'split': {'type': summary.splitType.wire, 'rationale': splitRationale},
    'rationale': rationale,
    'warnings': warnings.map((w) => w.toJson()).toList(),
    'weeklyVolume': weeklyVolume.map((g) => g.toJson()).toList(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };
}

class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  factory Paginated.fromJson(Json j, T Function(Json) read) => Paginated(
    items: j.objList('items', read),
    page: j.integer('page'),
    pageSize: j.integer('pageSize'),
    total: j.integer('total'),
  );

  Json toJson(Json Function(T) write) => {
    'items': items.map(write).toList(),
    'page': page,
    'pageSize': pageSize,
    'total': total,
  };
}

/// PUT/DELETE /plans/current/exercises/:planExerciseId/override (idea 3).
class PlanExerciseOverride {
  const PlanExerciseOverride({
    required this.planVersionId,
    required this.planExerciseIds,
    required this.original,
    required this.pinned,
  });

  final String planVersionId;
  final List<String> planExerciseIds;
  final ExerciseRef original;

  /// null tras volver al original (DELETE).
  final ExerciseRef? pinned;

  factory PlanExerciseOverride.fromJson(Json j) => PlanExerciseOverride(
    planVersionId: j.str('planVersionId'),
    planExerciseIds: j.strList('planExerciseIds'),
    original: ExerciseRef.fromJson(j.obj('original')),
    pinned: j.objOrNull('pinned') == null
        ? null
        : ExerciseRef.fromJson(j.obj('pinned')),
  );

  Json toJson() => {
    'planVersionId': planVersionId,
    'planExerciseIds': planExerciseIds,
    'original': original.toJson(),
    'pinned': pinned?.toJson(),
  };
}
