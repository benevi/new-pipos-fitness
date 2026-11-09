/// Entrenamientos y sesión de hoy (contracts/src/schemas/workouts.ts).
library;

import 'enums.dart';
import 'json.dart';
import 'plan.dart';

/// POST /workouts (idempotente por `clientId`).
class StartWorkoutRequest {
  const StartWorkoutRequest({
    required this.clientId,
    required this.planSessionId,
    required this.startedAt,
  });

  final String clientId;
  final String planSessionId;
  final DateTime startedAt;

  Json toJson() => {
    'clientId': clientId,
    'planSessionId': planSessionId,
    'startedAt': isoUtc(startedAt),
  };
}

/// POST /workouts/:id/sets (idempotente por `clientId`: 201 la primera vez,
/// 200 al reenviar).
class UpsertSetRequest {
  const UpsertSetRequest({
    required this.clientId,
    required this.planExerciseId,
    required this.exerciseId,
    required this.setIndex,
    required this.reps,
    required this.loadKg,
    required this.rir,
    required this.isWarmup,
    required this.completedAt,
    this.clientUpdatedAt,
  });

  final String clientId;
  final String? planExerciseId;
  final String exerciseId;
  final int setIndex;
  final int reps;
  final double loadKg;
  final int? rir;
  final bool isWarmup;
  final DateTime completedAt;
  final DateTime? clientUpdatedAt;

  Json toJson() => {
    'clientId': clientId,
    'planExerciseId': planExerciseId,
    'exerciseId': exerciseId,
    'setIndex': setIndex,
    'reps': reps,
    'loadKg': jsonNum(loadKg),
    'rir': rir,
    'isWarmup': isWarmup,
    'completedAt': isoUtc(completedAt),
    if (clientUpdatedAt != null) 'clientUpdatedAt': isoUtc(clientUpdatedAt!),
  };
}

class SetLog {
  const SetLog({
    required this.id,
    required this.clientId,
    required this.workoutId,
    required this.planExerciseId,
    required this.exerciseId,
    required this.setIndex,
    required this.reps,
    required this.loadKg,
    required this.rir,
    required this.isWarmup,
    required this.completedAt,
    required this.clientUpdatedAt,
    required this.deletedAt,
  });

  final String id;
  final String clientId;
  final String workoutId;
  final String? planExerciseId;
  final String exerciseId;
  final int setIndex;
  final int reps;
  final double loadKg;
  final int? rir;
  final bool isWarmup;
  final DateTime completedAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;

  factory SetLog.fromJson(Json j) => SetLog(
    id: j.str('id'),
    clientId: j.str('clientId'),
    workoutId: j.str('workoutId'),
    planExerciseId: j.strOrNull('planExerciseId'),
    exerciseId: j.str('exerciseId'),
    setIndex: j.integer('setIndex'),
    reps: j.integer('reps'),
    loadKg: j.number('loadKg'),
    rir: j.intOrNull('rir'),
    isWarmup: j.boolean('isWarmup'),
    completedAt: j.dateTime('completedAt'),
    clientUpdatedAt: j.dateTime('clientUpdatedAt'),
    deletedAt: j.dateTimeOrNull('deletedAt'),
  );

  Json toJson() => {
    'id': id,
    'clientId': clientId,
    'workoutId': workoutId,
    'planExerciseId': planExerciseId,
    'exerciseId': exerciseId,
    'setIndex': setIndex,
    'reps': reps,
    'loadKg': jsonNum(loadKg),
    'rir': rir,
    'isWarmup': isWarmup,
    'completedAt': isoUtc(completedAt),
    'clientUpdatedAt': isoUtc(clientUpdatedAt),
    'deletedAt': deletedAt == null ? null : isoUtc(deletedAt!),
  };
}

class ExerciseRef {
  const ExerciseRef({
    required this.id,
    required this.slug,
    required this.nameEs,
  });

  final String id;
  final String slug;
  final String nameEs;

  factory ExerciseRef.fromJson(Json j) => ExerciseRef(
    id: j.str('id'),
    slug: j.str('slug'),
    nameEs: j.str('nameEs'),
  );

  Json toJson() => {'id': id, 'slug': slug, 'nameEs': nameEs};
}

class Substitution {
  const Substitution({
    required this.workoutId,
    required this.planExerciseId,
    required this.exercise,
    required this.substitutedFrom,
  });

  final String workoutId;
  final String planExerciseId;
  final ExerciseRef exercise;
  final ExerciseRef substitutedFrom;

