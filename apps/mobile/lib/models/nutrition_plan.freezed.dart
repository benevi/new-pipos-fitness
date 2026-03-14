// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nutrition_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NutritionPlan _$NutritionPlanFromJson(Map<String, dynamic> json) {
  return _NutritionPlan.fromJson(json);
}

/// @nodoc
mixin _$NutritionPlan {
  NutritionPlanInfo get plan => throw _privateConstructorUsedError;
  NutritionPlanVersion get version => throw _privateConstructorUsedError;

  /// Serializes this NutritionPlan to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NutritionPlanCopyWith<NutritionPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionPlanCopyWith<$Res> {
  factory $NutritionPlanCopyWith(
          NutritionPlan value, $Res Function(NutritionPlan) then) =
      _$NutritionPlanCopyWithImpl<$Res, NutritionPlan>;
  @useResult
  $Res call({NutritionPlanInfo plan, NutritionPlanVersion version});

  $NutritionPlanInfoCopyWith<$Res> get plan;
  $NutritionPlanVersionCopyWith<$Res> get version;
}

/// @nodoc
class _$NutritionPlanCopyWithImpl<$Res, $Val extends NutritionPlan>
    implements $NutritionPlanCopyWith<$Res> {
  _$NutritionPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? version = null,
  }) {
    return _then(_value.copyWith(
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as NutritionPlanInfo,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as NutritionPlanVersion,
    ) as $Val);
  }

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NutritionPlanInfoCopyWith<$Res> get plan {
    return $NutritionPlanInfoCopyWith<$Res>(_value.plan, (value) {
      return _then(_value.copyWith(plan: value) as $Val);
    });
  }

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NutritionPlanVersionCopyWith<$Res> get version {
    return $NutritionPlanVersionCopyWith<$Res>(_value.version, (value) {
      return _then(_value.copyWith(version: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NutritionPlanImplCopyWith<$Res>
    implements $NutritionPlanCopyWith<$Res> {
  factory _$$NutritionPlanImplCopyWith(
          _$NutritionPlanImpl value, $Res Function(_$NutritionPlanImpl) then) =
      __$$NutritionPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({NutritionPlanInfo plan, NutritionPlanVersion version});

  @override
  $NutritionPlanInfoCopyWith<$Res> get plan;
  @override
  $NutritionPlanVersionCopyWith<$Res> get version;
}

/// @nodoc
class __$$NutritionPlanImplCopyWithImpl<$Res>
    extends _$NutritionPlanCopyWithImpl<$Res, _$NutritionPlanImpl>
    implements _$$NutritionPlanImplCopyWith<$Res> {
  __$$NutritionPlanImplCopyWithImpl(
      _$NutritionPlanImpl _value, $Res Function(_$NutritionPlanImpl) _then)
      : super(_value, _then);

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? version = null,
  }) {
    return _then(_$NutritionPlanImpl(
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as NutritionPlanInfo,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as NutritionPlanVersion,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NutritionPlanImpl implements _NutritionPlan {
  const _$NutritionPlanImpl({required this.plan, required this.version});

  factory _$NutritionPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionPlanImplFromJson(json);

  @override
  final NutritionPlanInfo plan;
  @override
  final NutritionPlanVersion version;

  @override
  String toString() {
    return 'NutritionPlan(plan: $plan, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionPlanImpl &&
            (identical(other.plan, plan) || other.plan == plan) &&
            (identical(other.version, version) || other.version == version));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, plan, version);

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionPlanImplCopyWith<_$NutritionPlanImpl> get copyWith =>
      __$$NutritionPlanImplCopyWithImpl<_$NutritionPlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionPlanImplToJson(
      this,
    );
  }
}

abstract class _NutritionPlan implements NutritionPlan {
  const factory _NutritionPlan(
      {required final NutritionPlanInfo plan,
      required final NutritionPlanVersion version}) = _$NutritionPlanImpl;

  factory _NutritionPlan.fromJson(Map<String, dynamic> json) =
      _$NutritionPlanImpl.fromJson;

  @override
  NutritionPlanInfo get plan;
  @override
  NutritionPlanVersion get version;

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NutritionPlanImplCopyWith<_$NutritionPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NutritionPlanInfo _$NutritionPlanInfoFromJson(Map<String, dynamic> json) {
  return _NutritionPlanInfo.fromJson(json);
}

/// @nodoc
mixin _$NutritionPlanInfo {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get currentVersionId => throw _privateConstructorUsedError;

  /// Serializes this NutritionPlanInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NutritionPlanInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NutritionPlanInfoCopyWith<NutritionPlanInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionPlanInfoCopyWith<$Res> {
  factory $NutritionPlanInfoCopyWith(
          NutritionPlanInfo value, $Res Function(NutritionPlanInfo) then) =
      _$NutritionPlanInfoCopyWithImpl<$Res, NutritionPlanInfo>;
  @useResult
  $Res call({String id, String userId, String? currentVersionId});
}

/// @nodoc
class _$NutritionPlanInfoCopyWithImpl<$Res, $Val extends NutritionPlanInfo>
    implements $NutritionPlanInfoCopyWith<$Res> {
  _$NutritionPlanInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NutritionPlanInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? currentVersionId = freezed,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NutritionPlanInfoImplCopyWith<$Res>
    implements $NutritionPlanInfoCopyWith<$Res> {
  factory _$$NutritionPlanInfoImplCopyWith(_$NutritionPlanInfoImpl value,
          $Res Function(_$NutritionPlanInfoImpl) then) =
      __$$NutritionPlanInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String userId, String? currentVersionId});
}

/// @nodoc
class __$$NutritionPlanInfoImplCopyWithImpl<$Res>
    extends _$NutritionPlanInfoCopyWithImpl<$Res, _$NutritionPlanInfoImpl>
    implements _$$NutritionPlanInfoImplCopyWith<$Res> {
  __$$NutritionPlanInfoImplCopyWithImpl(_$NutritionPlanInfoImpl _value,
      $Res Function(_$NutritionPlanInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of NutritionPlanInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? currentVersionId = freezed,
  }) {
    return _then(_$NutritionPlanInfoImpl(
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NutritionPlanInfoImpl implements _NutritionPlanInfo {
  const _$NutritionPlanInfoImpl(
      {required this.id, required this.userId, this.currentVersionId});

  factory _$NutritionPlanInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionPlanInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String? currentVersionId;

  @override
  String toString() {
    return 'NutritionPlanInfo(id: $id, userId: $userId, currentVersionId: $currentVersionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionPlanInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.currentVersionId, currentVersionId) ||
                other.currentVersionId == currentVersionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, currentVersionId);

  /// Create a copy of NutritionPlanInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionPlanInfoImplCopyWith<_$NutritionPlanInfoImpl> get copyWith =>
      __$$NutritionPlanInfoImplCopyWithImpl<_$NutritionPlanInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionPlanInfoImplToJson(
      this,
    );
  }
}

abstract class _NutritionPlanInfo implements NutritionPlanInfo {
  const factory _NutritionPlanInfo(
      {required final String id,
      required final String userId,
      final String? currentVersionId}) = _$NutritionPlanInfoImpl;

  factory _NutritionPlanInfo.fromJson(Map<String, dynamic> json) =
      _$NutritionPlanInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String? get currentVersionId;

  /// Create a copy of NutritionPlanInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NutritionPlanInfoImplCopyWith<_$NutritionPlanInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NutritionPlanVersion _$NutritionPlanVersionFromJson(Map<String, dynamic> json) {
  return _NutritionPlanVersion.fromJson(json);
}

/// @nodoc
mixin _$NutritionPlanVersion {
  String get id => throw _privateConstructorUsedError;
  String get planId => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get engineVersion => throw _privateConstructorUsedError;
  double? get dailyCalorieTarget => throw _privateConstructorUsedError;
  NutritionMacroTarget? get dailyMacroTarget =>
      throw _privateConstructorUsedError;
  List<NutritionDay> get days => throw _privateConstructorUsedError;

  /// Serializes this NutritionPlanVersion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NutritionPlanVersion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NutritionPlanVersionCopyWith<NutritionPlanVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionPlanVersionCopyWith<$Res> {
  factory $NutritionPlanVersionCopyWith(NutritionPlanVersion value,
          $Res Function(NutritionPlanVersion) then) =
      _$NutritionPlanVersionCopyWithImpl<$Res, NutritionPlanVersion>;
  @useResult
  $Res call(
      {String id,
      String planId,
      int version,
      String createdAt,
      String engineVersion,
      double? dailyCalorieTarget,
      NutritionMacroTarget? dailyMacroTarget,
      List<NutritionDay> days});

  $NutritionMacroTargetCopyWith<$Res>? get dailyMacroTarget;
}

/// @nodoc
class _$NutritionPlanVersionCopyWithImpl<$Res,
        $Val extends NutritionPlanVersion>
    implements $NutritionPlanVersionCopyWith<$Res> {
  _$NutritionPlanVersionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NutritionPlanVersion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? version = null,
    Object? createdAt = null,
    Object? engineVersion = null,
    Object? dailyCalorieTarget = freezed,
    Object? dailyMacroTarget = freezed,
    Object? days = null,
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
      dailyCalorieTarget: freezed == dailyCalorieTarget
          ? _value.dailyCalorieTarget
          : dailyCalorieTarget // ignore: cast_nullable_to_non_nullable
              as double?,
      dailyMacroTarget: freezed == dailyMacroTarget
          ? _value.dailyMacroTarget
          : dailyMacroTarget // ignore: cast_nullable_to_non_nullable
              as NutritionMacroTarget?,
      days: null == days
          ? _value.days
          : days // ignore: cast_nullable_to_non_nullable
              as List<NutritionDay>,
    ) as $Val);
  }

  /// Create a copy of NutritionPlanVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NutritionMacroTargetCopyWith<$Res>? get dailyMacroTarget {
    if (_value.dailyMacroTarget == null) {
      return null;
    }

    return $NutritionMacroTargetCopyWith<$Res>(_value.dailyMacroTarget!,
        (value) {
      return _then(_value.copyWith(dailyMacroTarget: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NutritionPlanVersionImplCopyWith<$Res>
    implements $NutritionPlanVersionCopyWith<$Res> {
  factory _$$NutritionPlanVersionImplCopyWith(_$NutritionPlanVersionImpl value,
          $Res Function(_$NutritionPlanVersionImpl) then) =
      __$$NutritionPlanVersionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String planId,
      int version,
      String createdAt,
      String engineVersion,
      double? dailyCalorieTarget,
      NutritionMacroTarget? dailyMacroTarget,
      List<NutritionDay> days});

  @override
  $NutritionMacroTargetCopyWith<$Res>? get dailyMacroTarget;
}

/// @nodoc
class __$$NutritionPlanVersionImplCopyWithImpl<$Res>
    extends _$NutritionPlanVersionCopyWithImpl<$Res, _$NutritionPlanVersionImpl>
    implements _$$NutritionPlanVersionImplCopyWith<$Res> {
  __$$NutritionPlanVersionImplCopyWithImpl(_$NutritionPlanVersionImpl _value,
      $Res Function(_$NutritionPlanVersionImpl) _then)
      : super(_value, _then);

  /// Create a copy of NutritionPlanVersion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? version = null,
    Object? createdAt = null,
    Object? engineVersion = null,
    Object? dailyCalorieTarget = freezed,
    Object? dailyMacroTarget = freezed,
    Object? days = null,
  }) {
    return _then(_$NutritionPlanVersionImpl(
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
      dailyCalorieTarget: freezed == dailyCalorieTarget
          ? _value.dailyCalorieTarget
          : dailyCalorieTarget // ignore: cast_nullable_to_non_nullable
              as double?,
      dailyMacroTarget: freezed == dailyMacroTarget
          ? _value.dailyMacroTarget
          : dailyMacroTarget // ignore: cast_nullable_to_non_nullable
              as NutritionMacroTarget?,
      days: null == days
          ? _value._days
          : days // ignore: cast_nullable_to_non_nullable
              as List<NutritionDay>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NutritionPlanVersionImpl implements _NutritionPlanVersion {
  const _$NutritionPlanVersionImpl(
      {required this.id,
      required this.planId,
      required this.version,
      required this.createdAt,
      required this.engineVersion,
      this.dailyCalorieTarget,
      this.dailyMacroTarget,
      required final List<NutritionDay> days})
      : _days = days;

  factory _$NutritionPlanVersionImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionPlanVersionImplFromJson(json);

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
  final double? dailyCalorieTarget;
  @override
  final NutritionMacroTarget? dailyMacroTarget;
  final List<NutritionDay> _days;
  @override
  List<NutritionDay> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  @override
  String toString() {
    return 'NutritionPlanVersion(id: $id, planId: $planId, version: $version, createdAt: $createdAt, engineVersion: $engineVersion, dailyCalorieTarget: $dailyCalorieTarget, dailyMacroTarget: $dailyMacroTarget, days: $days)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionPlanVersionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.engineVersion, engineVersion) ||
                other.engineVersion == engineVersion) &&
            (identical(other.dailyCalorieTarget, dailyCalorieTarget) ||
                other.dailyCalorieTarget == dailyCalorieTarget) &&
            (identical(other.dailyMacroTarget, dailyMacroTarget) ||
                other.dailyMacroTarget == dailyMacroTarget) &&
            const DeepCollectionEquality().equals(other._days, _days));
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
      dailyCalorieTarget,
      dailyMacroTarget,
      const DeepCollectionEquality().hash(_days));

  /// Create a copy of NutritionPlanVersion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionPlanVersionImplCopyWith<_$NutritionPlanVersionImpl>
      get copyWith =>
          __$$NutritionPlanVersionImplCopyWithImpl<_$NutritionPlanVersionImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionPlanVersionImplToJson(
      this,
    );
  }
}

abstract class _NutritionPlanVersion implements NutritionPlanVersion {
  const factory _NutritionPlanVersion(
      {required final String id,
      required final String planId,
      required final int version,
      required final String createdAt,
      required final String engineVersion,
      final double? dailyCalorieTarget,
      final NutritionMacroTarget? dailyMacroTarget,
      required final List<NutritionDay> days}) = _$NutritionPlanVersionImpl;

  factory _NutritionPlanVersion.fromJson(Map<String, dynamic> json) =
      _$NutritionPlanVersionImpl.fromJson;

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
  double? get dailyCalorieTarget;
  @override
  NutritionMacroTarget? get dailyMacroTarget;
  @override
  List<NutritionDay> get days;

  /// Create a copy of NutritionPlanVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NutritionPlanVersionImplCopyWith<_$NutritionPlanVersionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

NutritionMacroTarget _$NutritionMacroTargetFromJson(Map<String, dynamic> json) {
  return _NutritionMacroTarget.fromJson(json);
}

/// @nodoc
mixin _$NutritionMacroTarget {
  double get proteinG => throw _privateConstructorUsedError;
  double get carbsG => throw _privateConstructorUsedError;
  double get fatG => throw _privateConstructorUsedError;

  /// Serializes this NutritionMacroTarget to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NutritionMacroTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NutritionMacroTargetCopyWith<NutritionMacroTarget> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionMacroTargetCopyWith<$Res> {
  factory $NutritionMacroTargetCopyWith(NutritionMacroTarget value,
          $Res Function(NutritionMacroTarget) then) =
      _$NutritionMacroTargetCopyWithImpl<$Res, NutritionMacroTarget>;
  @useResult
  $Res call({double proteinG, double carbsG, double fatG});
}

/// @nodoc
class _$NutritionMacroTargetCopyWithImpl<$Res,
        $Val extends NutritionMacroTarget>
    implements $NutritionMacroTargetCopyWith<$Res> {
  _$NutritionMacroTargetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NutritionMacroTarget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? proteinG = null,
    Object? carbsG = null,
    Object? fatG = null,
  }) {
    return _then(_value.copyWith(
      proteinG: null == proteinG
          ? _value.proteinG
          : proteinG // ignore: cast_nullable_to_non_nullable
              as double,
      carbsG: null == carbsG
          ? _value.carbsG
          : carbsG // ignore: cast_nullable_to_non_nullable
              as double,
      fatG: null == fatG
          ? _value.fatG
          : fatG // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NutritionMacroTargetImplCopyWith<$Res>
    implements $NutritionMacroTargetCopyWith<$Res> {
  factory _$$NutritionMacroTargetImplCopyWith(_$NutritionMacroTargetImpl value,
          $Res Function(_$NutritionMacroTargetImpl) then) =
      __$$NutritionMacroTargetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double proteinG, double carbsG, double fatG});
}

/// @nodoc
class __$$NutritionMacroTargetImplCopyWithImpl<$Res>
    extends _$NutritionMacroTargetCopyWithImpl<$Res, _$NutritionMacroTargetImpl>
    implements _$$NutritionMacroTargetImplCopyWith<$Res> {
  __$$NutritionMacroTargetImplCopyWithImpl(_$NutritionMacroTargetImpl _value,
      $Res Function(_$NutritionMacroTargetImpl) _then)
      : super(_value, _then);

  /// Create a copy of NutritionMacroTarget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? proteinG = null,
    Object? carbsG = null,
    Object? fatG = null,
  }) {
    return _then(_$NutritionMacroTargetImpl(
      proteinG: null == proteinG
          ? _value.proteinG
          : proteinG // ignore: cast_nullable_to_non_nullable
              as double,
      carbsG: null == carbsG
          ? _value.carbsG
          : carbsG // ignore: cast_nullable_to_non_nullable
              as double,
      fatG: null == fatG
          ? _value.fatG
          : fatG // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NutritionMacroTargetImpl implements _NutritionMacroTarget {
  const _$NutritionMacroTargetImpl(
      {required this.proteinG, required this.carbsG, required this.fatG});

  factory _$NutritionMacroTargetImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionMacroTargetImplFromJson(json);

  @override
  final double proteinG;
  @override
  final double carbsG;
  @override
  final double fatG;

  @override
  String toString() {
    return 'NutritionMacroTarget(proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionMacroTargetImpl &&
            (identical(other.proteinG, proteinG) ||
                other.proteinG == proteinG) &&
            (identical(other.carbsG, carbsG) || other.carbsG == carbsG) &&
            (identical(other.fatG, fatG) || other.fatG == fatG));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, proteinG, carbsG, fatG);

  /// Create a copy of NutritionMacroTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionMacroTargetImplCopyWith<_$NutritionMacroTargetImpl>
      get copyWith =>
          __$$NutritionMacroTargetImplCopyWithImpl<_$NutritionMacroTargetImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionMacroTargetImplToJson(
      this,
    );
  }
}

abstract class _NutritionMacroTarget implements NutritionMacroTarget {
  const factory _NutritionMacroTarget(
      {required final double proteinG,
      required final double carbsG,
      required final double fatG}) = _$NutritionMacroTargetImpl;

  factory _NutritionMacroTarget.fromJson(Map<String, dynamic> json) =
      _$NutritionMacroTargetImpl.fromJson;

  @override
  double get proteinG;
  @override
  double get carbsG;
  @override
  double get fatG;

  /// Create a copy of NutritionMacroTarget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NutritionMacroTargetImplCopyWith<_$NutritionMacroTargetImpl>
      get copyWith => throw _privateConstructorUsedError;
}

NutritionDay _$NutritionDayFromJson(Map<String, dynamic> json) {
  return _NutritionDayData.fromJson(json);
}

/// @nodoc
mixin _$NutritionDay {
  String get id => throw _privateConstructorUsedError;
  int get dayIndex => throw _privateConstructorUsedError;
  List<NutritionMeal> get meals => throw _privateConstructorUsedError;

  /// Serializes this NutritionDay to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NutritionDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NutritionDayCopyWith<NutritionDay> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionDayCopyWith<$Res> {
  factory $NutritionDayCopyWith(
          NutritionDay value, $Res Function(NutritionDay) then) =
      _$NutritionDayCopyWithImpl<$Res, NutritionDay>;
  @useResult
  $Res call({String id, int dayIndex, List<NutritionMeal> meals});
}

/// @nodoc
class _$NutritionDayCopyWithImpl<$Res, $Val extends NutritionDay>
    implements $NutritionDayCopyWith<$Res> {
  _$NutritionDayCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NutritionDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dayIndex = null,
    Object? meals = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      dayIndex: null == dayIndex
          ? _value.dayIndex
          : dayIndex // ignore: cast_nullable_to_non_nullable
              as int,
      meals: null == meals
          ? _value.meals
          : meals // ignore: cast_nullable_to_non_nullable
              as List<NutritionMeal>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NutritionDayDataImplCopyWith<$Res>
    implements $NutritionDayCopyWith<$Res> {
  factory _$$NutritionDayDataImplCopyWith(_$NutritionDayDataImpl value,
          $Res Function(_$NutritionDayDataImpl) then) =
      __$$NutritionDayDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, int dayIndex, List<NutritionMeal> meals});
}

/// @nodoc
class __$$NutritionDayDataImplCopyWithImpl<$Res>
    extends _$NutritionDayCopyWithImpl<$Res, _$NutritionDayDataImpl>
    implements _$$NutritionDayDataImplCopyWith<$Res> {
  __$$NutritionDayDataImplCopyWithImpl(_$NutritionDayDataImpl _value,
      $Res Function(_$NutritionDayDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of NutritionDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dayIndex = null,
    Object? meals = null,
  }) {
    return _then(_$NutritionDayDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      dayIndex: null == dayIndex
          ? _value.dayIndex
          : dayIndex // ignore: cast_nullable_to_non_nullable
              as int,
      meals: null == meals
          ? _value._meals
          : meals // ignore: cast_nullable_to_non_nullable
              as List<NutritionMeal>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NutritionDayDataImpl implements _NutritionDayData {
  const _$NutritionDayDataImpl(
      {required this.id,
      required this.dayIndex,
      required final List<NutritionMeal> meals})
      : _meals = meals;

  factory _$NutritionDayDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionDayDataImplFromJson(json);

  @override
  final String id;
  @override
  final int dayIndex;
  final List<NutritionMeal> _meals;
  @override
  List<NutritionMeal> get meals {
    if (_meals is EqualUnmodifiableListView) return _meals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_meals);
  }

  @override
  String toString() {
    return 'NutritionDay(id: $id, dayIndex: $dayIndex, meals: $meals)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionDayDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.dayIndex, dayIndex) ||
                other.dayIndex == dayIndex) &&
            const DeepCollectionEquality().equals(other._meals, _meals));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, dayIndex, const DeepCollectionEquality().hash(_meals));

  /// Create a copy of NutritionDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionDayDataImplCopyWith<_$NutritionDayDataImpl> get copyWith =>
      __$$NutritionDayDataImplCopyWithImpl<_$NutritionDayDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionDayDataImplToJson(
      this,
    );
  }
}

abstract class _NutritionDayData implements NutritionDay {
  const factory _NutritionDayData(
      {required final String id,
      required final int dayIndex,
      required final List<NutritionMeal> meals}) = _$NutritionDayDataImpl;

  factory _NutritionDayData.fromJson(Map<String, dynamic> json) =
      _$NutritionDayDataImpl.fromJson;

  @override
  String get id;
  @override
  int get dayIndex;
  @override
  List<NutritionMeal> get meals;

  /// Create a copy of NutritionDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NutritionDayDataImplCopyWith<_$NutritionDayDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NutritionMeal _$NutritionMealFromJson(Map<String, dynamic> json) {
  return _NutritionMeal.fromJson(json);
}

/// @nodoc
mixin _$NutritionMeal {
  String get id => throw _privateConstructorUsedError;
  int get mealIndex => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get templateId => throw _privateConstructorUsedError;
  List<NutritionMealItem> get items => throw _privateConstructorUsedError;

  /// Serializes this NutritionMeal to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NutritionMeal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NutritionMealCopyWith<NutritionMeal> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionMealCopyWith<$Res> {
  factory $NutritionMealCopyWith(
          NutritionMeal value, $Res Function(NutritionMeal) then) =
      _$NutritionMealCopyWithImpl<$Res, NutritionMeal>;
  @useResult
  $Res call(
      {String id,
      int mealIndex,
      String name,
      String? templateId,
      List<NutritionMealItem> items});
}

/// @nodoc
class _$NutritionMealCopyWithImpl<$Res, $Val extends NutritionMeal>
    implements $NutritionMealCopyWith<$Res> {
  _$NutritionMealCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NutritionMeal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mealIndex = null,
    Object? name = null,
    Object? templateId = freezed,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mealIndex: null == mealIndex
          ? _value.mealIndex
          : mealIndex // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: freezed == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<NutritionMealItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NutritionMealImplCopyWith<$Res>
    implements $NutritionMealCopyWith<$Res> {
  factory _$$NutritionMealImplCopyWith(
          _$NutritionMealImpl value, $Res Function(_$NutritionMealImpl) then) =
      __$$NutritionMealImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      int mealIndex,
      String name,
      String? templateId,
      List<NutritionMealItem> items});
}

/// @nodoc
class __$$NutritionMealImplCopyWithImpl<$Res>
    extends _$NutritionMealCopyWithImpl<$Res, _$NutritionMealImpl>
    implements _$$NutritionMealImplCopyWith<$Res> {
  __$$NutritionMealImplCopyWithImpl(
      _$NutritionMealImpl _value, $Res Function(_$NutritionMealImpl) _then)
      : super(_value, _then);

  /// Create a copy of NutritionMeal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mealIndex = null,
    Object? name = null,
    Object? templateId = freezed,
    Object? items = null,
  }) {
    return _then(_$NutritionMealImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mealIndex: null == mealIndex
          ? _value.mealIndex
          : mealIndex // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: freezed == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<NutritionMealItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NutritionMealImpl implements _NutritionMeal {
  const _$NutritionMealImpl(
      {required this.id,
      required this.mealIndex,
      required this.name,
      this.templateId,
      required final List<NutritionMealItem> items})
      : _items = items;

  factory _$NutritionMealImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionMealImplFromJson(json);

  @override
  final String id;
  @override
  final int mealIndex;
  @override
  final String name;
  @override
  final String? templateId;
  final List<NutritionMealItem> _items;
  @override
  List<NutritionMealItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'NutritionMeal(id: $id, mealIndex: $mealIndex, name: $name, templateId: $templateId, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionMealImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mealIndex, mealIndex) ||
                other.mealIndex == mealIndex) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, mealIndex, name, templateId,
      const DeepCollectionEquality().hash(_items));

  /// Create a copy of NutritionMeal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionMealImplCopyWith<_$NutritionMealImpl> get copyWith =>
      __$$NutritionMealImplCopyWithImpl<_$NutritionMealImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionMealImplToJson(
      this,
    );
  }
}

abstract class _NutritionMeal implements NutritionMeal {
  const factory _NutritionMeal(
      {required final String id,
      required final int mealIndex,
      required final String name,
      final String? templateId,
      required final List<NutritionMealItem> items}) = _$NutritionMealImpl;

  factory _NutritionMeal.fromJson(Map<String, dynamic> json) =
      _$NutritionMealImpl.fromJson;

  @override
  String get id;
  @override
  int get mealIndex;
  @override
  String get name;
  @override
  String? get templateId;
  @override
  List<NutritionMealItem> get items;

  /// Create a copy of NutritionMeal
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NutritionMealImplCopyWith<_$NutritionMealImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NutritionMealItem _$NutritionMealItemFromJson(Map<String, dynamic> json) {
  return _NutritionMealItem.fromJson(json);
}

/// @nodoc
mixin _$NutritionMealItem {
  String get id => throw _privateConstructorUsedError;
  String get foodId => throw _privateConstructorUsedError;
  double get quantityG => throw _privateConstructorUsedError;

  /// Serializes this NutritionMealItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NutritionMealItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NutritionMealItemCopyWith<NutritionMealItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionMealItemCopyWith<$Res> {
  factory $NutritionMealItemCopyWith(
          NutritionMealItem value, $Res Function(NutritionMealItem) then) =
      _$NutritionMealItemCopyWithImpl<$Res, NutritionMealItem>;
  @useResult
  $Res call({String id, String foodId, double quantityG});
}

/// @nodoc
class _$NutritionMealItemCopyWithImpl<$Res, $Val extends NutritionMealItem>
    implements $NutritionMealItemCopyWith<$Res> {
  _$NutritionMealItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NutritionMealItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? foodId = null,
    Object? quantityG = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      foodId: null == foodId
          ? _value.foodId
          : foodId // ignore: cast_nullable_to_non_nullable
              as String,
      quantityG: null == quantityG
          ? _value.quantityG
          : quantityG // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NutritionMealItemImplCopyWith<$Res>
    implements $NutritionMealItemCopyWith<$Res> {
  factory _$$NutritionMealItemImplCopyWith(_$NutritionMealItemImpl value,
          $Res Function(_$NutritionMealItemImpl) then) =
      __$$NutritionMealItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String foodId, double quantityG});
}

/// @nodoc
class __$$NutritionMealItemImplCopyWithImpl<$Res>
    extends _$NutritionMealItemCopyWithImpl<$Res, _$NutritionMealItemImpl>
    implements _$$NutritionMealItemImplCopyWith<$Res> {
  __$$NutritionMealItemImplCopyWithImpl(_$NutritionMealItemImpl _value,
      $Res Function(_$NutritionMealItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of NutritionMealItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? foodId = null,
    Object? quantityG = null,
  }) {
    return _then(_$NutritionMealItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      foodId: null == foodId
          ? _value.foodId
          : foodId // ignore: cast_nullable_to_non_nullable
              as String,
      quantityG: null == quantityG
          ? _value.quantityG
          : quantityG // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NutritionMealItemImpl implements _NutritionMealItem {
  const _$NutritionMealItemImpl(
      {required this.id, required this.foodId, required this.quantityG});

  factory _$NutritionMealItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionMealItemImplFromJson(json);

  @override
  final String id;
  @override
  final String foodId;
  @override
  final double quantityG;

  @override
  String toString() {
    return 'NutritionMealItem(id: $id, foodId: $foodId, quantityG: $quantityG)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionMealItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.foodId, foodId) || other.foodId == foodId) &&
            (identical(other.quantityG, quantityG) ||
                other.quantityG == quantityG));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, foodId, quantityG);

  /// Create a copy of NutritionMealItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionMealItemImplCopyWith<_$NutritionMealItemImpl> get copyWith =>
      __$$NutritionMealItemImplCopyWithImpl<_$NutritionMealItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionMealItemImplToJson(
      this,
    );
  }
}

abstract class _NutritionMealItem implements NutritionMealItem {
  const factory _NutritionMealItem(
      {required final String id,
      required final String foodId,
      required final double quantityG}) = _$NutritionMealItemImpl;

  factory _NutritionMealItem.fromJson(Map<String, dynamic> json) =
      _$NutritionMealItemImpl.fromJson;

  @override
  String get id;
  @override
  String get foodId;
  @override
  double get quantityG;

  /// Create a copy of NutritionMealItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NutritionMealItemImplCopyWith<_$NutritionMealItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NutritionVersionSummary _$NutritionVersionSummaryFromJson(
    Map<String, dynamic> json) {
  return _NutritionVersionSummary.fromJson(json);
}

/// @nodoc
mixin _$NutritionVersionSummary {
  String get id => throw _privateConstructorUsedError;
  String get planId => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get engineVersion => throw _privateConstructorUsedError;

  /// Serializes this NutritionVersionSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NutritionVersionSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NutritionVersionSummaryCopyWith<NutritionVersionSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionVersionSummaryCopyWith<$Res> {
  factory $NutritionVersionSummaryCopyWith(NutritionVersionSummary value,
          $Res Function(NutritionVersionSummary) then) =
      _$NutritionVersionSummaryCopyWithImpl<$Res, NutritionVersionSummary>;
  @useResult
  $Res call(
      {String id,
      String planId,
      int version,
      String createdAt,
      String engineVersion});
}

/// @nodoc
class _$NutritionVersionSummaryCopyWithImpl<$Res,
        $Val extends NutritionVersionSummary>
    implements $NutritionVersionSummaryCopyWith<$Res> {
  _$NutritionVersionSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NutritionVersionSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? version = null,
    Object? createdAt = null,
    Object? engineVersion = null,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NutritionVersionSummaryImplCopyWith<$Res>
    implements $NutritionVersionSummaryCopyWith<$Res> {
  factory _$$NutritionVersionSummaryImplCopyWith(
          _$NutritionVersionSummaryImpl value,
          $Res Function(_$NutritionVersionSummaryImpl) then) =
      __$$NutritionVersionSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String planId,
      int version,
      String createdAt,
      String engineVersion});
}

