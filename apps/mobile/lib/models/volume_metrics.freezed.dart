// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'volume_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VolumeMetrics _$VolumeMetricsFromJson(Map<String, dynamic> json) {
  return _VolumeMetrics.fromJson(json);
}

/// @nodoc
mixin _$VolumeMetrics {
  List<VolumeByExercise> get byExercise => throw _privateConstructorUsedError;
  List<VolumeByMuscle> get byMuscle => throw _privateConstructorUsedError;
  String? get weekStart => throw _privateConstructorUsedError;
  String? get weekEnd => throw _privateConstructorUsedError;

  /// Serializes this VolumeMetrics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VolumeMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VolumeMetricsCopyWith<VolumeMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VolumeMetricsCopyWith<$Res> {
  factory $VolumeMetricsCopyWith(
          VolumeMetrics value, $Res Function(VolumeMetrics) then) =
      _$VolumeMetricsCopyWithImpl<$Res, VolumeMetrics>;
  @useResult
  $Res call(
      {List<VolumeByExercise> byExercise,
      List<VolumeByMuscle> byMuscle,
      String? weekStart,
      String? weekEnd});
}

/// @nodoc
class _$VolumeMetricsCopyWithImpl<$Res, $Val extends VolumeMetrics>
    implements $VolumeMetricsCopyWith<$Res> {
  _$VolumeMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VolumeMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? byExercise = null,
    Object? byMuscle = null,
    Object? weekStart = freezed,
    Object? weekEnd = freezed,
  }) {
    return _then(_value.copyWith(
      byExercise: null == byExercise
          ? _value.byExercise
          : byExercise // ignore: cast_nullable_to_non_nullable
              as List<VolumeByExercise>,
      byMuscle: null == byMuscle
          ? _value.byMuscle
          : byMuscle // ignore: cast_nullable_to_non_nullable
              as List<VolumeByMuscle>,
      weekStart: freezed == weekStart
          ? _value.weekStart
          : weekStart // ignore: cast_nullable_to_non_nullable
              as String?,
      weekEnd: freezed == weekEnd
          ? _value.weekEnd
          : weekEnd // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VolumeMetricsImplCopyWith<$Res>
    implements $VolumeMetricsCopyWith<$Res> {
  factory _$$VolumeMetricsImplCopyWith(
          _$VolumeMetricsImpl value, $Res Function(_$VolumeMetricsImpl) then) =
      __$$VolumeMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<VolumeByExercise> byExercise,
      List<VolumeByMuscle> byMuscle,
      String? weekStart,
      String? weekEnd});
}

/// @nodoc
class __$$VolumeMetricsImplCopyWithImpl<$Res>
    extends _$VolumeMetricsCopyWithImpl<$Res, _$VolumeMetricsImpl>
    implements _$$VolumeMetricsImplCopyWith<$Res> {
  __$$VolumeMetricsImplCopyWithImpl(
      _$VolumeMetricsImpl _value, $Res Function(_$VolumeMetricsImpl) _then)
      : super(_value, _then);

  /// Create a copy of VolumeMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? byExercise = null,
    Object? byMuscle = null,
    Object? weekStart = freezed,
    Object? weekEnd = freezed,
  }) {
    return _then(_$VolumeMetricsImpl(
      byExercise: null == byExercise
          ? _value._byExercise
          : byExercise // ignore: cast_nullable_to_non_nullable
              as List<VolumeByExercise>,
      byMuscle: null == byMuscle
          ? _value._byMuscle
          : byMuscle // ignore: cast_nullable_to_non_nullable
              as List<VolumeByMuscle>,
      weekStart: freezed == weekStart
          ? _value.weekStart
          : weekStart // ignore: cast_nullable_to_non_nullable
              as String?,
      weekEnd: freezed == weekEnd
          ? _value.weekEnd
          : weekEnd // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VolumeMetricsImpl implements _VolumeMetrics {
  const _$VolumeMetricsImpl(
      {required final List<VolumeByExercise> byExercise,
      required final List<VolumeByMuscle> byMuscle,
      this.weekStart,
      this.weekEnd})
      : _byExercise = byExercise,
        _byMuscle = byMuscle;

  factory _$VolumeMetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$VolumeMetricsImplFromJson(json);

  final List<VolumeByExercise> _byExercise;
  @override
  List<VolumeByExercise> get byExercise {
    if (_byExercise is EqualUnmodifiableListView) return _byExercise;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_byExercise);
  }

  final List<VolumeByMuscle> _byMuscle;
  @override
  List<VolumeByMuscle> get byMuscle {
    if (_byMuscle is EqualUnmodifiableListView) return _byMuscle;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_byMuscle);
  }

  @override
  final String? weekStart;
  @override
  final String? weekEnd;

  @override
  String toString() {
    return 'VolumeMetrics(byExercise: $byExercise, byMuscle: $byMuscle, weekStart: $weekStart, weekEnd: $weekEnd)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VolumeMetricsImpl &&
            const DeepCollectionEquality()
                .equals(other._byExercise, _byExercise) &&
            const DeepCollectionEquality().equals(other._byMuscle, _byMuscle) &&
            (identical(other.weekStart, weekStart) ||
                other.weekStart == weekStart) &&
            (identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_byExercise),
      const DeepCollectionEquality().hash(_byMuscle),
      weekStart,
      weekEnd);

  /// Create a copy of VolumeMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VolumeMetricsImplCopyWith<_$VolumeMetricsImpl> get copyWith =>
      __$$VolumeMetricsImplCopyWithImpl<_$VolumeMetricsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VolumeMetricsImplToJson(
      this,
    );
  }
}

