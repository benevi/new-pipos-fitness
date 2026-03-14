import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import 'dashboard_provider.dart';
import 'progress_provider.dart';
import 'volume_provider.dart';
import 'widgets/dashboard_summary_card.dart';
import 'widgets/fatigue_banner.dart';
import 'widgets/progress_list_item.dart';
import 'widgets/volume_summary_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressProvider);
    final vm = ref.watch(dashboardProvider);

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
          data: (_) {
            if (vm.isEmpty) return const _EmptyView();
            return _LoadedDashboard(vm: vm);
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
              const Icon(Icons.cloud_off,
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
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insights, size: 64, color: AppColors.onSurfaceVariant),
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

class _LoadedDashboard extends StatelessWidget {
  final DashboardViewModel vm;
  const _LoadedDashboard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SummaryRow(vm: vm),
        const SizedBox(height: AppSpacing.md),
        FatigueBanner(detected: vm.fatigueDetected),
        const SizedBox(height: AppSpacing.md),
        if (vm.totalVolume > 0 || vm.volumeByMuscle.isNotEmpty) ...[
          VolumeSummaryCard(
            totalVolume: vm.totalVolume,
            exerciseCount: vm.exerciseCount,
            muscleCount: vm.muscleCount,
            muscleVolumes: vm.volumeByMuscle,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (vm.exercises.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.accent, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text('Exercise Progress',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...vm.exercises.map((e) => ProgressListItem(exercise: e)),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final DashboardViewModel vm;
  const _SummaryRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    final adherencePct = vm.adherenceScore != null
        ? '${(vm.adherenceScore! * 100).toStringAsFixed(0)}%'
        : '—';

    return Row(
      children: [
        Expanded(
          child: DashboardSummaryCard(
            icon: Icons.check_circle_outline,
            label: 'Adherence',
            value: adherencePct,
            color: _adherenceColor(vm.adherenceScore),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: DashboardSummaryCard(
            icon: Icons.fitness_center,
            label: 'Exercises',
            value: '${vm.exercises.length}',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: DashboardSummaryCard(
            icon: vm.fatigueDetected ? Icons.warning_amber : Icons.favorite,
            label: 'Fatigue',
            value: vm.fatigueDetected ? 'Yes' : 'No',
            color: vm.fatigueDetected ? AppColors.error : AppColors.success,
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
