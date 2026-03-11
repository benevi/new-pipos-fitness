import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/nutrition_plan.dart';
import 'nutrition_plan_provider.dart';
import 'nutrition_versions_provider.dart';

class NutritionViewModel {
  final bool isEmpty;
  final int? versionNumber;
  final double? dailyCalorieTarget;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final int dayCount;
  final int selectedDay;
  final List<NutritionMealVM> meals;
  final List<NutritionVersionSummary> versions;

  const NutritionViewModel({
    this.isEmpty = true,
    this.versionNumber,
    this.dailyCalorieTarget,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.dayCount = 0,
    this.selectedDay = 0,
    this.meals = const [],
    this.versions = const [],
  });
}

class NutritionMealVM {
  final String name;
  final List<NutritionMealItemVM> items;

  const NutritionMealVM({required this.name, required this.items});
}

class NutritionMealItemVM {
  final String foodId;
  final double quantityG;

  const NutritionMealItemVM({required this.foodId, required this.quantityG});
}

final selectedDayProvider = StateProvider<int>((ref) => 0);

final nutritionViewModelProvider = Provider<NutritionViewModel>((ref) {
  final plan = ref.watch(nutritionPlanProvider).valueOrNull;
  final versions = ref.watch(nutritionVersionsProvider).valueOrNull ?? [];
  final selectedDay = ref.watch(selectedDayProvider);

  if (plan == null) return const NutritionViewModel();

  final v = plan.version;
  final days = v.days;

  final clampedDay = selectedDay.clamp(0, (days.length - 1).clamp(0, 999));
  final dayMeals = days.isNotEmpty ? days[clampedDay].meals : <NutritionMeal>[];

  return NutritionViewModel(
    isEmpty: days.isEmpty,
    versionNumber: v.version,
    dailyCalorieTarget: v.dailyCalorieTarget,
    proteinG: v.dailyMacroTarget?.proteinG,
    carbsG: v.dailyMacroTarget?.carbsG,
    fatG: v.dailyMacroTarget?.fatG,
    dayCount: days.length,
    selectedDay: clampedDay,
    meals: dayMeals.map((m) {
      return NutritionMealVM(
        name: m.name,
        items: m.items
            .map((i) => NutritionMealItemVM(
                  foodId: i.foodId,
                  quantityG: i.quantityG,
                ))
            .toList(),
      );
    }).toList(),
    versions: versions,
  );
});
