import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../models/exercise.dart';
import '../../models/progress_metrics.dart';
import '../../models/volume_metrics.dart';
import '../workouts/exercise_catalog_provider.dart';
import 'progress_provider.dart';
import 'volume_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressProvider);
    final volumeAsync = ref.watch(volumeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(progressProvider.notifier).refresh(),
            ref.read(volumeProvider.notifier).refresh(),
          ]);
        },
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorView(
            onRetry: () {
              ref.invalidate(progressProvider);
              ref.invalidate(volumeProvider);
            },
          ),
          data: (progress) {
            final volume = volumeAsync.valueOrNull;

            if (progress == null || progress.exercises.isEmpty) {
              return _EmptyView();
            }

            return _LoadedDashboard(progress: progress, volume: volume);
          },
        ),
      ),
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
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off,
                  size: 48, color: AppColors.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
              const Text('Failed to load analytics'),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insights, size: 64, color: AppColors.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
              Text('No progress data yet',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Complete a workout to see your stats',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadedDashboard extends ConsumerWidget {
  final ProgressMetrics progress;
  final VolumeMetrics? volume;

  const _LoadedDashboard({required this.progress, this.volume});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(exerciseCatalogProvider).valueOrNull;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SummaryRow(progress: progress),
        const SizedBox(height: AppSpacing.md),
        _FatigueCard(detected: progress.fatigueDetected),
        const SizedBox(height: AppSpacing.md),
        if (volume != null) ...[
          _VolumeSummaryCard(volume: volume!),
          const SizedBox(height: AppSpacing.md),
        ],
        _ExerciseProgressSection(
          exercises: progress.exercises,
          catalog: catalog,
        ),
      ],
    );
  }
}

// ─── Section 1: Summary Cards ───────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final ProgressMetrics progress;
  const _SummaryRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final adherencePct = progress.adherenceScore != null
        ? '${(progress.adherenceScore! * 100).toStringAsFixed(0)}%'
        : '—';

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.check_circle_outline,
            label: 'Adherence',
            value: adherencePct,
            color: _adherenceColor(progress.adherenceScore),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricCard(
            icon: Icons.fitness_center,
            label: 'Exercises',
            value: '${progress.exercises.length}',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricCard(
            icon: progress.fatigueDetected
                ? Icons.warning_amber
                : Icons.favorite,
            label: 'Fatigue',
            value: progress.fatigueDetected ? 'Yes' : 'No',
            color:
                progress.fatigueDetected ? AppColors.error : AppColors.success,
          ),
        ),
      ],
    );
  }

  Color _adherenceColor(double? score) {
    if (score == null) return AppColors.onSurfaceVariant;
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.5) return AppColors.accent;
    return AppColors.error;
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}

// ─── Section 4: Fatigue Status ──────────────────────────────────────────

class _FatigueCard extends StatelessWidget {
  final bool detected;
  const _FatigueCard({required this.detected});

  @override
  Widget build(BuildContext context) {
    final bgColor = detected
        ? AppColors.error.withOpacity(0.12)
        : AppColors.success.withOpacity(0.12);
    final fgColor = detected ? AppColors.error : AppColors.success;
    final icon =
        detected ? Icons.warning_amber_rounded : Icons.shield_outlined;
    final text = detected
        ? 'Fatigue detected — consider reducing volume or taking a deload.'
        : 'No fatigue detected — you are recovering well.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: fgColor, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: fgColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section 3: Weekly Volume ───────────────────────────────────────────

class _VolumeSummaryCard extends StatelessWidget {
  final VolumeMetrics volume;
  const _VolumeSummaryCard({required this.volume});

  @override
  Widget build(BuildContext context) {
    final totalByExercise =
        volume.byExercise.fold<double>(0, (s, e) => s + e.volume);

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
                  child: _VolumeStatItem(
                    label: 'Total Volume',
                    value: '${totalByExercise.toStringAsFixed(0)} kg',
                  ),
                ),
                Expanded(
                  child: _VolumeStatItem(
                    label: 'Exercises',
                    value: '${volume.byExercise.length}',
                  ),
                ),
                Expanded(
                  child: _VolumeStatItem(
                    label: 'Muscles',
                    value: '${volume.byMuscle.length}',
                  ),
                ),
              ],
            ),
            if (volume.byMuscle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: volume.byMuscle
                    .map((m) => Chip(
                          label: Text(
                            '${m.muscleId}: ${m.volume.toStringAsFixed(0)}',
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

class _VolumeStatItem extends StatelessWidget {
  final String label;
  final String value;
  const _VolumeStatItem({required this.label, required this.value});

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

// ─── Section 2: Exercise Progress ───────────────────────────────────────

class _ExerciseProgressSection extends StatelessWidget {
  final List<ExerciseProgressItem> exercises;
  final Map<String, Exercise>? catalog;

  const _ExerciseProgressSection({
    required this.exercises,
    this.catalog,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: AppColors.accent, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text('Exercise Progress',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...exercises.map((e) => _ExerciseProgressRow(
              exercise: e,
              catalog: catalog,
            )),
      ],
    );
  }
}

class _ExerciseProgressRow extends StatelessWidget {
  final ExerciseProgressItem exercise;
  final Map<String, Exercise>? catalog;

  const _ExerciseProgressRow({required this.exercise, this.catalog});

  @override
  Widget build(BuildContext context) {
    final name = exerciseName(catalog, exercise.exerciseId);
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
                    name,
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
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                        ),
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
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
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
