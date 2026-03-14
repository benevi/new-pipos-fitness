// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProgressMetrics _$ProgressMetricsFromJson(Map<String, dynamic> json) {
  return _ProgressMetrics.fromJson(json);
}

/// @nodoc
mixin _$ProgressMetrics {
  List<ExerciseProgressItem> get exercises =>
      throw _privateConstructorUsedError;
  double? get adherenceScore => throw _privateConstructorUsedError;
  bool get fatigueDetected => throw _privateConstructorUsedError;

  /// Serializes this ProgressMetrics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProgressMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProgressMetricsCopyWith<ProgressMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProgressMetricsCopyWith<$Res> {
  factory $ProgressMetricsCopyWith(
          ProgressMetrics value, $Res Function(ProgressMetrics) then) =
      _$ProgressMetricsCopyWithImpl<$Res, ProgressMetrics>;
  @useResult
  $Res call(
      {List<ExerciseProgressItem> exercises,
      double? adherenceScore,
      bool fatigueDetected});
}

/// @nodoc
class _$ProgressMetricsCopyWithImpl<$Res, $Val extends ProgressMetrics>
    implements $ProgressMetricsCopyWith<$Res> {
  _$ProgressMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProgressMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exercises = null,
    Object? adherenceScore = freezed,
    Object? fatigueDetected = null,
  }) {
    return _then(_value.copyWith(
      exercises: null == exercises
          ? _value.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<ExerciseProgressItem>,
      adherenceScore: freezed == adherenceScore
          ? _value.adherenceScore
          : adherenceScore // ignore: cast_nullable_to_non_nullable
              as double?,
      fatigueDetected: null == fatigueDetected
          ? _value.fatigueDetected
          : fatigueDetected // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProgressMetricsImplCopyWith<$Res>
    implements $ProgressMetricsCopyWith<$Res> {
  factory _$$ProgressMetricsImplCopyWith(_$ProgressMetricsImpl value,
          $Res Function(_$ProgressMetricsImpl) then) =
      __$$ProgressMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ExerciseProgressItem> exercises,
      double? adherenceScore,
      bool fatigueDetected});
}

/// @nodoc
class __$$ProgressMetricsImplCopyWithImpl<$Res>
    extends _$ProgressMetricsCopyWithImpl<$Res, _$ProgressMetricsImpl>
    implements _$$ProgressMetricsImplCopyWith<$Res> {
  __$$ProgressMetricsImplCopyWithImpl(
      _$ProgressMetricsImpl _value, $Res Function(_$ProgressMetricsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProgressMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exercises = null,
    Object? adherenceScore = freezed,
    Object? fatigueDetected = null,
  }) {
    return _then(_$ProgressMetricsImpl(
      exercises: null == exercises
          ? _value._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<ExerciseProgressItem>,
      adherenceScore: freezed == adherenceScore
          ? _value.adherenceScore
          : adherenceScore // ignore: cast_nullable_to_non_nullable
              as double?,
      fatigueDetected: null == fatigueDetected
          ? _value.fatigueDetected
          : fatigueDetected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProgressMetricsImpl implements _ProgressMetrics {
  const _$ProgressMetricsImpl(
      {required final List<ExerciseProgressItem> exercises,
      required this.adherenceScore,
      required this.fatigueDetected})
      : _exercises = exercises;

  factory _$ProgressMetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProgressMetricsImplFromJson(json);

  final List<ExerciseProgressItem> _exercises;
  @override
  List<ExerciseProgressItem> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  final double? adherenceScore;
  @override
  final bool fatigueDetected;

  @override
  String toString() {
    return 'ProgressMetrics(exercises: $exercises, adherenceScore: $adherenceScore, fatigueDetected: $fatigueDetected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProgressMetricsImpl &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises) &&
            (identical(other.adherenceScore, adherenceScore) ||
                other.adherenceScore == adherenceScore) &&
            (identical(other.fatigueDetected, fatigueDetected) ||
                other.fatigueDetected == fatigueDetected));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_exercises),
      adherenceScore,
      fatigueDetected);

  /// Create a copy of ProgressMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProgressMetricsImplCopyWith<_$ProgressMetricsImpl> get copyWith =>
      __$$ProgressMetricsImplCopyWithImpl<_$ProgressMetricsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProgressMetricsImplToJson(
      this,
    );
  }
}

abstract class _ProgressMetrics implements ProgressMetrics {
  const factory _ProgressMetrics(
      {required final List<ExerciseProgressItem> exercises,
      required final double? adherenceScore,
      required final bool fatigueDetected}) = _$ProgressMetricsImpl;

  factory _ProgressMetrics.fromJson(Map<String, dynamic> json) =
      _$ProgressMetricsImpl.fromJson;

  @override
  List<ExerciseProgressItem> get exercises;
  @override
  double? get adherenceScore;
  @override
  bool get fatigueDetected;

  /// Create a copy of ProgressMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProgressMetricsImplCopyWith<_$ProgressMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExerciseProgressItem _$ExerciseProgressItemFromJson(Map<String, dynamic> json) {
  return _ExerciseProgressItem.fromJson(json);
}

/// @nodoc
mixin _$ExerciseProgressItem {
  String get exerciseId => throw _privateConstructorUsedError;
  double? get estimated1RM => throw _privateConstructorUsedError;
  double? get volumeLastWeek => throw _privateConstructorUsedError;
  String? get volumeTrend => throw _privateConstructorUsedError;
  double? get fatigueScore => throw _privateConstructorUsedError;
  String? get lastUpdated => throw _privateConstructorUsedError;

  /// Serializes this ExerciseProgressItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExerciseProgressItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseProgressItemCopyWith<ExerciseProgressItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseProgressItemCopyWith<$Res> {
  factory $ExerciseProgressItemCopyWith(ExerciseProgressItem value,
          $Res Function(ExerciseProgressItem) then) =
      _$ExerciseProgressItemCopyWithImpl<$Res, ExerciseProgressItem>;
  @useResult
  $Res call(
      {String exerciseId,
      double? estimated1RM,
      double? volumeLastWeek,
      String? volumeTrend,
      double? fatigueScore,
      String? lastUpdated});
}

/// @nodoc
class _$ExerciseProgressItemCopyWithImpl<$Res,
        $Val extends ExerciseProgressItem>
    implements $ExerciseProgressItemCopyWith<$Res> {
  _$ExerciseProgressItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExerciseProgressItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? estimated1RM = freezed,
    Object? volumeLastWeek = freezed,
    Object? volumeTrend = freezed,
    Object? fatigueScore = freezed,
    Object? lastUpdated = freezed,
  }) {
    return _then(_value.copyWith(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      estimated1RM: freezed == estimated1RM
          ? _value.estimated1RM
          : estimated1RM // ignore: cast_nullable_to_non_nullable
              as double?,
      volumeLastWeek: freezed == volumeLastWeek
          ? _value.volumeLastWeek
          : volumeLastWeek // ignore: cast_nullable_to_non_nullable
              as double?,
      volumeTrend: freezed == volumeTrend
          ? _value.volumeTrend
          : volumeTrend // ignore: cast_nullable_to_non_nullable
              as String?,
      fatigueScore: freezed == fatigueScore
          ? _value.fatigueScore
          : fatigueScore // ignore: cast_nullable_to_non_nullable
              as double?,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseProgressItemImplCopyWith<$Res>
    implements $ExerciseProgressItemCopyWith<$Res> {
  factory _$$ExerciseProgressItemImplCopyWith(_$ExerciseProgressItemImpl value,
          $Res Function(_$ExerciseProgressItemImpl) then) =
      __$$ExerciseProgressItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String exerciseId,
      double? estimated1RM,
      double? volumeLastWeek,
      String? volumeTrend,
      double? fatigueScore,
      String? lastUpdated});
}

/// @nodoc
class __$$ExerciseProgressItemImplCopyWithImpl<$Res>
    extends _$ExerciseProgressItemCopyWithImpl<$Res, _$ExerciseProgressItemImpl>
    implements _$$ExerciseProgressItemImplCopyWith<$Res> {
  __$$ExerciseProgressItemImplCopyWithImpl(_$ExerciseProgressItemImpl _value,
      $Res Function(_$ExerciseProgressItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExerciseProgressItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? estimated1RM = freezed,
    Object? volumeLastWeek = freezed,
    Object? volumeTrend = freezed,
    Object? fatigueScore = freezed,
    Object? lastUpdated = freezed,
  }) {
    return _then(_$ExerciseProgressItemImpl(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      estimated1RM: freezed == estimated1RM
          ? _value.estimated1RM
          : estimated1RM // ignore: cast_nullable_to_non_nullable
              as double?,
      volumeLastWeek: freezed == volumeLastWeek
          ? _value.volumeLastWeek
          : volumeLastWeek // ignore: cast_nullable_to_non_nullable
              as double?,
      volumeTrend: freezed == volumeTrend
          ? _value.volumeTrend
          : volumeTrend // ignore: cast_nullable_to_non_nullable
              as String?,
      fatigueScore: freezed == fatigueScore
          ? _value.fatigueScore
          : fatigueScore // ignore: cast_nullable_to_non_nullable
              as double?,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseProgressItemImpl implements _ExerciseProgressItem {
  const _$ExerciseProgressItemImpl(
      {required this.exerciseId,
      this.estimated1RM,
      this.volumeLastWeek,
      this.volumeTrend,
      this.fatigueScore,
      this.lastUpdated});

  factory _$ExerciseProgressItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseProgressItemImplFromJson(json);

  @override
  final String exerciseId;
  @override
  final double? estimated1RM;
  @override
  final double? volumeLastWeek;
  @override
  final String? volumeTrend;
  @override
  final double? fatigueScore;
  @override
  final String? lastUpdated;

  @override
  String toString() {
    return 'ExerciseProgressItem(exerciseId: $exerciseId, estimated1RM: $estimated1RM, volumeLastWeek: $volumeLastWeek, volumeTrend: $volumeTrend, fatigueScore: $fatigueScore, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseProgressItemImpl &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.estimated1RM, estimated1RM) ||
                other.estimated1RM == estimated1RM) &&
            (identical(other.volumeLastWeek, volumeLastWeek) ||
                other.volumeLastWeek == volumeLastWeek) &&
            (identical(other.volumeTrend, volumeTrend) ||
                other.volumeTrend == volumeTrend) &&
            (identical(other.fatigueScore, fatigueScore) ||
                other.fatigueScore == fatigueScore) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, exerciseId, estimated1RM,
      volumeLastWeek, volumeTrend, fatigueScore, lastUpdated);

  /// Create a copy of ExerciseProgressItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseProgressItemImplCopyWith<_$ExerciseProgressItemImpl>
      get copyWith =>
          __$$ExerciseProgressItemImplCopyWithImpl<_$ExerciseProgressItemImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseProgressItemImplToJson(
      this,
    );
  }
}

abstract class _ExerciseProgressItem implements ExerciseProgressItem {
  const factory _ExerciseProgressItem(
      {required final String exerciseId,
      final double? estimated1RM,
      final double? volumeLastWeek,
      final String? volumeTrend,
      final double? fatigueScore,
      final String? lastUpdated}) = _$ExerciseProgressItemImpl;

  factory _ExerciseProgressItem.fromJson(Map<String, dynamic> json) =
      _$ExerciseProgressItemImpl.fromJson;

  @override
  String get exerciseId;
  @override
  double? get estimated1RM;
  @override
  double? get volumeLastWeek;
  @override
  String? get volumeTrend;
  @override
  double? get fatigueScore;
  @override
  String? get lastUpdated;

  /// Create a copy of ExerciseProgressItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseProgressItemImplCopyWith<_$ExerciseProgressItemImpl>
      get copyWith => throw _privateConstructorUsedError;
}
