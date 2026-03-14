import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import 'workout_session_provider.dart';

class WorkoutCompleteScreen extends ConsumerWidget {
  const WorkoutCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workoutSessionProvider);
    final session = ws.session;

    final totalSets = session?.exercises
            .fold<int>(0, (sum, e) => sum + e.sets.length) ??
        0;
    final totalExercises = session?.exercises.length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Workout Complete!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  ws.planSession?.name ?? 'Session',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(
                      label: 'Exercises',
                      value: '$totalExercises',
                      icon: Icons.fitness_center,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _StatChip(
                      label: 'Sets',
                      value: '$totalSets',
                      icon: Icons.repeat,
                    ),
                    if (session?.durationMinutes != null) ...[
                      const SizedBox(width: AppSpacing.lg),
                      _StatChip(
                        label: 'Minutes',
                        value: '${session!.durationMinutes}',
                        icon: Icons.timer,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ref.read(workoutSessionProvider.notifier).reset();
                      context.go('/dashboard');
                    },
                    child: const Text('Back to Dashboard'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 28),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
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