  factory Substitution.fromJson(Json j) => Substitution(
    workoutId: j.str('workoutId'),
    planExerciseId: j.str('planExerciseId'),
    exercise: ExerciseRef.fromJson(j.obj('exercise')),
    substitutedFrom: ExerciseRef.fromJson(j.obj('substitutedFrom')),
  );

  Json toJson() => {
    'workoutId': workoutId,
    'planExerciseId': planExerciseId,
    'exercise': exercise.toJson(),
    'substitutedFrom': substitutedFrom.toJson(),
  };
}

class Workout {
  const Workout({
    required this.id,
    required this.clientId,
    required this.planSessionId,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.sets,
    required this.substitutions,
  });

  final String id;
  final String clientId;
  final String planSessionId;
  final WorkoutStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<SetLog> sets;
  final List<Substitution> substitutions;

  factory Workout.fromJson(Json j) => Workout(
    id: j.str('id'),
    clientId: j.str('clientId'),
    planSessionId: j.str('planSessionId'),
    status: j.enumValue('status', WorkoutStatus.values),
    startedAt: j.dateTime('startedAt'),
    completedAt: j.dateTimeOrNull('completedAt'),
    sets: j.objList('sets', SetLog.fromJson),
    substitutions: j.objList('substitutions', Substitution.fromJson),
  );

  Json toJson() => {
    'id': id,
    'clientId': clientId,
    'planSessionId': planSessionId,
    'status': status.wire,
    'startedAt': isoUtc(startedAt),
    'completedAt': completedAt == null ? null : isoUtc(completedAt!),
    'sets': sets.map((s) => s.toJson()).toList(),
    'substitutions': substitutions.map((s) => s.toJson()).toList(),
  };
}

class SubstituteOption {
  const SubstituteOption({
    required this.exerciseId,
    required this.slug,
    required this.nameEs,
    required this.score,
    required this.rationale,
  });

  final String exerciseId;
  final String slug;
  final String nameEs;
  final double score;
  final List<String> rationale;

  factory SubstituteOption.fromJson(Json j) => SubstituteOption(
    exerciseId: j.str('exerciseId'),
    slug: j.str('slug'),
    nameEs: j.str('nameEs'),
    score: j.number('score'),
    rationale: j.strList('rationale'),
  );

  Json toJson() => {
    'exerciseId': exerciseId,
    'slug': slug,
    'nameEs': nameEs,
    'score': jsonNum(score),
    'rationale': rationale,
  };
}

class SubstitutesResponse {
  const SubstitutesResponse({
    required this.exercise,
    required this.substitutes,
  });

  final ExerciseRef exercise;
  final List<SubstituteOption> substitutes;

  factory SubstitutesResponse.fromJson(Json j) => SubstitutesResponse(
    exercise: ExerciseRef.fromJson(j.obj('exercise')),
    substitutes: j.objList('substitutes', SubstituteOption.fromJson),
  );

  Json toJson() => {
    'exercise': exercise.toJson(),
    'substitutes': substitutes.map((s) => s.toJson()).toList(),
  };
}

class TodayPrescription {
  const TodayPrescription({
    required this.action,
    required this.sets,
    required this.repMin,
    required this.repMax,
    required this.targetRir,
    required this.loadKg,
    required this.isDeload,
    required this.rationale,
  });

  final ProgressionAction action;
  final int sets;
  final int repMin;
  final int repMax;
  final int targetRir;

  /// null = sin carga conocida («estimación inicial»).
  final double? loadKg;
  final bool isDeload;
  final List<String> rationale;

  factory TodayPrescription.fromJson(Json j) => TodayPrescription(
    action: j.enumValue('action', ProgressionAction.values),
    sets: j.integer('sets'),
    repMin: j.integer('repMin'),
    repMax: j.integer('repMax'),
    targetRir: j.integer('targetRir'),
    loadKg: j.numOrNull('loadKg'),
    isDeload: j.boolean('isDeload'),
    rationale: j.strList('rationale'),
  );

  Json toJson() => {
    'action': action.wire,
    'sets': sets,
    'repMin': repMin,
    'repMax': repMax,
    'targetRir': targetRir,
    'loadKg': loadKg == null ? null : jsonNum(loadKg!),
    'isDeload': isDeload,
    'rationale': rationale,
  };
}

class TodayExercise {
  const TodayExercise({
    required this.planExerciseId,
    required this.order,
    required this.exercise,
    required this.substitutedFrom,
    required this.cuesEs,
    required this.movementPattern,
    required this.loadType,
    required this.role,
    required this.restSeconds,
    required this.prescription,
    required this.warmupSets,
    required this.loggedSets,
  });

