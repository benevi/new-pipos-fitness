// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TrainingPlan _$TrainingPlanFromJson(Map<String, dynamic> json) {
  return _TrainingPlan.fromJson(json);
}

/// @nodoc
mixin _$TrainingPlan {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get currentVersionId => throw _privateConstructorUsedError;
  TrainingPlanVersion get version => throw _privateConstructorUsedError;

  /// Serializes this TrainingPlan to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrainingPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrainingPlanCopyWith<TrainingPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrainingPlanCopyWith<$Res> {
  factory $TrainingPlanCopyWith(
          TrainingPlan value, $Res Function(TrainingPlan) then) =
      _$TrainingPlanCopyWithImpl<$Res, TrainingPlan>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String? currentVersionId,
      TrainingPlanVersion version});

  $TrainingPlanVersionCopyWith<$Res> get version;
}

/// @nodoc
class _$TrainingPlanCopyWithImpl<$Res, $Val extends TrainingPlan>
    implements $TrainingPlanCopyWith<$Res> {
  _$TrainingPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrainingPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? currentVersionId = freezed,
    Object? version = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      currentVersionId: freezed == currentVersionId
          ? _value.currentVersionId
          : currentVersionId // ignore: cast_nullable_to_non_nullable
              as String?,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as TrainingPlanVersion,
    ) as $Val);
  }

  /// Create a copy of TrainingPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TrainingPlanVersionCopyWith<$Res> get version {
    return $TrainingPlanVersionCopyWith<$Res>(_value.version, (value) {
      return _then(_value.copyWith(version: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TrainingPlanImplCopyWith<$Res>
    implements $TrainingPlanCopyWith<$Res> {
  factory _$$TrainingPlanImplCopyWith(
          _$TrainingPlanImpl value, $Res Function(_$TrainingPlanImpl) then) =
      __$$TrainingPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String? currentVersionId,
      TrainingPlanVersion version});

  @override
  $TrainingPlanVersionCopyWith<$Res> get version;
}

/// @nodoc
class __$$TrainingPlanImplCopyWithImpl<$Res>
    extends _$TrainingPlanCopyWithImpl<$Res, _$TrainingPlanImpl>
    implements _$$TrainingPlanImplCopyWith<$Res> {
  __$$TrainingPlanImplCopyWithImpl(
      _$TrainingPlanImpl _value, $Res Function(_$TrainingPlanImpl) _then)
      : super(_value, _then);

  /// Create a copy of TrainingPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? currentVersionId = freezed,
    Object? version = null,
  }) {
    return _then(_$TrainingPlanImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      currentVersionId: freezed == currentVersionId
          ? _value.currentVersionId
          : currentVersionId // ignore: cast_nullable_to_non_nullable
              as String?,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as TrainingPlanVersion,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrainingPlanImpl implements _TrainingPlan {
  const _$TrainingPlanImpl(
      {required this.id,
      required this.userId,
      required this.currentVersionId,
      required this.version});

  factory _$TrainingPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrainingPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String? currentVersionId;
  @override
  final TrainingPlanVersion version;

  @override
  String toString() {
    return 'TrainingPlan(id: $id, userId: $userId, currentVersionId: $currentVersionId, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrainingPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.currentVersionId, currentVersionId) ||
                other.currentVersionId == currentVersionId) &&
            (identical(other.version, version) || other.version == version));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, userId, currentVersionId, version);

  /// Create a copy of TrainingPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrainingPlanImplCopyWith<_$TrainingPlanImpl> get copyWith =>
      __$$TrainingPlanImplCopyWithImpl<_$TrainingPlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrainingPlanImplToJson(
      this,
    );
  }
}

abstract class _TrainingPlan implements TrainingPlan {
  const factory _TrainingPlan(
      {required final String id,
      required final String userId,
      required final String? currentVersionId,
      required final TrainingPlanVersion version}) = _$TrainingPlanImpl;

  factory _TrainingPlan.fromJson(Map<String, dynamic> json) =
      _$TrainingPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String? get currentVersionId;
  @override
  TrainingPlanVersion get version;

  /// Create a copy of TrainingPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrainingPlanImplCopyWith<_$TrainingPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TrainingPlanVersion _$TrainingPlanVersionFromJson(Map<String, dynamic> json) {
  return _TrainingPlanVersion.fromJson(json);
}

