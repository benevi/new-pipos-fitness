import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../dashboard_provider.dart';

class VolumeSummaryCard extends StatelessWidget {
  final double totalVolume;
  final int exerciseCount;
  final int muscleCount;
  final List<MuscleVolumeVM> muscleVolumes;

  const VolumeSummaryCard({
    super.key,
    required this.totalVolume,
    required this.exerciseCount,
    required this.muscleCount,
    required this.muscleVolumes,
  });

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.bar_chart, color: AppColors.accent, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text('Weekly Volume',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Total Volume',
                    value: '${totalVolume.toStringAsFixed(0)} kg',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Exercises',
                    value: '$exerciseCount',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Muscles',
                    value: '$muscleCount',
                  ),
                ),
              ],
            ),
            if (muscleVolumes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: muscleVolumes
                    .map((m) => Chip(
                          label: Text(
                            '${m.displayName}: ${m.volume.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