  final String planExerciseId;
  final int order;
  final ExerciseRef exercise;
  final ExerciseRef? substitutedFrom;
  final List<String> cuesEs;
  final MovementPattern movementPattern;
  final LoadType loadType;
  final ExerciseRole role;
  final int restSeconds;
  final TodayPrescription prescription;
  final List<WarmupSet> warmupSets;
  final List<SetLog> loggedSets;

  factory TodayExercise.fromJson(Json j) => TodayExercise(
    planExerciseId: j.str('planExerciseId'),
    order: j.integer('order'),
    exercise: ExerciseRef.fromJson(j.obj('exercise')),
    substitutedFrom: j.objOrNull('substitutedFrom') == null
        ? null
        : ExerciseRef.fromJson(j.obj('substitutedFrom')),
    cuesEs: j.strList('cuesEs'),
    movementPattern: j.enumValue('movementPattern', MovementPattern.values),
    loadType: j.enumValue('loadType', LoadType.values),
    role: j.enumValue('role', ExerciseRole.values),
    restSeconds: j.integer('restSeconds'),
    prescription: TodayPrescription.fromJson(j.obj('prescription')),
    warmupSets: j.objList('warmupSets', WarmupSet.fromJson),
    loggedSets: j.objList('loggedSets', SetLog.fromJson),
  );

  Json toJson() => {
    'planExerciseId': planExerciseId,
    'order': order,
    'exercise': exercise.toJson(),
    'substitutedFrom': substitutedFrom?.toJson(),
    'cuesEs': cuesEs,
    'movementPattern': movementPattern.wire,
    'loadType': loadType.wire,
    'role': role.wire,
    'restSeconds': restSeconds,
    'prescription': prescription.toJson(),
    'warmupSets': warmupSets.map((w) => w.toJson()).toList(),
    'loggedSets': loggedSets.map((s) => s.toJson()).toList(),
  };
}

class TodayWorkoutRef {
  const TodayWorkoutRef({
    required this.id,
    required this.clientId,
    required this.status,
    required this.startedAt,
  });

  final String id;
  final String clientId;
  final WorkoutStatus status;
  final DateTime startedAt;

  factory TodayWorkoutRef.fromJson(Json j) => TodayWorkoutRef(
    id: j.str('id'),
    clientId: j.str('clientId'),
    status: j.enumValue('status', WorkoutStatus.values),
    startedAt: j.dateTime('startedAt'),
  );

  Json toJson() => {
    'id': id,
    'clientId': clientId,
    'status': status.wire,
    'startedAt': isoUtc(startedAt),
  };
}

/// GET /sessions/today.
class TodaySession {
  const TodaySession({
    required this.planVersionId,
    required this.planSessionId,
    required this.order,
    required this.dayIndex,
    required this.kind,
    required this.name,
    required this.targetMinutes,
    required this.estimatedMinutes,
    required this.generalWarmupMinutes,
    required this.rationale,
    required this.today,
    required this.workout,
    required this.exercises,
  });

  final String planVersionId;
  final String planSessionId;
  final int order;
  final int dayIndex;
  final SessionKind kind;
  final String name;
  final int targetMinutes;
  final double estimatedMinutes;
  final double generalWarmupMinutes;
  final List<String> rationale;
  final String today;
  final TodayWorkoutRef? workout;
  final List<TodayExercise> exercises;

  factory TodaySession.fromJson(Json j) => TodaySession(
    planVersionId: j.str('planVersionId'),
    planSessionId: j.str('planSessionId'),
    order: j.integer('order'),
    dayIndex: j.integer('dayIndex'),
    kind: j.enumValue('kind', SessionKind.values),
    name: j.str('name'),
    targetMinutes: j.integer('targetMinutes'),
    estimatedMinutes: j.number('estimatedMinutes'),
    generalWarmupMinutes: j.number('generalWarmupMinutes'),
    rationale: j.strList('rationale'),
    today: j.str('today'),
    workout: j.objOrNull('workout') == null
        ? null
        : TodayWorkoutRef.fromJson(j.obj('workout')),
    exercises: j.objList('exercises', TodayExercise.fromJson),
  );

  Json toJson() => {
    'planVersionId': planVersionId,
    'planSessionId': planSessionId,
    'order': order,
    'dayIndex': dayIndex,
    'kind': kind.wire,
    'name': name,
    'targetMinutes': targetMinutes,
    'estimatedMinutes': jsonNum(estimatedMinutes),
    'generalWarmupMinutes': jsonNum(generalWarmupMinutes),
    'rationale': rationale,
    'today': today,
    'workout': workout?.toJson(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}
