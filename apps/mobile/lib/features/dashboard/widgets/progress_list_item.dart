import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../dashboard_provider.dart';

class ProgressListItem extends StatelessWidget {
  final ExerciseProgressVM exercise;
  const ProgressListItem({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final trendIcon = _trendIcon(exercise.volumeTrend);
    final trendColor = _trendColor(exercise.volumeTrend);

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (exercise.fatigueScore != null &&
                      exercise.fatigueScore! > 0.5)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Fatigue: ${(exercise.fatigueScore! * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11, color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (exercise.estimated1RM != null)
                    Text(
                      '${exercise.estimated1RM!.toStringAsFixed(1)} kg e1RM',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (exercise.volumeLastWeek != null)
                    Text(
                      '${exercise.volumeLastWeek!.toStringAsFixed(0)} kg vol',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(trendIcon, color: trendColor, size: 22),
          ],
        ),
      ),
    );
  }

  IconData _trendIcon(String? trend) {
    switch (trend) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _trendColor(String? trend) {
    switch (trend) {
      case 'up':
        return AppColors.success;
      case 'down':
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }
}
