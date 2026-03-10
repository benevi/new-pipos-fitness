import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../models/training_plan.dart';
import 'exercise_catalog_provider.dart';
import 'training_plan_provider.dart';
import 'workout_session_provider.dart';

class WorkoutsScreen extends ConsumerStatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen> {
  bool _resumeChecked = false;

  @override
  void initState() {
    super.initState();
    _checkResume();
  }

  Future<void> _checkResume() async {
    if (_resumeChecked) return;
    _resumeChecked = true;

    final ws = ref.read(workoutSessionProvider);
    if (ws.isActive) return;

    final active = await ref
        .read(workoutSessionProvider.notifier)
        .checkForActiveWorkout();

    if (active != null && mounted) {
      final shouldResume = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Resume Workout?'),
          content: const Text(
            'You have an unfinished workout session. Would you like to resume it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Resume'),
            ),
          ],
        ),
      );

      if (shouldResume == true && mounted) {
        final success = await ref
            .read(workoutSessionProvider.notifier)
            .resumeWorkout(active.id);
        if (success && mounted) {
          context.push('/workout-player');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () =>
                    ref.read(trainingPlanProvider.notifier).refresh(),
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
    final catalog = ref.watch(exerciseCatalogProvider).valueOrNull;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _SessionCard(session: session, catalog: catalog);
      },
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final TrainingSession session;
  final Map<String, dynamic>? catalog;
  const _SessionCard({required this.session, this.catalog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutSessionProvider);
    final isBusy = workoutState.isActive || workoutState.isStarting;
    final catalogMap = ref.watch(exerciseCatalogProvider).valueOrNull;

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
                  .map((e) {
                    final name = exerciseName(catalogMap, e.exerciseId);
                    final display = name.length > 16
                        ? '${name.substring(0, 16)}…'
                        : name;
                    return Chip(
                      label: Text(display, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            if (workoutState.status == WorkoutStatus.error &&
                workoutState.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutState.error!,
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                    if (workoutState.session != null &&
                        workoutState.planSession != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: TextButton(
                          onPressed: () async {
                            final notifier =
                                ref.read(workoutSessionProvider.notifier);
                            final success =
                                await notifier.retryAddExercises();
                            if (success && context.mounted) {
                              context.push('/workout-player');
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isBusy
                    ? null
                    : () async {
                        final notifier =
                            ref.read(workoutSessionProvider.notifier);
                        final success = await notifier.startWorkout(session);
                        if (success && context.mounted) {
                          context.push('/workout-player');
                        }
                      },
                icon: workoutState.isStarting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  workoutState.isStarting
                      ? 'Starting…'
                      : workoutState.isActive
                          ? 'Workout in Progress'
                          : 'Start Workout',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
