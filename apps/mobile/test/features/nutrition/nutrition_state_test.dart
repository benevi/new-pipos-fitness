import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/nutrition/nutrition_view_model_provider.dart';
import 'package:pipos_fitness/models/nutrition_plan.dart';

void main() {
  group('NutritionViewModel empty-state', () {
    test('isEmpty true by default', () {
      const vm = NutritionViewModel();
      expect(vm.isEmpty, true);
      expect(vm.meals, isEmpty);
    });

    test('isEmpty true when dayCount is 0', () {
      const vm = NutritionViewModel(dayCount: 0);
      expect(vm.isEmpty, true);
    });

    test('not empty when days exist', () {
      const vm = NutritionViewModel(
        isEmpty: false,
        dayCount: 7,
        meals: [NutritionMealVM(name: 'Breakfast', items: [])],
      );
      expect(vm.isEmpty, false);
      expect(vm.dayCount, 7);
    });
  });

  group('NutritionViewModel data composition', () {
    test('selectedDay clamped to valid range', () {
      final plan = _buildPlan(dayCount: 3);
      final vm = _buildVM(plan, selectedDay: 5);
      expect(vm.selectedDay, 2);
    });

    test('selectedDay 0 when plan has days', () {
      final plan = _buildPlan(dayCount: 7);
      final vm = _buildVM(plan, selectedDay: 0);
      expect(vm.selectedDay, 0);
    });

    test('meals populated for selected day', () {
      final plan = _buildPlan(dayCount: 2, mealsPerDay: 3);
      final vm = _buildVM(plan, selectedDay: 1);
      expect(vm.meals.length, 3);
    });

    test('meals empty for day with no meals', () {
      final plan = _buildPlan(dayCount: 2, mealsPerDay: 0);
      final vm = _buildVM(plan, selectedDay: 0);
      expect(vm.meals, isEmpty);
    });

    test('calorie and macro targets propagated', () {
      final plan = _buildPlan(
        dayCount: 1,
        calories: 2200,
        proteinG: 165,
        carbsG: 220,
        fatG: 73,
      );
      final vm = _buildVM(plan, selectedDay: 0);
      expect(vm.dailyCalorieTarget, 2200);
      expect(vm.proteinG, 165);
      expect(vm.carbsG, 220);
      expect(vm.fatG, 73);
    });

    test('calorie and macro targets null when not provided', () {
      final plan = _buildPlan(dayCount: 1);
      final vm = _buildVM(plan, selectedDay: 0);
      expect(vm.dailyCalorieTarget, isNull);
      expect(vm.proteinG, isNull);
    });

    test('versionNumber propagated', () {
      final plan = _buildPlan(dayCount: 1, versionNumber: 3);
      final vm = _buildVM(plan, selectedDay: 0);
      expect(vm.versionNumber, 3);
    });
  });

  group('NutritionPlan model parsing', () {
    test('fromJson full response', () {
      final json = {
        'plan': {
          'id': 'p1',
          'userId': 'u1',
          'currentVersionId': 'v1',
        },
        'version': {
          'id': 'v1',
          'planId': 'p1',
          'version': 2,
          'createdAt': '2026-03-09T00:00:00Z',
          'engineVersion': '0.8.0',
          'dailyCalorieTarget': 2000.0,
          'dailyMacroTarget': {
            'proteinG': 150.0,
            'carbsG': 200.0,
            'fatG': 67.0,
          },
          'days': [
            {
              'id': 'd1',
              'dayIndex': 0,
              'meals': [
                {
                  'id': 'm1',
                  'mealIndex': 0,
                  'name': 'Breakfast',
                  'templateId': null,
                  'items': [
                    {
                      'id': 'i1',
                      'foodId': 'oats',
                      'quantityG': 80.0,
                    },
                  ],
                },
              ],
            },
          ],
        },
      };

      final plan = NutritionPlan.fromJson(json);
      expect(plan.plan.id, 'p1');
      expect(plan.version.version, 2);
      expect(plan.version.dailyCalorieTarget, 2000);
      expect(plan.version.dailyMacroTarget?.proteinG, 150);
      expect(plan.version.days.length, 1);
      expect(plan.version.days.first.meals.first.name, 'Breakfast');
      expect(plan.version.days.first.meals.first.items.first.foodId, 'oats');
    });

    test('fromJson without calorie/macro targets', () {
      final json = {
        'plan': {
          'id': 'p1',
          'userId': 'u1',
          'currentVersionId': 'v1',
        },
        'version': {
          'id': 'v1',
          'planId': 'p1',
          'version': 1,
          'createdAt': '2026-03-09T00:00:00Z',
          'engineVersion': '0.8.0',
          'days': [],
        },
      };

      final plan = NutritionPlan.fromJson(json);
      expect(plan.version.dailyCalorieTarget, isNull);
      expect(plan.version.dailyMacroTarget, isNull);
      expect(plan.version.days, isEmpty);
    });
  });

  group('NutritionVersionSummary parsing', () {
    test('fromJson', () {
      final json = {
        'id': 'v1',
        'planId': 'p1',
        'version': 3,
        'createdAt': '2026-03-09T10:00:00Z',
        'engineVersion': '0.8.1',
      };
      final v = NutritionVersionSummary.fromJson(json);
      expect(v.version, 3);
      expect(v.engineVersion, '0.8.1');
    });
  });

  group('Meal data composition', () {
    test('items mapped correctly', () {
      final plan = _buildPlanWithItems();
      final vm = _buildVM(plan, selectedDay: 0);
      expect(vm.meals.length, 1);
      expect(vm.meals.first.name, 'Breakfast');
      expect(vm.meals.first.items.length, 2);
      expect(vm.meals.first.items[0].foodId, 'eggs');
      expect(vm.meals.first.items[0].quantityG, 120);
      expect(vm.meals.first.items[1].foodId, 'toast');
      expect(vm.meals.first.items[1].quantityG, 60);
    });
  });
}