abstract class _VolumeMetrics implements VolumeMetrics {
  const factory _VolumeMetrics(
      {required final List<VolumeByExercise> byExercise,
      required final List<VolumeByMuscle> byMuscle,
      final String? weekStart,
      final String? weekEnd}) = _$VolumeMetricsImpl;

  factory _VolumeMetrics.fromJson(Map<String, dynamic> json) =
      _$VolumeMetricsImpl.fromJson;

  @override
  List<VolumeByExercise> get byExercise;
  @override
  List<VolumeByMuscle> get byMuscle;
  @override
  String? get weekStart;
  @override
  String? get weekEnd;

  /// Create a copy of VolumeMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VolumeMetricsImplCopyWith<_$VolumeMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VolumeByExercise _$VolumeByExerciseFromJson(Map<String, dynamic> json) {
  return _VolumeByExercise.fromJson(json);
}

/// @nodoc
mixin _$VolumeByExercise {
  String get exerciseId => throw _privateConstructorUsedError;
  double get volume => throw _privateConstructorUsedError;

  /// Serializes this VolumeByExercise to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VolumeByExercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VolumeByExerciseCopyWith<VolumeByExercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VolumeByExerciseCopyWith<$Res> {
  factory $VolumeByExerciseCopyWith(
          VolumeByExercise value, $Res Function(VolumeByExercise) then) =
      _$VolumeByExerciseCopyWithImpl<$Res, VolumeByExercise>;
  @useResult
  $Res call({String exerciseId, double volume});
}

