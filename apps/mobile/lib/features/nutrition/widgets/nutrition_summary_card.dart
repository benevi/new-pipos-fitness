import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class NutritionSummaryCard extends StatelessWidget {
  final double? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final int? versionNumber;

  const NutritionSummaryCard({
    super.key,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.versionNumber,
  });

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
                const Icon(Icons.restaurant_menu,
                    color: AppColors.accent, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text('Daily Targets', style: tt.titleMedium),
                const Spacer(),
                if (versionNumber != null)
                  Text(
                    'v$versionNumber',
                    style: tt.bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (calories != null)
              _CalorieRow(calories: calories!)
            else
              Text('Calorie target not available',
                  style:
                      tt.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _MacroItem(
                    label: 'Protein', value: proteinG, unit: 'g', color: const Color(0xFF4FC3F7)),
                const SizedBox(width: AppSpacing.sm),
                _MacroItem(
                    label: 'Carbs', value: carbsG, unit: 'g', color: const Color(0xFFFFB74D)),
                const SizedBox(width: AppSpacing.sm),
                _MacroItem(
                    label: 'Fat', value: fatG, unit: 'g', color: const Color(0xFFE57373)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieRow extends StatelessWidget {
  final double calories;
  const _CalorieRow({required this.calories});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          calories.toStringAsFixed(0),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 4),
        Text(
          'kcal',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final Color color;

  const _MacroItem({
    required this.label,
    this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            Text(
              value != null ? '${value!.toStringAsFixed(0)}$unit' : '--',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style:
                    tt.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
