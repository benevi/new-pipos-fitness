// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExerciseDetail _$ExerciseDetailFromJson(Map<String, dynamic> json) {
  return _ExerciseDetail.fromJson(json);
}

/// @nodoc
mixin _$ExerciseDetail {
  String get id => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int get difficulty => throw _privateConstructorUsedError;
  String? get movementPattern => throw _privateConstructorUsedError;
  String get place => throw _privateConstructorUsedError;
  List<ExerciseMuscle> get muscles => throw _privateConstructorUsedError;
  List<ExerciseMedia> get media => throw _privateConstructorUsedError;

  /// Serializes this ExerciseDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExerciseDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseDetailCopyWith<ExerciseDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseDetailCopyWith<$Res> {
  factory $ExerciseDetailCopyWith(
          ExerciseDetail value, $Res Function(ExerciseDetail) then) =
      _$ExerciseDetailCopyWithImpl<$Res, ExerciseDetail>;
  @useResult
  $Res call(
      {String id,
      String slug,
      String name,
      String? description,
      int difficulty,
      String? movementPattern,
      String place,
      List<ExerciseMuscle> muscles,
      List<ExerciseMedia> media});
}

/// @nodoc
class _$ExerciseDetailCopyWithImpl<$Res, $Val extends ExerciseDetail>
    implements $ExerciseDetailCopyWith<$Res> {
  _$ExerciseDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExerciseDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? slug = null,
    Object? name = null,
    Object? description = freezed,
    Object? difficulty = null,
    Object? movementPattern = freezed,
    Object? place = null,
    Object? muscles = null,
    Object? media = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as int,
      movementPattern: freezed == movementPattern
          ? _value.movementPattern
          : movementPattern // ignore: cast_nullable_to_non_nullable
              as String?,
      place: null == place
          ? _value.place
          : place // ignore: cast_nullable_to_non_nullable
              as String,
      muscles: null == muscles
          ? _value.muscles
          : muscles // ignore: cast_nullable_to_non_nullable
              as List<ExerciseMuscle>,
      media: null == media
          ? _value.media
          : media // ignore: cast_nullable_to_non_nullable
              as List<ExerciseMedia>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseDetailImplCopyWith<$Res>
    implements $ExerciseDetailCopyWith<$Res> {
  factory _$$ExerciseDetailImplCopyWith(_$ExerciseDetailImpl value,
          $Res Function(_$ExerciseDetailImpl) then) =
      __$$ExerciseDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String slug,
      String name,
      String? description,
      int difficulty,
      String? movementPattern,
      String place,
      List<ExerciseMuscle> muscles,
      List<ExerciseMedia> media});
}

/// @nodoc
class __$$ExerciseDetailImplCopyWithImpl<$Res>
    extends _$ExerciseDetailCopyWithImpl<$Res, _$ExerciseDetailImpl>
    implements _$$ExerciseDetailImplCopyWith<$Res> {
  __$$ExerciseDetailImplCopyWithImpl(
      _$ExerciseDetailImpl _value, $Res Function(_$ExerciseDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExerciseDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? slug = null,
    Object? name = null,
    Object? description = freezed,
    Object? difficulty = null,
    Object? movementPattern = freezed,
    Object? place = null,
    Object? muscles = null,
    Object? media = null,
  }) {
    return _then(_$ExerciseDetailImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as int,
      movementPattern: freezed == movementPattern
          ? _value.movementPattern
          : movementPattern // ignore: cast_nullable_to_non_nullable
              as String?,
      place: null == place
          ? _value.place
          : place // ignore: cast_nullable_to_non_nullable
              as String,
      muscles: null == muscles
          ? _value._muscles
          : muscles // ignore: cast_nullable_to_non_nullable
              as List<ExerciseMuscle>,
      media: null == media
          ? _value._media
          : media // ignore: cast_nullable_to_non_nullable
              as List<ExerciseMedia>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseDetailImpl implements _ExerciseDetail {
  const _$ExerciseDetailImpl(
      {required this.id,
      required this.slug,
      required this.name,
      this.description,
      required this.difficulty,
      this.movementPattern,
      required this.place,
      final List<ExerciseMuscle> muscles = const [],
      final List<ExerciseMedia> media = const []})
      : _muscles = muscles,
        _media = media;

  factory _$ExerciseDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseDetailImplFromJson(json);

  @override
  final String id;
  @override
  final String slug;
  @override
  final String name;
  @override
  final String? description;
  @override
  final int difficulty;
  @override
  final String? movementPattern;
  @override
  final String place;
  final List<ExerciseMuscle> _muscles;
  @override
  @JsonKey()
  List<ExerciseMuscle> get muscles {
    if (_muscles is EqualUnmodifiableListView) return _muscles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_muscles);
  }

  final List<ExerciseMedia> _media;
  @override
  @JsonKey()
  List<ExerciseMedia> get media {
    if (_media is EqualUnmodifiableListView) return _media;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_media);
  }

  @override
  String toString() {
    return 'ExerciseDetail(id: $id, slug: $slug, name: $name, description: $description, difficulty: $difficulty, movementPattern: $movementPattern, place: $place, muscles: $muscles, media: $media)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.movementPattern, movementPattern) ||
                other.movementPattern == movementPattern) &&
            (identical(other.place, place) || other.place == place) &&
            const DeepCollectionEquality().equals(other._muscles, _muscles) &&
            const DeepCollectionEquality().equals(other._media, _media));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      slug,
      name,
      description,
      difficulty,
      movementPattern,
      place,
      const DeepCollectionEquality().hash(_muscles),
      const DeepCollectionEquality().hash(_media));

  /// Create a copy of ExerciseDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseDetailImplCopyWith<_$ExerciseDetailImpl> get copyWith =>
      __$$ExerciseDetailImplCopyWithImpl<_$ExerciseDetailImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseDetailImplToJson(
      this,
    );
  }
}

abstract class _ExerciseDetail implements ExerciseDetail {
  const factory _ExerciseDetail(
      {required final String id,
      required final String slug,
      required final String name,
      final String? description,
      required final int difficulty,
      final String? movementPattern,
      required final String place,
      final List<ExerciseMuscle> muscles,
      final List<ExerciseMedia> media}) = _$ExerciseDetailImpl;

  factory _ExerciseDetail.fromJson(Map<String, dynamic> json) =
      _$ExerciseDetailImpl.fromJson;

  @override
  String get id;
  @override
  String get slug;
  @override
  String get name;
  @override
  String? get description;
  @override
  int get difficulty;
  @override
  String? get movementPattern;
  @override
  String get place;
  @override
  List<ExerciseMuscle> get muscles;
  @override
  List<ExerciseMedia> get media;

  /// Create a copy of ExerciseDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseDetailImplCopyWith<_$ExerciseDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
