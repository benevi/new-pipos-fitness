import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../nutrition_view_model_provider.dart';

class MealCard extends StatelessWidget {
  final NutritionMealVM meal;
  final int index;

  const MealCard({super.key, required this.meal, required this.index});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  child: Text(
                    '${index + 1}',
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    meal.name,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${meal.items.length} item${meal.items.length == 1 ? '' : 's'}',
                  style: tt.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            if (meal.items.isNotEmpty) ...[
              const Divider(height: AppSpacing.lg),
              ...meal.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.foodId,
                            style: tt.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.quantityG.toStringAsFixed(0)}g',
                          style: tt.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
