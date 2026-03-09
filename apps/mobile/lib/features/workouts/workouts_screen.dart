import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../models/training_plan.dart';
import 'training_plan_provider.dart';
import 'workout_session_provider.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(trainingPlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load training plan'),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => ref.read(trainingPlanProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (plan) {
          if (plan == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center,
                      size: 64, color: AppColors.onSurfaceVariant),
                  const SizedBox(height: AppSpacing.md),
                  const Text('No training plan yet'),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () =>
                        ref.read(trainingPlanProvider.notifier).generate(),
                    child: const Text('Generate Plan'),
                  ),
                ],
              ),
            );
          }

          return _SessionList(plan: plan);
        },
      ),
    );
  }
}

class _SessionList extends ConsumerWidget {
  final TrainingPlan plan;
  const _SessionList({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = plan.version.sessions;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _SessionCard(session: session);
      },
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final TrainingSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutSessionProvider);
    final isActive = workoutState.isActive;

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${session.exercises.length} exercises · ${session.targetDurationMinutes} min',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: session.exercises
                  .map((e) => Chip(
                        label: Text(
                          e.exerciseId.length > 12
                              ? '${e.exerciseId.substring(0, 12)}…'
                              : e.exerciseId,
                          style: const TextStyle(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isActive
                    ? null
                    : () async {
                        final notifier =
                            ref.read(workoutSessionProvider.notifier);
                        final success = await notifier.startWorkout(session);
                        if (success && context.mounted) {
                          context.push('/workout-player');
                        }
                      },
                icon: const Icon(Icons.play_arrow),
                label: Text(isActive ? 'Workout in Progress' : 'Start Workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