/// @nodoc
mixin _$TrainingPlanVersion {
  String get id => throw _privateConstructorUsedError;
  String get planId => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get engineVersion => throw _privateConstructorUsedError;
  double get objectiveScore => throw _privateConstructorUsedError;
  List<TrainingSession> get sessions => throw _privateConstructorUsedError;

  /// Serializes this TrainingPlanVersion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrainingPlanVersion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrainingPlanVersionCopyWith<TrainingPlanVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrainingPlanVersionCopyWith<$Res> {
  factory $TrainingPlanVersionCopyWith(
          TrainingPlanVersion value, $Res Function(TrainingPlanVersion) then) =
      _$TrainingPlanVersionCopyWithImpl<$Res, TrainingPlanVersion>;
  @useResult
  $Res call(
      {String id,
      String planId,
      int version,
      String createdAt,
      String engineVersion,
      double objectiveScore,
      List<TrainingSession> sessions});
}

/// @nodoc
class _$TrainingPlanVersionCopyWithImpl<$Res, $Val extends TrainingPlanVersion>
    implements $TrainingPlanVersionCopyWith<$Res> {
  _$TrainingPlanVersionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrainingPlanVersion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? version = null,
    Object? createdAt = null,
    Object? engineVersion = null,
    Object? objectiveScore = null,
    Object? sessions = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      planId: null == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      engineVersion: null == engineVersion
          ? _value.engineVersion
          : engineVersion // ignore: cast_nullable_to_non_nullable
              as String,
      objectiveScore: null == objectiveScore
          ? _value.objectiveScore
          : objectiveScore // ignore: cast_nullable_to_non_nullable
              as double,
      sessions: null == sessions
          ? _value.sessions
          : sessions // ignore: cast_nullable_to_non_nullable
              as List<TrainingSession>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrainingPlanVersionImplCopyWith<$Res>
    implements $TrainingPlanVersionCopyWith<$Res> {
  factory _$$TrainingPlanVersionImplCopyWith(_$TrainingPlanVersionImpl value,
          $Res Function(_$TrainingPlanVersionImpl) then) =
      __$$TrainingPlanVersionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String planId,
      int version,
      String createdAt,
      String engineVersion,
      double objectiveScore,
      List<TrainingSession> sessions});
}

/// @nodoc
class __$$TrainingPlanVersionImplCopyWithImpl<$Res>
    extends _$TrainingPlanVersionCopyWithImpl<$Res, _$TrainingPlanVersionImpl>
    implements _$$TrainingPlanVersionImplCopyWith<$Res> {
  __$$TrainingPlanVersionImplCopyWithImpl(_$TrainingPlanVersionImpl _value,
      $Res Function(_$TrainingPlanVersionImpl) _then)
      : super(_value, _then);

  /// Create a copy of TrainingPlanVersion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? version = null,
    Object? createdAt = null,
    Object? engineVersion = null,
    Object? objectiveScore = null,
    Object? sessions = null,
  }) {
    return _then(_$TrainingPlanVersionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      planId: null == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      engineVersion: null == engineVersion
          ? _value.engineVersion
          : engineVersion // ignore: cast_nullable_to_non_nullable
              as String,
      objectiveScore: null == objectiveScore
          ? _value.objectiveScore
          : objectiveScore // ignore: cast_nullable_to_non_nullable
              as double,
      sessions: null == sessions
          ? _value._sessions
          : sessions // ignore: cast_nullable_to_non_nullable
              as List<TrainingSession>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrainingPlanVersionImpl implements _TrainingPlanVersion {
  const _$TrainingPlanVersionImpl(
      {required this.id,
      required this.planId,
      required this.version,
      required this.createdAt,
      required this.engineVersion,
      required this.objectiveScore,
      required final List<TrainingSession> sessions})
      : _sessions = sessions;

  factory _$TrainingPlanVersionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrainingPlanVersionImplFromJson(json);

  @override
  final String id;
  @override
  final String planId;
  @override
  final int version;
  @override
  final String createdAt;
  @override
  final String engineVersion;
  @override
  final double objectiveScore;
  final List<TrainingSession> _sessions;
  @override
  List<TrainingSession> get sessions {
    if (_sessions is EqualUnmodifiableListView) return _sessions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sessions);
  }

  @override
  String toString() {
    return 'TrainingPlanVersion(id: $id, planId: $planId, version: $version, createdAt: $createdAt, engineVersion: $engineVersion, objectiveScore: $objectiveScore, sessions: $sessions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrainingPlanVersionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.engineVersion, engineVersion) ||
                other.engineVersion == engineVersion) &&
            (identical(other.objectiveScore, objectiveScore) ||
                other.objectiveScore == objectiveScore) &&
            const DeepCollectionEquality().equals(other._sessions, _sessions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      planId,
      version,
      createdAt,
      engineVersion,
      objectiveScore,
      const DeepCollectionEquality().hash(_sessions));

  /// Create a copy of TrainingPlanVersion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrainingPlanVersionImplCopyWith<_$TrainingPlanVersionImpl> get copyWith =>
      __$$TrainingPlanVersionImplCopyWithImpl<_$TrainingPlanVersionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrainingPlanVersionImplToJson(
      this,
    );
  }
}

