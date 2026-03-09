import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutrition_plan.freezed.dart';
part 'nutrition_plan.g.dart';

@freezed
class NutritionPlan with _$NutritionPlan {
  const factory NutritionPlan({
    required String id,
    required String userId,
    required String? currentVersionId,
    required NutritionPlanVersion version,
  }) = _NutritionPlan;

  factory NutritionPlan.fromJson(Map<String, dynamic> json) =>
      _$NutritionPlanFromJson(json);
}

@freezed
class NutritionPlanVersion with _$NutritionPlanVersion {
  const factory NutritionPlanVersion({
    required String id,
    required String planId,
    required int version,
    required String createdAt,
    required String engineVersion,
    required List<NutritionDay> days,
  }) = _NutritionPlanVersion;

  factory NutritionPlanVersion.fromJson(Map<String, dynamic> json) =>
      _$NutritionPlanVersionFromJson(json);
}

@freezed
class NutritionDay with _$NutritionDay {
  const factory NutritionDay({
    required String id,
    required int dayIndex,
    required List<NutritionMeal> meals,
  }) = _NutritionDayData;

  factory NutritionDay.fromJson(Map<String, dynamic> json) =>
      _$NutritionDayFromJson(json);
}

@freezed
class NutritionMeal with _$NutritionMeal {
  const factory NutritionMeal({
    required String id,
    required int mealIndex,
    required String name,
    String? templateId,
    required List<NutritionMealItem> items,
  }) = _NutritionMeal;

  factory NutritionMeal.fromJson(Map<String, dynamic> json) =>
      _$NutritionMealFromJson(json);
}

@freezed
class NutritionMealItem with _$NutritionMealItem {
  const factory NutritionMealItem({
    required String id,
    required String foodId,
    required double quantityG,
  }) = _NutritionMealItem;

  factory NutritionMealItem.fromJson(Map<String, dynamic> json) =>
      _$NutritionMealItemFromJson(json);
}