/// @nodoc
class __$$NutritionVersionSummaryImplCopyWithImpl<$Res>
    extends _$NutritionVersionSummaryCopyWithImpl<$Res,
        _$NutritionVersionSummaryImpl>
    implements _$$NutritionVersionSummaryImplCopyWith<$Res> {
  __$$NutritionVersionSummaryImplCopyWithImpl(
      _$NutritionVersionSummaryImpl _value,
      $Res Function(_$NutritionVersionSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of NutritionVersionSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? version = null,
    Object? createdAt = null,
    Object? engineVersion = null,
  }) {
    return _then(_$NutritionVersionSummaryImpl(
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NutritionVersionSummaryImpl implements _NutritionVersionSummary {
  const _$NutritionVersionSummaryImpl(
      {required this.id,
      required this.planId,
      required this.version,
      required this.createdAt,
      required this.engineVersion});

  factory _$NutritionVersionSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionVersionSummaryImplFromJson(json);

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
  String toString() {
    return 'NutritionVersionSummary(id: $id, planId: $planId, version: $version, createdAt: $createdAt, engineVersion: $engineVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionVersionSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.engineVersion, engineVersion) ||
                other.engineVersion == engineVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, planId, version, createdAt, engineVersion);

  /// Create a copy of NutritionVersionSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionVersionSummaryImplCopyWith<_$NutritionVersionSummaryImpl>
      get copyWith => __$$NutritionVersionSummaryImplCopyWithImpl<
          _$NutritionVersionSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionVersionSummaryImplToJson(
      this,
    );
  }
}

abstract class _NutritionVersionSummary implements NutritionVersionSummary {
  const factory _NutritionVersionSummary(
      {required final String id,
      required final String planId,
      required final int version,
      required final String createdAt,
      required final String engineVersion}) = _$NutritionVersionSummaryImpl;

  factory _NutritionVersionSummary.fromJson(Map<String, dynamic> json) =
      _$NutritionVersionSummaryImpl.fromJson;

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

  /// Create a copy of NutritionVersionSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NutritionVersionSummaryImplCopyWith<_$NutritionVersionSummaryImpl>
      get copyWith => throw _privateConstructorUsedError;
}