abstract class _TrainingPlanVersion implements TrainingPlanVersion {
  const factory _TrainingPlanVersion(
          {required final String id,
          required final String planId,
          required final int version,
          required final String createdAt,
          required final String engineVersion,
          required final double objectiveScore,
          required final List<TrainingSession> sessions}) =
      _$TrainingPlanVersionImpl;

  factory _TrainingPlanVersion.fromJson(Map<String, dynamic> json) =
      _$TrainingPlanVersionImpl.fromJson;

  @override
  String get id;
  @override
  String get planId;
  @override
  int get version;
  @override
  String get createdAt;
  @override
  String get engineVersion;
  @override
  double get objectiveScore;
  @override
  List<TrainingSession> get sessions;

  /// Create a copy of TrainingPlanVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrainingPlanVersionImplCopyWith<_$TrainingPlanVersionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TrainingSession _$TrainingSessionFromJson(Map<String, dynamic> json) {
  return _TrainingSession.fromJson(json);
}

/// @nodoc
mixin _$TrainingSession {
  String get id => throw _privateConstructorUsedError;
  String get planVersionId => throw _privateConstructorUsedError;
  int get sessionIndex => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get targetDurationMinutes => throw _privateConstructorUsedError;
  List<TrainingSessionExercise> get exercises =>
      throw _privateConstructorUsedError;

  /// Serializes this TrainingSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrainingSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrainingSessionCopyWith<TrainingSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrainingSessionCopyWith<$Res> {
  factory $TrainingSessionCopyWith(
          TrainingSession value, $Res Function(TrainingSession) then) =
      _$TrainingSessionCopyWithImpl<$Res, TrainingSession>;
  @useResult
  $Res call(
      {String id,
      String planVersionId,
      int sessionIndex,
      String name,
      int targetDurationMinutes,
      List<TrainingSessionExercise> exercises});
}

/// @nodoc
class _$TrainingSessionCopyWithImpl<$Res, $Val extends TrainingSession>
    implements $TrainingSessionCopyWith<$Res> {
  _$TrainingSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrainingSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planVersionId = null,
    Object? sessionIndex = null,
    Object? name = null,
    Object? targetDurationMinutes = null,
    Object? exercises = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      planVersionId: null == planVersionId
          ? _value.planVersionId
          : planVersionId // ignore: cast_nullable_to_non_nullable
              as String,
      sessionIndex: null == sessionIndex
          ? _value.sessionIndex
          : sessionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      targetDurationMinutes: null == targetDurationMinutes
          ? _value.targetDurationMinutes
          : targetDurationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      exercises: null == exercises
          ? _value.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<TrainingSessionExercise>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrainingSessionImplCopyWith<$Res>
    implements $TrainingSessionCopyWith<$Res> {
  factory _$$TrainingSessionImplCopyWith(_$TrainingSessionImpl value,
          $Res Function(_$TrainingSessionImpl) then) =
      __$$TrainingSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String planVersionId,
      int sessionIndex,
      String name,
      int targetDurationMinutes,
      List<TrainingSessionExercise> exercises});
}

