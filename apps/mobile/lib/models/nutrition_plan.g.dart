// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NutritionPlanImpl _$$NutritionPlanImplFromJson(Map<String, dynamic> json) =>
    _$NutritionPlanImpl(
      plan: NutritionPlanInfo.fromJson(json['plan'] as Map<String, dynamic>),
      version: NutritionPlanVersion.fromJson(
          json['version'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$NutritionPlanImplToJson(_$NutritionPlanImpl instance) =>
    <String, dynamic>{
      'plan': instance.plan,
      'version': instance.version,
    };

_$NutritionPlanInfoImpl _$$NutritionPlanInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$NutritionPlanInfoImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      currentVersionId: json['currentVersionId'] as String?,
    );

Map<String, dynamic> _$$NutritionPlanInfoImplToJson(
        _$NutritionPlanInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'currentVersionId': instance.currentVersionId,
    };

_$NutritionPlanVersionImpl _$$NutritionPlanVersionImplFromJson(
        Map<String, dynamic> json) =>
    _$NutritionPlanVersionImpl(
      id: json['id'] as String,
      planId: json['planId'] as String,
      version: (json['version'] as num).toInt(),
      createdAt: json['createdAt'] as String,
      engineVersion: json['engineVersion'] as String,
      dailyCalorieTarget: (json['dailyCalorieTarget'] as num?)?.toDouble(),
      dailyMacroTarget: json['dailyMacroTarget'] == null
          ? null
          : NutritionMacroTarget.fromJson(
              json['dailyMacroTarget'] as Map<String, dynamic>),
      days: (json['days'] as List<dynamic>)
          .map((e) => NutritionDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$NutritionPlanVersionImplToJson(
        _$NutritionPlanVersionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'planId': instance.planId,
      'version': instance.version,
      'createdAt': instance.createdAt,
      'engineVersion': instance.engineVersion,
      'dailyCalorieTarget': instance.dailyCalorieTarget,
      'dailyMacroTarget': instance.dailyMacroTarget,
      'days': instance.days,
    };

_$NutritionMacroTargetImpl _$$NutritionMacroTargetImplFromJson(
        Map<String, dynamic> json) =>
    _$NutritionMacroTargetImpl(
      proteinG: (json['proteinG'] as num).toDouble(),
      carbsG: (json['carbsG'] as num).toDouble(),
      fatG: (json['fatG'] as num).toDouble(),
    );

Map<String, dynamic> _$$NutritionMacroTargetImplToJson(
        _$NutritionMacroTargetImpl instance) =>
    <String, dynamic>{
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
    };

_$NutritionDayDataImpl _$$NutritionDayDataImplFromJson(
        Map<String, dynamic> json) =>
    _$NutritionDayDataImpl(
      id: json['id'] as String,
      dayIndex: (json['dayIndex'] as num).toInt(),
      meals: (json['meals'] as List<dynamic>)
          .map((e) => NutritionMeal.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$NutritionDayDataImplToJson(
        _$NutritionDayDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dayIndex': instance.dayIndex,
      'meals': instance.meals,
    };

_$NutritionMealImpl _$$NutritionMealImplFromJson(Map<String, dynamic> json) =>
    _$NutritionMealImpl(
      id: json['id'] as String,
      mealIndex: (json['mealIndex'] as num).toInt(),
      name: json['name'] as String,
      templateId: json['templateId'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => NutritionMealItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$NutritionMealImplToJson(_$NutritionMealImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mealIndex': instance.mealIndex,
      'name': instance.name,
      'templateId': instance.templateId,
      'items': instance.items,
    };

_$NutritionMealItemImpl _$$NutritionMealItemImplFromJson(
        Map<String, dynamic> json) =>
    _$NutritionMealItemImpl(
      id: json['id'] as String,
      foodId: json['foodId'] as String,
      quantityG: (json['quantityG'] as num).toDouble(),
    );

Map<String, dynamic> _$$NutritionMealItemImplToJson(
        _$NutritionMealItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'foodId': instance.foodId,
      'quantityG': instance.quantityG,
    };

_$NutritionVersionSummaryImpl _$$NutritionVersionSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$NutritionVersionSummaryImpl(
      id: json['id'] as String,
      planId: json['planId'] as String,
      version: (json['version'] as num).toInt(),
      createdAt: json['createdAt'] as String,
      engineVersion: json['engineVersion'] as String,
    );

Map<String, dynamic> _$$NutritionVersionSummaryImplToJson(
        _$NutritionVersionSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'planId': instance.planId,
      'version': instance.version,
      'createdAt': instance.createdAt,
      'engineVersion': instance.engineVersion,
    };
