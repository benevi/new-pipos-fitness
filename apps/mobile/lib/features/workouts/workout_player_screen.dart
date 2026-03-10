import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../models/exercise.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';
import 'exercise_catalog_provider.dart';
import 'workout_session_provider.dart';

class WorkoutPlayerScreen extends ConsumerWidget {
  const WorkoutPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workoutSessionProvider);
    final catalog = ref.watch(exerciseCatalogProvider).valueOrNull;

    if (!ws.isActive || ws.session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('No active workout')),
      );
    }

    final exercises = ws.session!.exercises;
    final totalEx = ws.totalExercises;
    final idx = ws.currentExerciseIndex.clamp(0, totalEx > 0 ? totalEx - 1 : 0);

    final planExercise = ws.planSession?.exercises.elementAtOrNull(idx);
    // Match by order for robust lookup, fall back to positional index
    final workoutExercise =
        exercises.where((e) => e.order == idx).firstOrNull ??
            exercises.elementAtOrNull(idx);

    if (workoutExercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${idx + 1} / $totalEx'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context, ref),
        ),
      ),
      body: Column(
        children: [
          if (ws.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              color: AppColors.error.withOpacity(0.2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(ws.error!,
                        style: const TextStyle(color: AppColors.error)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () =>
                        ref.read(workoutSessionProvider.notifier).clearError(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ExerciseHeader(
                    planExercise: planExercise,
                    workoutExercise: workoutExercise,
                    catalog: catalog,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _LoggedSetsList(sets: workoutExercise.sets),
                  const SizedBox(height: AppSpacing.md),
                  _SetInputForm(
                    workoutExerciseId: workoutExercise.id,
                    setIndex: workoutExercise.sets.length,
                    plannedSets: planExercise?.sets ?? 0,
                  ),
                ],
              ),
            ),
          ),
          _BottomBar(
            currentIndex: idx,
            totalExercises: totalEx,
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Workout?'),
        content: const Text(
            'Your logged sets are saved, but the workout will remain unfinished.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(workoutSessionProvider.notifier).reset();
              context.go('/workouts');
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseHeader extends StatelessWidget {
  final TrainingSessionExercise? planExercise;
  final WorkoutExercise workoutExercise;
  final Map<String, Exercise>? catalog;

  const _ExerciseHeader({
    this.planExercise,
    required this.workoutExercise,
    this.catalog,
  });

  @override
  Widget build(BuildContext context) {
    final name = exerciseName(catalog, workoutExercise.exerciseId);

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
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            if (planExercise != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.repeat,
                    label: '${planExercise!.sets} sets',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _InfoChip(
                    icon: Icons.straighten,
                    label:
                        '${planExercise!.repRangeMin}–${planExercise!.repRangeMax} reps',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _InfoChip(
                    icon: Icons.timer,
                    label: '${planExercise!.restSeconds}s rest',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'RIR target: ${planExercise!.rirTarget}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _LoggedSetsList extends StatelessWidget {
  final List<WorkoutSet> sets;
  const _LoggedSetsList({required this.sets});

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) {
      return Text(
        'No sets logged yet',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Logged Sets', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        ...sets.map((s) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '#${s.setIndex + 1}',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${s.weightKg ?? 0} kg × ${s.reps ?? 0} reps'
                      '${s.rir != null ? ' @ RIR ${s.rir}' : ''}',
                    ),
                  ),
                  Icon(
                    s.completed ? Icons.check_circle : Icons.circle_outlined,
                    color: s.completed
                        ? AppColors.success
                        : AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _SetInputForm extends ConsumerStatefulWidget {
  final String workoutExerciseId;
  final int setIndex;
  final int plannedSets;
  const _SetInputForm({
    required this.workoutExerciseId,
    required this.setIndex,
    required this.plannedSets,
  });

  @override
  ConsumerState<_SetInputForm> createState() => _SetInputFormState();
}

class _SetInputFormState extends ConsumerState<_SetInputForm> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _rirController = TextEditingController();
  bool _isLogging = false;

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _rirController.dispose();
    super.dispose();
  }

  Future<void> _logSet() async {
    setState(() => _isLogging = true);

    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);
    final rir = int.tryParse(_rirController.text);

    final success = await ref.read(workoutSessionProvider.notifier).logSet(
          workoutExerciseId: widget.workoutExerciseId,
          weightKg: weight,
          reps: reps,
          rir: rir,
        );

    if (success) {
      _weightController.clear();
      _repsController.clear();
      _rirController.clear();
    }

    if (mounted) setState(() => _isLogging = false);
  }

  @override
  Widget build(BuildContext context) {
    // For resumed workouts without plan data, allow unlimited sets
    final allDone =
        widget.plannedSets > 0 && widget.setIndex >= widget.plannedSets;

    if (allDone) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            const Text('All planned sets completed!'),
          ],
        ),
      );
    }

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.plannedSets > 0
                  ? 'Set ${widget.setIndex + 1} of ${widget.plannedSets}'
                  : 'Set ${widget.setIndex + 1}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    decoration: const InputDecoration(labelText: 'Reps'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _rirController,
                    decoration: const InputDecoration(labelText: 'RIR'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLogging ? null : _logSet,
                child: _isLogging
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log Set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  final int currentIndex;
  final int totalExercises;
  const _BottomBar({
    required this.currentIndex,
    required this.totalExercises,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLast = currentIndex >= totalExercises - 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          top: BorderSide(color: AppColors.onSurfaceVariant.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (currentIndex > 0)
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(workoutSessionProvider.notifier).previousExercise(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Prev'),
              )
            else
              const SizedBox.shrink(),
            const Spacer(),
            if (isLast)
              FilledButton.icon(
                onPressed: () async {
                  final startedAt =
                      ref.read(workoutSessionProvider).session?.startedAt;
                  int? duration;
                  if (startedAt != null) {
                    final start = DateTime.tryParse(startedAt);
                    if (start != null) {
                      duration = DateTime.now().difference(start).inMinutes;
                    }
                  }
                  final success = await ref
                      .read(workoutSessionProvider.notifier)
                      .finishWorkout(durationMinutes: duration);
                  if (success && context.mounted) {
                    context.go('/workout-complete');
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Finish'),
              )
            else
              FilledButton.icon(
                onPressed: () =>
                    ref.read(workoutSessionProvider.notifier).nextExercise(),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
          ],
        ),
      ),
    );
  }
}