/// @nodoc
class __$$TrainingSessionImplCopyWithImpl<$Res>
    extends _$TrainingSessionCopyWithImpl<$Res, _$TrainingSessionImpl>
    implements _$$TrainingSessionImplCopyWith<$Res> {
  __$$TrainingSessionImplCopyWithImpl(
      _$TrainingSessionImpl _value, $Res Function(_$TrainingSessionImpl) _then)
      : super(_value, _then);

  /// Create a copy of TrainingSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planVersionId = null,
    Object? sessionIndex = null,
    Object? name = null,
    Object? targetDurationMinutes = null,
    Object? exercises = null,
  }) {
    return _then(_$TrainingSessionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      planVersionId: null == planVersionId
          ? _value.planVersionId
          : planVersionId // ignore: cast_nullable_to_non_nullable
              as String,
      sessionIndex: null == sessionIndex
          ? _value.sessionIndex
          : sessionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      targetDurationMinutes: null == targetDurationMinutes
          ? _value.targetDurationMinutes
          : targetDurationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      exercises: null == exercises
          ? _value._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<TrainingSessionExercise>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrainingSessionImpl implements _TrainingSession {
  const _$TrainingSessionImpl(
      {required this.id,
      required this.planVersionId,
      required this.sessionIndex,
      required this.name,
      required this.targetDurationMinutes,
      required final List<TrainingSessionExercise> exercises})
      : _exercises = exercises;

  factory _$TrainingSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrainingSessionImplFromJson(json);

  @override
  final String id;
  @override
  final String planVersionId;
  @override
  final int sessionIndex;
  @override
  final String name;
  @override
  final int targetDurationMinutes;
  final List<TrainingSessionExercise> _exercises;
  @override
  List<TrainingSessionExercise> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  String toString() {
    return 'TrainingSession(id: $id, planVersionId: $planVersionId, sessionIndex: $sessionIndex, name: $name, targetDurationMinutes: $targetDurationMinutes, exercises: $exercises)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrainingSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planVersionId, planVersionId) ||
                other.planVersionId == planVersionId) &&
            (identical(other.sessionIndex, sessionIndex) ||
                other.sessionIndex == sessionIndex) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.targetDurationMinutes, targetDurationMinutes) ||
                other.targetDurationMinutes == targetDurationMinutes) &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      planVersionId,
      sessionIndex,
      name,
      targetDurationMinutes,
      const DeepCollectionEquality().hash(_exercises));

  /// Create a copy of TrainingSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrainingSessionImplCopyWith<_$TrainingSessionImpl> get copyWith =>
      __$$TrainingSessionImplCopyWithImpl<_$TrainingSessionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrainingSessionImplToJson(
      this,
    );
  }
}

abstract class _TrainingSession implements TrainingSession {
  const factory _TrainingSession(
          {required final String id,
          required final String planVersionId,
          required final int sessionIndex,
          required final String name,
          required final int targetDurationMinutes,
          required final List<TrainingSessionExercise> exercises}) =
      _$TrainingSessionImpl;

  factory _TrainingSession.fromJson(Map<String, dynamic> json) =
      _$TrainingSessionImpl.fromJson;

  @override
  String get id;
  @override
  String get planVersionId;
  @override
  int get sessionIndex;
  @override
  String get name;
  @override
  int get targetDurationMinutes;
  @override
  List<TrainingSessionExercise> get exercises;

  /// Create a copy of TrainingSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrainingSessionImplCopyWith<_$TrainingSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TrainingSessionExercise _$TrainingSessionExerciseFromJson(
    Map<String, dynamic> json) {
  return _TrainingSessionExercise.fromJson(json);
}

/// @nodoc
mixin _$TrainingSessionExercise {
  String get id => throw _privateConstructorUsedError;
  String get sessionId => throw _privateConstructorUsedError;
  String get exerciseId => throw _privateConstructorUsedError;
  int get sets => throw _privateConstructorUsedError;
  int get repRangeMin => throw _privateConstructorUsedError;
  int get repRangeMax => throw _privateConstructorUsedError;
  int get restSeconds => throw _privateConstructorUsedError;
  int get rirTarget => throw _privateConstructorUsedError;

  /// Serializes this TrainingSessionExercise to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrainingSessionExercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrainingSessionExerciseCopyWith<TrainingSessionExercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrainingSessionExerciseCopyWith<$Res> {
  factory $TrainingSessionExerciseCopyWith(TrainingSessionExercise value,
          $Res Function(TrainingSessionExercise) then) =
      _$TrainingSessionExerciseCopyWithImpl<$Res, TrainingSessionExercise>;
  @useResult
  $Res call(
      {String id,
      String sessionId,
      String exerciseId,
      int sets,
      int repRangeMin,
      int repRangeMax,
      int restSeconds,
      int rirTarget});
}

/// @nodoc
class _$TrainingSessionExerciseCopyWithImpl<$Res,
        $Val extends TrainingSessionExercise>
    implements $TrainingSessionExerciseCopyWith<$Res> {
  _$TrainingSessionExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrainingSessionExercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? exerciseId = null,
    Object? sets = null,
    Object? repRangeMin = null,
    Object? repRangeMax = null,
    Object? restSeconds = null,
    Object? rirTarget = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int,
      repRangeMin: null == repRangeMin
          ? _value.repRangeMin
          : repRangeMin // ignore: cast_nullable_to_non_nullable
              as int,
      repRangeMax: null == repRangeMax
          ? _value.repRangeMax
          : repRangeMax // ignore: cast_nullable_to_non_nullable
              as int,
      restSeconds: null == restSeconds
          ? _value.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      rirTarget: null == rirTarget
          ? _value.rirTarget
          : rirTarget // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrainingSessionExerciseImplCopyWith<$Res>
    implements $TrainingSessionExerciseCopyWith<$Res> {
  factory _$$TrainingSessionExerciseImplCopyWith(
          _$TrainingSessionExerciseImpl value,
          $Res Function(_$TrainingSessionExerciseImpl) then) =
      __$$TrainingSessionExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String sessionId,
      String exerciseId,
      int sets,
      int repRangeMin,
      int repRangeMax,
      int restSeconds,
      int rirTarget});
}

