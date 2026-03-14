// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'muscle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Muscle _$MuscleFromJson(Map<String, dynamic> json) {
  return _Muscle.fromJson(json);
}

/// @nodoc
mixin _$Muscle {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get region => throw _privateConstructorUsedError;
  String? get meshRegionId => throw _privateConstructorUsedError;

  /// Serializes this Muscle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Muscle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MuscleCopyWith<Muscle> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MuscleCopyWith<$Res> {
  factory $MuscleCopyWith(Muscle value, $Res Function(Muscle) then) =
      _$MuscleCopyWithImpl<$Res, Muscle>;
  @useResult
  $Res call({String id, String name, String region, String? meshRegionId});
}

/// @nodoc
class _$MuscleCopyWithImpl<$Res, $Val extends Muscle>
    implements $MuscleCopyWith<$Res> {
  _$MuscleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Muscle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? region = null,
    Object? meshRegionId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String,
      meshRegionId: freezed == meshRegionId
          ? _value.meshRegionId
          : meshRegionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MuscleImplCopyWith<$Res> implements $MuscleCopyWith<$Res> {
  factory _$$MuscleImplCopyWith(
          _$MuscleImpl value, $Res Function(_$MuscleImpl) then) =
      __$$MuscleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String region, String? meshRegionId});
}

/// @nodoc
class __$$MuscleImplCopyWithImpl<$Res>
    extends _$MuscleCopyWithImpl<$Res, _$MuscleImpl>
    implements _$$MuscleImplCopyWith<$Res> {
  __$$MuscleImplCopyWithImpl(
      _$MuscleImpl _value, $Res Function(_$MuscleImpl) _then)
      : super(_value, _then);

  /// Create a copy of Muscle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? region = null,
    Object? meshRegionId = freezed,
  }) {
    return _then(_$MuscleImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String,
      meshRegionId: freezed == meshRegionId
          ? _value.meshRegionId
          : meshRegionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MuscleImpl implements _Muscle {
  const _$MuscleImpl(
      {required this.id,
      required this.name,
      required this.region,
      this.meshRegionId});

  factory _$MuscleImpl.fromJson(Map<String, dynamic> json) =>
      _$$MuscleImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String region;
  @override
  final String? meshRegionId;

  @override
  String toString() {
    return 'Muscle(id: $id, name: $name, region: $region, meshRegionId: $meshRegionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MuscleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.meshRegionId, meshRegionId) ||
                other.meshRegionId == meshRegionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, region, meshRegionId);

  /// Create a copy of Muscle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MuscleImplCopyWith<_$MuscleImpl> get copyWith =>
      __$$MuscleImplCopyWithImpl<_$MuscleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MuscleImplToJson(
      this,
    );
  }
}

abstract class _Muscle implements Muscle {
  const factory _Muscle(
      {required final String id,
      required final String name,
      required final String region,
      final String? meshRegionId}) = _$MuscleImpl;

  factory _Muscle.fromJson(Map<String, dynamic> json) = _$MuscleImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get region;
  @override
  String? get meshRegionId;

  /// Create a copy of Muscle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MuscleImplCopyWith<_$MuscleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
