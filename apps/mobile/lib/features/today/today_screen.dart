/// Sesión de hoy (CUJ-2/3/4): calentamiento, objetivo por ejercicio, carga
/// sugerida o «estimación inicial», registro rápido (valores precargados:
/// confirmar una serie es 1 toque), selector de RIR, descanso automático,
/// cambio de ejercicio y fin del entrenamiento. Todo el registro pasa por la
/// cola drift → [SyncService]; funciona en modo avión.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tokens.dart';
import '../../core/api/api_failure.dart';
import '../../core/offline/app_database.dart';
import '../../core/offline/offline_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/enums.dart';
import '../../models/plan.dart';
import '../../models/workout.dart';
import '../../shared/widgets.dart';
import '../setup/setup_provider.dart';
import 'rest_timer_bar.dart';
import 'swap_sheet.dart';
import 'today_providers.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todaySessionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.todayTitle)),
      body: today.when(
        loading: () => const LoadingView(),
        error: (e, _) {
          final f = ApiFailure.from(e);
          return ErrorView(
            error: e,
            message: f.isConnectivity ? l10n.todayOfflineNoData : null,
            onRetry: () => ref.invalidate(todaySessionProvider),
          );
        },
        data: (cached) {
          if (cached == null) {
            return Center(
              child: EmptyState(
                icon: Icons.event_note_outlined,
                title: l10n.todayEmptyTitle,
                body: l10n.todayEmptyBody,
                actionLabel: l10n.todayEmptyAction,
                onAction: () =>
                    ref.read(setupStatusProvider.notifier).requireOnboarding(),
              ),
            );
          }
          return _SessionBody(cached: cached);
        },
      ),
      bottomNavigationBar: const RestTimerBar(),
    );
  }
}

class _SessionBody extends ConsumerStatefulWidget {
  const _SessionBody({required this.cached});

  final Cached<TodaySession> cached;

  @override
  ConsumerState<_SessionBody> createState() => _SessionBodyState();
}

class _SessionBodyState extends ConsumerState<_SessionBody> {
  TodaySession get session => widget.cached.value;

  @override
  void initState() {
    super.initState();
    _adoptServerWorkout();
  }

