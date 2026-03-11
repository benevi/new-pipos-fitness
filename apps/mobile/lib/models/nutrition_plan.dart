import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutrition_plan.freezed.dart';
part 'nutrition_plan.g.dart';

/// Top-level response from GET /nutrition-plans/current and POST /nutrition-plans/generate.
@freezed
class NutritionPlan with _$NutritionPlan {
  const factory NutritionPlan({
    required NutritionPlanInfo plan,
    required NutritionPlanVersion version,
  }) = _NutritionPlan;

  factory NutritionPlan.fromJson(Map<String, dynamic> json) =>
      _$NutritionPlanFromJson(json);
}

@freezed
class NutritionPlanInfo with _$NutritionPlanInfo {
  const factory NutritionPlanInfo({
    required String id,
    required String userId,
    String? currentVersionId,
  }) = _NutritionPlanInfo;

  factory NutritionPlanInfo.fromJson(Map<String, dynamic> json) =>
      _$NutritionPlanInfoFromJson(json);
}

@freezed
class NutritionPlanVersion with _$NutritionPlanVersion {
  const factory NutritionPlanVersion({
    required String id,
    required String planId,
    required int version,
    required String createdAt,
    required String engineVersion,
    double? dailyCalorieTarget,
    NutritionMacroTarget? dailyMacroTarget,
    required List<NutritionDay> days,
  }) = _NutritionPlanVersion;

  factory NutritionPlanVersion.fromJson(Map<String, dynamic> json) =>
      _$NutritionPlanVersionFromJson(json);
}

@freezed
class NutritionMacroTarget with _$NutritionMacroTarget {
  const factory NutritionMacroTarget({
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) = _NutritionMacroTarget;

  factory NutritionMacroTarget.fromJson(Map<String, dynamic> json) =>
      _$NutritionMacroTargetFromJson(json);
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

/// Lightweight version summary from GET /nutrition-plans/versions.
@freezed
class NutritionVersionSummary with _$NutritionVersionSummary {
  const factory NutritionVersionSummary({
    required String id,
    required String planId,
    required int version,
    required String createdAt,
    required String engineVersion,
  }) = _NutritionVersionSummary;

  factory NutritionVersionSummary.fromJson(Map<String, dynamic> json) =>
      _$NutritionVersionSummaryFromJson(json);
}