/// @nodoc
class _$VolumeByExerciseCopyWithImpl<$Res, $Val extends VolumeByExercise>
    implements $VolumeByExerciseCopyWith<$Res> {
  _$VolumeByExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VolumeByExercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? volume = null,
  }) {
    return _then(_value.copyWith(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VolumeByExerciseImplCopyWith<$Res>
    implements $VolumeByExerciseCopyWith<$Res> {
  factory _$$VolumeByExerciseImplCopyWith(_$VolumeByExerciseImpl value,
          $Res Function(_$VolumeByExerciseImpl) then) =
      __$$VolumeByExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String exerciseId, double volume});
}

/// @nodoc
class __$$VolumeByExerciseImplCopyWithImpl<$Res>
    extends _$VolumeByExerciseCopyWithImpl<$Res, _$VolumeByExerciseImpl>
    implements _$$VolumeByExerciseImplCopyWith<$Res> {
  __$$VolumeByExerciseImplCopyWithImpl(_$VolumeByExerciseImpl _value,
      $Res Function(_$VolumeByExerciseImpl) _then)
      : super(_value, _then);

  /// Create a copy of VolumeByExercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? volume = null,
  }) {
    return _then(_$VolumeByExerciseImpl(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VolumeByExerciseImpl implements _VolumeByExercise {
  const _$VolumeByExerciseImpl(
      {required this.exerciseId, required this.volume});

  factory _$VolumeByExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$VolumeByExerciseImplFromJson(json);

  @override
  final String exerciseId;
  @override
  final double volume;

  @override
  String toString() {
    return 'VolumeByExercise(exerciseId: $exerciseId, volume: $volume)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VolumeByExerciseImpl &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, exerciseId, volume);

  /// Create a copy of VolumeByExercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VolumeByExerciseImplCopyWith<_$VolumeByExerciseImpl> get copyWith =>
      __$$VolumeByExerciseImplCopyWithImpl<_$VolumeByExerciseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VolumeByExerciseImplToJson(
      this,
    );
  }
}

abstract class _VolumeByExercise implements VolumeByExercise {
  const factory _VolumeByExercise(
      {required final String exerciseId,
      required final double volume}) = _$VolumeByExerciseImpl;

  factory _VolumeByExercise.fromJson(Map<String, dynamic> json) =
      _$VolumeByExerciseImpl.fromJson;

  @override
  String get exerciseId;
  @override
  double get volume;

  /// Create a copy of VolumeByExercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VolumeByExerciseImplCopyWith<_$VolumeByExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VolumeByMuscle _$VolumeByMuscleFromJson(Map<String, dynamic> json) {
  return _VolumeByMuscle.fromJson(json);
}

/// @nodoc
mixin _$VolumeByMuscle {
  String get muscleId => throw _privateConstructorUsedError;
  double get volume => throw _privateConstructorUsedError;

  /// Serializes this VolumeByMuscle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VolumeByMuscle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VolumeByMuscleCopyWith<VolumeByMuscle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VolumeByMuscleCopyWith<$Res> {
  factory $VolumeByMuscleCopyWith(
          VolumeByMuscle value, $Res Function(VolumeByMuscle) then) =
      _$VolumeByMuscleCopyWithImpl<$Res, VolumeByMuscle>;
  @useResult
  $Res call({String muscleId, double volume});
}

/// @nodoc
class _$VolumeByMuscleCopyWithImpl<$Res, $Val extends VolumeByMuscle>
    implements $VolumeByMuscleCopyWith<$Res> {
  _$VolumeByMuscleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VolumeByMuscle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? muscleId = null,
    Object? volume = null,
  }) {
    return _then(_value.copyWith(
      muscleId: null == muscleId
          ? _value.muscleId
          : muscleId // ignore: cast_nullable_to_non_nullable
              as String,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VolumeByMuscleImplCopyWith<$Res>
    implements $VolumeByMuscleCopyWith<$Res> {
  factory _$$VolumeByMuscleImplCopyWith(_$VolumeByMuscleImpl value,
          $Res Function(_$VolumeByMuscleImpl) then) =
      __$$VolumeByMuscleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String muscleId, double volume});
}

/// @nodoc
class __$$VolumeByMuscleImplCopyWithImpl<$Res>
    extends _$VolumeByMuscleCopyWithImpl<$Res, _$VolumeByMuscleImpl>
    implements _$$VolumeByMuscleImplCopyWith<$Res> {
  __$$VolumeByMuscleImplCopyWithImpl(
      _$VolumeByMuscleImpl _value, $Res Function(_$VolumeByMuscleImpl) _then)
      : super(_value, _then);

  /// Create a copy of VolumeByMuscle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? muscleId = null,
    Object? volume = null,
  }) {
    return _then(_$VolumeByMuscleImpl(
      muscleId: null == muscleId
          ? _value.muscleId
          : muscleId // ignore: cast_nullable_to_non_nullable
              as String,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VolumeByMuscleImpl implements _VolumeByMuscle {
  const _$VolumeByMuscleImpl({required this.muscleId, required this.volume});

  factory _$VolumeByMuscleImpl.fromJson(Map<String, dynamic> json) =>
      _$$VolumeByMuscleImplFromJson(json);

  @override
  final String muscleId;
  @override
  final double volume;

  @override
  String toString() {
    return 'VolumeByMuscle(muscleId: $muscleId, volume: $volume)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VolumeByMuscleImpl &&
            (identical(other.muscleId, muscleId) ||
                other.muscleId == muscleId) &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, muscleId, volume);

  /// Create a copy of VolumeByMuscle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VolumeByMuscleImplCopyWith<_$VolumeByMuscleImpl> get copyWith =>
      __$$VolumeByMuscleImplCopyWithImpl<_$VolumeByMuscleImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VolumeByMuscleImplToJson(
      this,
    );
  }
}

abstract class _VolumeByMuscle implements VolumeByMuscle {
  const factory _VolumeByMuscle(
      {required final String muscleId,
      required final double volume}) = _$VolumeByMuscleImpl;

  factory _VolumeByMuscle.fromJson(Map<String, dynamic> json) =
      _$VolumeByMuscleImpl.fromJson;

  @override
  String get muscleId;
  @override
  double get volume;

  /// Create a copy of VolumeByMuscle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VolumeByMuscleImplCopyWith<_$VolumeByMuscleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