/// @nodoc
class __$$TrainingSessionExerciseImplCopyWithImpl<$Res>
    extends _$TrainingSessionExerciseCopyWithImpl<$Res,
        _$TrainingSessionExerciseImpl>
    implements _$$TrainingSessionExerciseImplCopyWith<$Res> {
  __$$TrainingSessionExerciseImplCopyWithImpl(
      _$TrainingSessionExerciseImpl _value,
      $Res Function(_$TrainingSessionExerciseImpl) _then)
      : super(_value, _then);

  /// Create a copy of TrainingSessionExercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? exerciseId = null,
    Object? sets = null,
    Object? repRangeMin = null,
    Object? repRangeMax = null,
    Object? restSeconds = null,
    Object? rirTarget = null,
  }) {
    return _then(_$TrainingSessionExerciseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int,
      repRangeMin: null == repRangeMin
          ? _value.repRangeMin
          : repRangeMin // ignore: cast_nullable_to_non_nullable
              as int,
      repRangeMax: null == repRangeMax
          ? _value.repRangeMax
          : repRangeMax // ignore: cast_nullable_to_non_nullable
              as int,
      restSeconds: null == restSeconds
          ? _value.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      rirTarget: null == rirTarget
          ? _value.rirTarget
          : rirTarget // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrainingSessionExerciseImpl implements _TrainingSessionExercise {
  const _$TrainingSessionExerciseImpl(
      {required this.id,
      required this.sessionId,
      required this.exerciseId,
      required this.sets,
      required this.repRangeMin,
      required this.repRangeMax,
      required this.restSeconds,
      required this.rirTarget});

  factory _$TrainingSessionExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrainingSessionExerciseImplFromJson(json);

  @override
  final String id;
  @override
  final String sessionId;
  @override
  final String exerciseId;
  @override
  final int sets;
  @override
  final int repRangeMin;
  @override
  final int repRangeMax;
  @override
  final int restSeconds;
  @override
  final int rirTarget;

  @override
  String toString() {
    return 'TrainingSessionExercise(id: $id, sessionId: $sessionId, exerciseId: $exerciseId, sets: $sets, repRangeMin: $repRangeMin, repRangeMax: $repRangeMax, restSeconds: $restSeconds, rirTarget: $rirTarget)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrainingSessionExerciseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.sets, sets) || other.sets == sets) &&
            (identical(other.repRangeMin, repRangeMin) ||
                other.repRangeMin == repRangeMin) &&
            (identical(other.repRangeMax, repRangeMax) ||
                other.repRangeMax == repRangeMax) &&
            (identical(other.restSeconds, restSeconds) ||
                other.restSeconds == restSeconds) &&
            (identical(other.rirTarget, rirTarget) ||
                other.rirTarget == rirTarget));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, sessionId, exerciseId, sets,
      repRangeMin, repRangeMax, restSeconds, rirTarget);

  /// Create a copy of TrainingSessionExercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrainingSessionExerciseImplCopyWith<_$TrainingSessionExerciseImpl>
      get copyWith => __$$TrainingSessionExerciseImplCopyWithImpl<
          _$TrainingSessionExerciseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrainingSessionExerciseImplToJson(
      this,
    );
  }
}

abstract class _TrainingSessionExercise implements TrainingSessionExercise {
  const factory _TrainingSessionExercise(
      {required final String id,
      required final String sessionId,
      required final String exerciseId,
      required final int sets,
      required final int repRangeMin,
      required final int repRangeMax,
      required final int restSeconds,
      required final int rirTarget}) = _$TrainingSessionExerciseImpl;

  factory _TrainingSessionExercise.fromJson(Map<String, dynamic> json) =
      _$TrainingSessionExerciseImpl.fromJson;

  @override
  String get id;
  @override
  String get sessionId;
  @override
  String get exerciseId;
  @override
  int get sets;
  @override
  int get repRangeMin;
  @override
  int get repRangeMax;
  @override
  int get restSeconds;
  @override
  int get rirTarget;

  /// Create a copy of TrainingSessionExercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrainingSessionExerciseImplCopyWith<_$TrainingSessionExerciseImpl>
      get copyWith => throw _privateConstructorUsedError;
}
