import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import 'food_catalog_provider.dart';
import 'nutrition_plan_provider.dart';
import 'nutrition_versions_provider.dart';
import 'nutrition_view_model_provider.dart';
import 'widgets/day_selector.dart';
import 'widgets/meal_card.dart';
import 'widgets/nutrition_summary_card.dart';
import 'widgets/nutrition_versions_sheet.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(nutritionPlanProvider);
    final vm = ref.watch(nutritionViewModelProvider);

    ref.read(foodCatalogProvider.notifier).refreshIfStale();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          if (vm.versions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Plan versions',
              onPressed: () =>
                  NutritionVersionsSheet.show(context, vm.versions),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(nutritionPlanProvider.notifier).refresh(),
            ref.read(nutritionVersionsProvider.notifier).refresh(),
            ref.read(foodCatalogProvider.notifier).refresh(),
          ]);
        },
        child: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorView(
            onRetry: () {
              ref.invalidate(nutritionPlanProvider);
              ref.invalidate(nutritionVersionsProvider);
            },
          ),
          data: (plan) {
            if (plan == null || vm.isEmpty) return const _EmptyView();
            return _LoadedNutrition(vm: vm);
          },
        ),
      ),
    );
  }
}

class _LoadedNutrition extends ConsumerWidget {
  final NutritionViewModel vm;
  const _LoadedNutrition({required this.vm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        NutritionSummaryCard(
          calories: vm.dailyCalorieTarget,
          proteinG: vm.proteinG,
          carbsG: vm.carbsG,
          fatG: vm.fatG,
          versionNumber: vm.versionNumber,
        ),
        const SizedBox(height: AppSpacing.md),
        DaySelector(
          dayCount: vm.dayCount,
          selectedDay: vm.selectedDay,
          onDaySelected: (day) =>
              ref.read(selectedDayProvider.notifier).state = day,
        ),
        const SizedBox(height: AppSpacing.md),
        if (vm.meals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                'No meals for this day',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          )
        else
          ...vm.meals.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: MealCard(meal: e.value, index: e.key),
                ),
              ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.restaurant_outlined,
            size: 64, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            'No nutrition plan yet',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            'Generate a plan from your profile to get started.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            'Failed to load nutrition plan',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.error),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