  @override
  void didUpdateWidget(covariant _SessionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cached.value.workout?.id != session.workout?.id) {
      _adoptServerWorkout();
    }
  }

  /// Si la API ya tiene un entrenamiento en curso, se registra en local con
  /// su mismo `clientId` (las series nuevas se le asocian).
  void _adoptServerWorkout() {
    final w = session.workout;
    if (w == null || w.status != WorkoutStatus.inProgress) return;
    ref
        .read(syncServiceProvider)
        .startWorkout(planSessionId: session.planSessionId, adopt: w);
  }

  Future<LocalWorkout> _ensureWorkout() async {
    final open = ref
        .read(openWorkoutProvider(session.planSessionId))
        .valueOrNull;
    if (open != null) return open;
    return ref
        .read(syncServiceProvider)
        .startWorkout(planSessionId: session.planSessionId);
  }

  Future<void> _logSet(
    TodayExercise exercise,
    int setIndex,
    int reps,
    double load,
    int? rir,
  ) async {
    final workout = await _ensureWorkout();
    await ref
        .read(syncServiceProvider)
        .logSet(
          workoutClientId: workout.clientId,
          planExerciseId: exercise.planExerciseId,
          exerciseId: exercise.exercise.id,
          setIndex: setIndex,
          reps: reps,
          loadKg: load,
          rir: rir,
        );
    HapticFeedback.lightImpact();
    ref.read(restTimerProvider.notifier).start(exercise.restSeconds);
  }

  Future<void> _finish(List<LocalSetLog> local) async {
    final l10n = AppLocalizations.of(context);
    var planned = 0;
    var done = 0;
    var volume = 0.0;
    for (final e in session.exercises) {
      final merged = mergeSets(e, local);
      planned += e.prescription.sets;
      done += merged.length.clamp(0, e.prescription.sets);
      for (final s in merged) {
        volume += s.reps * s.loadKg;
      }
    }
    final remaining = planned - done;
    final unsynced = local
        .where((s) => s.status != SetSyncStatus.synced)
        .length;
    final hasFailed = local.any((s) => s.status == SetSyncStatus.failed);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.todayFinishConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.todayFinishConfirmBody(remaining)),
            if (unsynced > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.todayFinishUnsynced(unsynced),
                key: const Key('finish-unsynced'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          if (hasFailed)
            TextButton(
              key: const Key('finish-retry'),
              onPressed: () {
                ref.read(syncServiceProvider).retryFailed();
                Navigator.of(ctx).pop(false);
              },
              child: Text(l10n.todayFinishRetryNow),
            ),
          FilledButton(
            key: const Key('finish-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.todayFinishConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final workout = await _ensureWorkout();
    await ref.read(syncServiceProvider).finishWorkout(workout.clientId);
    ref.read(restTimerProvider.notifier).skip();
    await ref.read(cacheStoreProvider).remove(CacheKeys.today);
    if (!mounted) return;
    final allSets = await ref
        .read(syncServiceProvider)
        .setsOf(workout.clientId);
    final serverSets = session.exercises
        .expand((e) => e.loggedSets)
        .where((s) => !s.isWarmup)
        .length;
    if (!mounted) return;
    context.go(
      '/workout-complete',
      extra: WorkoutSummary(
        workoutClientId: workout.clientId,
        sets: allSets.where((s) => !s.isWarmup).length + serverSets,
        volumeKg: volume,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final workout = ref
        .watch(openWorkoutProvider(session.planSessionId))
        .valueOrNull;
    final local = workout == null
        ? const <LocalSetLog>[]
        : ref.watch(localSetsProvider(workout.clientId)).valueOrNull ??
              const <LocalSetLog>[];
    final hasLogged =
        local.isNotEmpty ||
        session.exercises.any((e) => e.loggedSets.isNotEmpty);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(todaySessionProvider.future),
      child: ListView(
        key: const Key('today-list'),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (widget.cached.fromCache && widget.cached.savedAt != null)
            NoticeBanner(
              key: const Key('today-cached'),
              text: l10n.cachedDataNotice(
                l10n.dateTime(widget.cached.savedAt!),
              ),
              icon: Icons.cloud_off_outlined,
            ),
          for (final c
              in ref.watch(conflictingWorkoutsProvider).valueOrNull ??
                  const <LocalWorkout>[])
            _ConflictBanner(workout: c),
          Semantics(
            header: true,
            child: Text(session.name, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.todaySessionMeta(
              session.estimatedMinutes.round(),
              session.exercises.length,
            ),
            style: theme.textTheme.bodyMedium,
          ),
          RationaleExpander(lines: session.rationale),
          if (session.generalWarmupMinutes > 0)
            NoticeBanner(
              text: l10n.todayGeneralWarmup(
                session.generalWarmupMinutes.round(),
              ),
              icon: Icons.directions_walk,
            ),
          if (!hasLogged) NoticeBanner(text: l10n.todayStartHint),
          for (final e in session.exercises)
            ExerciseCard(
              key: Key('exercise-${e.planExerciseId}'),
              exercise: e,
              logged: mergeSets(e, local),
              onLog: (index, reps, load, rir) =>
                  _logSet(e, index, reps, load, rir),
              onSwap: () => showSwapSheet(
                context,
                exercise: e,
                planSessionId: session.planSessionId,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('finish-workout'),
            onPressed: hasLogged ? () => _finish(local) : null,
            icon: const Icon(Icons.flag_outlined),
            label: Text(l10n.todayFinish),
          ),
          const SizedBox(height: AppSpacing.md),
          NoticeBanner(
            text: l10n.medicalNotice,
            icon: Icons.health_and_safety_outlined,
          ),
        ],
      ),
    );
  }
}

/// Entrenamiento local que la API no deja empezar porque hay otro en curso
/// en la cuenta: explica qué pasa y ofrece reintentar o descartar.
class _ConflictBanner extends ConsumerWidget {
  const _ConflictBanner({required this.workout});

  final LocalWorkout workout;

  Future<void> _discard(BuildContext context, WidgetRef ref, int count) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.todayConflictDiscardTitle),
        content: Text(l10n.todayConflictDiscardBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('conflict-discard-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.todayConflictDiscard),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(syncServiceProvider).discardWorkout(workout.clientId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count =
        ref.watch(localSetsProvider(workout.clientId)).valueOrNull?.length ?? 0;
    return Container(
      key: Key('workout-conflict-${workout.clientId}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.ms),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.todayConflictBody(count),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              TextButton(
                key: const Key('conflict-retry'),
                onPressed: () => ref.read(syncServiceProvider).retryFailed(),
                child: Text(l10n.syncRetry),
              ),
              TextButton(
                key: const Key('conflict-discard'),
                onPressed: () => _discard(context, ref, count),
                child: Text(l10n.todayConflictDiscard),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

typedef LogSetCallback =
    Future<void> Function(int setIndex, int reps, double loadKg, int? rir);

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.logged,
    required this.onLog,
    required this.onSwap,
  });

  final TodayExercise exercise;
  final List<LoggedSetView> logged;
  final LogSetCallback onLog;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = exercise.prescription;
    final weighted = exercise.loadType == LoadType.weighted;
    final noLoad = weighted && p.loadKg == null;
    final total = p.sets > logged.length ? p.sets : logged.length;
    final done = logged.length >= p.sets;

    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          exercise.exercise.nameEs,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      if (exercise.substitutedFrom != null)
                        Text(
                          l10n.todaySubstitutedFrom(
                            exercise.substitutedFrom!.nameEs,
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('swap-${exercise.planExerciseId}'),
                  tooltip: l10n.todaySwap,
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: onSwap,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.todayTarget(p.sets, p.repMin, p.repMax, p.targetRir),
              style: theme.textTheme.titleMedium,
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!weighted)
                  Text(l10n.loadBodyweight, style: theme.textTheme.bodyMedium)
                else if (p.loadKg != null)
                  Text(
                    l10n.todaySuggestedLoad(l10n.kg(p.loadKg!)),
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  Chip(
                    key: Key('estimate-${exercise.planExerciseId}'),
                    avatar: const Icon(Icons.tune),
                    label: Text(l10n.todayInitialEstimate),
                  ),
                if (p.isDeload) Chip(label: Text(l10n.todayDeload)),
                Text(
                  l10n.todayRest(exercise.restSeconds),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (noLoad)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.todayInitialEstimateHelp(p.targetRir),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.progressionLabel(p.action.wire),
                style: theme.textTheme.labelLarge,
              ),
            ),
            RationaleExpander(lines: [...p.rationale, ...exercise.cuesEs]),
            if (exercise.warmupSets.isNotEmpty)
              _WarmupList(sets: exercise.warmupSets),
            const Divider(),
            for (var i = 0; i < total; i++)
              if (i < logged.length)
                _LoggedSetRow(index: i, set: logged[i])
              else if (i == logged.length)
                ActiveSetRow(
                  key: Key('active-${exercise.planExerciseId}-$i'),
                  planExerciseId: exercise.planExerciseId,
                  index: i,
                  weighted: weighted,
                  initialReps: logged.isNotEmpty ? logged.last.reps : p.repMin,
                  initialLoad: logged.isNotEmpty
                      ? logged.last.loadKg
                      : (weighted ? p.loadKg : 0),
                  initialRir: logged.isNotEmpty
                      ? (logged.last.rir ?? p.targetRir)
                      : p.targetRir,
                  onConfirm: (reps, load, rir) => onLog(i, reps, load, rir),
                )
              else
                _UpcomingSetRow(index: i),
            if (done)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.todayExerciseDone,
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WarmupList extends StatelessWidget {
  const _WarmupList({required this.sets});

  final List<WarmupSet> sets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.todayWarmupSets, style: theme.textTheme.titleSmall),
        for (final w in sets)
          Text(
            l10n.todayWarmupSet(
              w.reps,
              w.loadKg != null
                  ? l10n.kg(w.loadKg!)
                  : w.loadPct != null
                  ? l10n.loadPctValue(l10n.number(w.loadPct!, maxDecimals: 0))
                  : l10n.loadBodyweight,
            ),
            style: theme.textTheme.bodyMedium,
          ),
      ],
    );
  }
}

class _LoggedSetRow extends ConsumerWidget {
  const _LoggedSetRow({required this.index, required this.set});

  final int index;
  final LoggedSetView set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (icon, label, color) = switch (set.status) {
      SetSyncStatus.synced => (
        Icons.cloud_done_outlined,
        l10n.syncStatusSynced,
        theme.colorScheme.primary,
      ),
      SetSyncStatus.failed => (
        Icons.error_outline,
        l10n.syncStatusFailed,
        theme.colorScheme.error,
      ),
      _ => (
        Icons.cloud_upload_outlined,
        l10n.syncStatusPending,
        theme.colorScheme.onSurfaceVariant,
      ),
    };
    final summary = l10n.todaySetDone(
      set.reps,
      l10n.kg(set.loadKg),
      set.rir == null ? '–' : '${set.rir}',
    );
    return Semantics(
      label: '${l10n.todaySetLabel(index + 1)}: $summary. $label',
      excludeSemantics: set.status != SetSyncStatus.failed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
        child: Row(
          children: [
            SizedBox(
              width: AppSpacing.xxl + AppSpacing.md,
              child: Text(
                l10n.todaySetLabel(index + 1),
                style: theme.textTheme.labelLarge,
              ),
            ),
            Expanded(child: Text(summary, style: theme.textTheme.bodyLarge)),
            if (set.status == SetSyncStatus.failed)
              IconButton(
                tooltip: l10n.syncRetry,
                icon: Icon(icon, color: color),
                onPressed: () => ref.read(syncServiceProvider).retryFailed(),
              )
            else
              Tooltip(
                message: label,
                child: Icon(
                  icon,
                  color: color,
                  key: Key('sync-${set.clientId}-${set.status.name}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingSetRow extends StatelessWidget {
  const _UpcomingSetRow({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          AppLocalizations.of(context).todaySetLabel(index + 1),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Serie siguiente, precargada: confirmar = 1 toque; ajustar reps/kg con el
/// teclado numérico o el RIR con su selector.
class ActiveSetRow extends StatefulWidget {
  const ActiveSetRow({
    super.key,
    required this.planExerciseId,
    required this.index,
    required this.weighted,
    required this.initialReps,
    required this.initialLoad,
    required this.initialRir,
    required this.onConfirm,
  });

  final String planExerciseId;
  final int index;
  final bool weighted;
  final int initialReps;
  final double? initialLoad;
  final int initialRir;
  final Future<void> Function(int reps, double load, int? rir) onConfirm;

  @override
  State<ActiveSetRow> createState() => _ActiveSetRowState();
}

class _ActiveSetRowState extends State<ActiveSetRow> {
  late final _reps = TextEditingController(text: '${widget.initialReps}');
  late final _load = TextEditingController(
    text: widget.initialLoad == null ? '' : _fmt(widget.initialLoad!),
  );
  late int _rir = widget.initialRir;
  String? _repsError;
  String? _loadError;
  bool _busy = false;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  @override
  void dispose() {
    _reps.dispose();
    _load.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final reps = int.tryParse(_reps.text.trim());
    final load = widget.weighted
        ? double.tryParse(_load.text.trim().replaceAll(',', '.'))
        : 0.0;
    setState(() {
      _repsError = reps == null || reps < 0 || reps > 100
          ? l10n.validationRange('0', '100')
          : null;
      _loadError = load == null || load < 0 || load > 1000
          ? l10n.validationRange('0', '1000')
          : null;
    });
    if (_repsError != null || _loadError != null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.onConfirm(reps!, load!, _rir);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickRir() async {
    final picked = await showRirPicker(context, _rir);
    if (picked != null && mounted) setState(() => _rir = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.planExerciseId;
    final setLabel = l10n.todaySetLabel(widget.index + 1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(setLabel, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: Key('reps-$id'),
                  controller: _reps,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.fieldReps,
                    errorText: _repsError,
                    errorMaxLines: 2,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (widget.weighted) ...[
                Expanded(
                  child: TextField(
                    key: Key('load-$id'),
                    controller: _load,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: l10n.fieldLoad,
                      errorText: _loadError,
                      errorMaxLines: 2,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.xxl + AppSpacing.sm,
                ),
                child: OutlinedButton(
                  key: Key('rir-$id'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      AppSpacing.xxl,
                      AppSpacing.xxl + AppSpacing.sm,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                  ),
                  onPressed: _pickRir,
                  child: Text(l10n.rirValue(_rir)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                key: Key('confirm-$id'),
                tooltip: l10n.todayConfirmSet(widget.index + 1),
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.xxl + AppSpacing.sm,
                  minHeight: AppSpacing.xxl + AppSpacing.sm,
                ),
                onPressed: _busy ? null : _confirm,
                icon: const Icon(Icons.check),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Selector de RIR (0–5) como hoja inferior con botones grandes.
Future<int?> showRirPicker(BuildContext context, int current) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.rirPickerTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.rirPickerHelp, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var r = 0; r <= 5; r++)
                    ChoiceChip(
                      key: Key('rir-option-$r'),
                      label: Text(l10n.rirValue(r)),
                      selected: r == current,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: (_) => Navigator.of(ctx).pop(r),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