NutritionPlan _buildPlan({
  int dayCount = 7,
  int mealsPerDay = 3,
  double? calories,
  double? proteinG,
  double? carbsG,
  double? fatG,
  int versionNumber = 1,
}) {
  final days = List.generate(dayCount, (d) {
    final meals = List.generate(mealsPerDay, (m) {
      return NutritionMeal(
        id: 'meal-$d-$m',
        mealIndex: m,
        name: 'Meal ${m + 1}',
        items: [],
      );
    });
    return NutritionDay(id: 'day-$d', dayIndex: d, meals: meals);
  });

  return NutritionPlan(
    plan: const NutritionPlanInfo(
      id: 'p1',
      userId: 'u1',
      currentVersionId: 'v1',
    ),
    version: NutritionPlanVersion(
      id: 'v1',
      planId: 'p1',
      version: versionNumber,
      createdAt: '2026-03-09T00:00:00Z',
      engineVersion: '0.8.0',
      dailyCalorieTarget: calories,
      dailyMacroTarget: (proteinG != null || carbsG != null || fatG != null)
          ? NutritionMacroTarget(
              proteinG: proteinG ?? 0,
              carbsG: carbsG ?? 0,
              fatG: fatG ?? 0,
            )
          : null,
      days: days,
    ),
  );
}

NutritionPlan _buildPlanWithItems() {
  return const NutritionPlan(
    plan: NutritionPlanInfo(
      id: 'p1',
      userId: 'u1',
      currentVersionId: 'v1',
    ),
    version: NutritionPlanVersion(
      id: 'v1',
      planId: 'p1',
      version: 1,
      createdAt: '2026-03-09T00:00:00Z',
      engineVersion: '0.8.0',
      days: [
        const NutritionDay(
          id: 'd1',
          dayIndex: 0,
          meals: [
            NutritionMeal(
              id: 'm1',
              mealIndex: 0,
              name: 'Breakfast',
              items: [
                NutritionMealItem(id: 'i1', foodId: 'eggs', quantityG: 120),
                NutritionMealItem(id: 'i2', foodId: 'toast', quantityG: 60),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

NutritionViewModel _buildVM(NutritionPlan plan, {int selectedDay = 0}) {
  final v = plan.version;
  final days = v.days;
  final clampedDay = selectedDay.clamp(0, (days.length - 1).clamp(0, 999));
  final dayMeals =
      days.isNotEmpty ? days[clampedDay].meals : <NutritionMeal>[];

  return NutritionViewModel(
    isEmpty: days.isEmpty,
    versionNumber: v.version,
    dailyCalorieTarget: v.dailyCalorieTarget,
    proteinG: v.dailyMacroTarget?.proteinG,
    carbsG: v.dailyMacroTarget?.carbsG,
    fatG: v.dailyMacroTarget?.fatG,
    dayCount: days.length,
    selectedDay: clampedDay,
    meals: dayMeals
        .map((m) => NutritionMealVM(
              name: m.name,
              items: m.items
                  .map((i) => NutritionMealItemVM(
                        foodId: i.foodId,
                        quantityG: i.quantityG,
                      ))
                  .toList(),
            ))
        .toList(),
  );
}
