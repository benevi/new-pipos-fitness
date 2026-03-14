// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_muscle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExerciseMuscle _$ExerciseMuscleFromJson(Map<String, dynamic> json) {
  return _ExerciseMuscle.fromJson(json);
}

/// @nodoc
mixin _$ExerciseMuscle {
  String get exerciseId => throw _privateConstructorUsedError;
  String get muscleId => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  Muscle? get muscle => throw _privateConstructorUsedError;

  /// Serializes this ExerciseMuscle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExerciseMuscle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseMuscleCopyWith<ExerciseMuscle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseMuscleCopyWith<$Res> {
  factory $ExerciseMuscleCopyWith(
          ExerciseMuscle value, $Res Function(ExerciseMuscle) then) =
      _$ExerciseMuscleCopyWithImpl<$Res, ExerciseMuscle>;
  @useResult
  $Res call({String exerciseId, String muscleId, String role, Muscle? muscle});

  $MuscleCopyWith<$Res>? get muscle;
}

/// @nodoc
class _$ExerciseMuscleCopyWithImpl<$Res, $Val extends ExerciseMuscle>
    implements $ExerciseMuscleCopyWith<$Res> {
  _$ExerciseMuscleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExerciseMuscle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? muscleId = null,
    Object? role = null,
    Object? muscle = freezed,
  }) {
    return _then(_value.copyWith(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      muscleId: null == muscleId
          ? _value.muscleId
          : muscleId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      muscle: freezed == muscle
          ? _value.muscle
          : muscle // ignore: cast_nullable_to_non_nullable
              as Muscle?,
    ) as $Val);
  }

  /// Create a copy of ExerciseMuscle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MuscleCopyWith<$Res>? get muscle {
    if (_value.muscle == null) {
      return null;
    }

    return $MuscleCopyWith<$Res>(_value.muscle!, (value) {
      return _then(_value.copyWith(muscle: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ExerciseMuscleImplCopyWith<$Res>
    implements $ExerciseMuscleCopyWith<$Res> {
  factory _$$ExerciseMuscleImplCopyWith(_$ExerciseMuscleImpl value,
          $Res Function(_$ExerciseMuscleImpl) then) =
      __$$ExerciseMuscleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String exerciseId, String muscleId, String role, Muscle? muscle});

  @override
  $MuscleCopyWith<$Res>? get muscle;
}

/// @nodoc
class __$$ExerciseMuscleImplCopyWithImpl<$Res>
    extends _$ExerciseMuscleCopyWithImpl<$Res, _$ExerciseMuscleImpl>
    implements _$$ExerciseMuscleImplCopyWith<$Res> {
  __$$ExerciseMuscleImplCopyWithImpl(
      _$ExerciseMuscleImpl _value, $Res Function(_$ExerciseMuscleImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExerciseMuscle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? muscleId = null,
    Object? role = null,
    Object? muscle = freezed,
  }) {
    return _then(_$ExerciseMuscleImpl(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      muscleId: null == muscleId
          ? _value.muscleId
          : muscleId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      muscle: freezed == muscle
          ? _value.muscle
          : muscle // ignore: cast_nullable_to_non_nullable
              as Muscle?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseMuscleImpl implements _ExerciseMuscle {
  const _$ExerciseMuscleImpl(
      {required this.exerciseId,
      required this.muscleId,
      required this.role,
      this.muscle});

  factory _$ExerciseMuscleImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseMuscleImplFromJson(json);

  @override
  final String exerciseId;
  @override
  final String muscleId;
  @override
  final String role;
  @override
  final Muscle? muscle;

  @override
  String toString() {
    return 'ExerciseMuscle(exerciseId: $exerciseId, muscleId: $muscleId, role: $role, muscle: $muscle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseMuscleImpl &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.muscleId, muscleId) ||
                other.muscleId == muscleId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.muscle, muscle) || other.muscle == muscle));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, exerciseId, muscleId, role, muscle);

  /// Create a copy of ExerciseMuscle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseMuscleImplCopyWith<_$ExerciseMuscleImpl> get copyWith =>
      __$$ExerciseMuscleImplCopyWithImpl<_$ExerciseMuscleImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseMuscleImplToJson(
      this,
    );
  }
}

abstract class _ExerciseMuscle implements ExerciseMuscle {
  const factory _ExerciseMuscle(
      {required final String exerciseId,
      required final String muscleId,
      required final String role,
      final Muscle? muscle}) = _$ExerciseMuscleImpl;

  factory _ExerciseMuscle.fromJson(Map<String, dynamic> json) =
      _$ExerciseMuscleImpl.fromJson;

  @override
  String get exerciseId;
  @override
  String get muscleId;
  @override
  String get role;
  @override
  Muscle? get muscle;

  /// Create a copy of ExerciseMuscle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseMuscleImplCopyWith<_$ExerciseMuscleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
