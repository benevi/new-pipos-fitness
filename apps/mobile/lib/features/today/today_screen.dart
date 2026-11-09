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
import '../../core/offline/sync_service.dart' show PendingSwap;
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/enums.dart';
import '../../models/notes_breaks.dart' show parseCalendarDate;

import '../../models/plan.dart';
import '../../models/workout.dart';
import '../../shared/decimal_input.dart';
import '../../shared/widgets.dart';
import '../setup/setup_provider.dart';
import 'adjust_sheet.dart';
import 'edit_set_sheet.dart';
import 'note_sheet.dart';
import 'plates.dart';
import 'rest_timer_bar.dart';
import '../plan/plan_providers.dart';
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
        .startWorkout(
          planSessionId: session.planSessionId,
          adjustment:
              ref.read(todayAdjustmentProvider) ?? session.adjustment?.request,
        );
  }

  Future<void> _logSet(
    TodayExercise exercise,
    int setIndex,
    int reps,
    double load,
    int? rir,
  ) async {
    final LocalWorkout workout;
    try {
      workout = await _ensureWorkout();
    } on StateError {
      // Sin usuario conocido (sesión offline sin datos cacheados) no hay
      // cola a la que asociar la serie.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).todayNoUserOffline),
          ),
        );
      }
      return;
    }
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

  /// Id local de la serie; si solo está en la API, se adopta antes en drift.
  Future<String> _localSetId(LoggedSetView set) async {
    final server = set.server;
    if (server != null) {
      final workout = await _ensureWorkout();
      await ref
          .read(syncServiceProvider)
          .adoptServerSet(workout.clientId, server);
    }
    return set.clientId;
  }

  Future<void> _editSet(
    LoggedSetView set,
    int reps,
    double loadKg,
    int? rir,
  ) async {
    final id = await _localSetId(set);
    await ref
        .read(syncServiceProvider)
        .updateSet(id, reps: reps, loadKg: loadKg, rir: rir);
  }

  Future<void> _deleteSet(LoggedSetView set) async {
    final id = await _localSetId(set);
    await ref.read(syncServiceProvider).deleteSet(id);
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
        sets:
            visibleSets(allSets).where((s) => !s.isWarmup).length + serverSets,
        volumeKg: volume,
      ),
    );
  }

  /// «Abandonar entrenamiento» (issue #13): pide confirmación, cierra el
  /// entrenamiento en local (la cola envía el abandono, también sin red) y
  /// deja Hoy limpio, también en la copia guardada para el modo avión.
  Future<void> _abandon(LocalWorkout? local) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.todayAbandonTitle),
        content: Text(l10n.todayAbandonBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('abandon-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.todayAbandon),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final workout = local ?? await _ensureWorkout();
    await ref.read(syncServiceProvider).abandonWorkout(workout.clientId);
    ref.read(restTimerProvider.notifier).skip();
    final json = session.toJson()
      ..['workout'] = null
      ..['exercises'] = [
        for (final e in session.exercises) {...e.toJson(), 'loggedSets': []},
      ];
    await ref.read(cacheStoreProvider).write(CacheKeys.today, json);
    ref.invalidate(todaySessionProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.todayAbandoned)));
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
        visibleSets(local).isNotEmpty ||
        session.exercises.any((e) => e.loggedSets.isNotEmpty);
    final pendingNotes =
        ref.watch(pendingNotesProvider).valueOrNull ??
        const <String, String?>{};
    // Cambios de ejercicio en cola (#23): se ven al momento; al confirmarse
    // se relee la sesión (carga y discos del sustituto).
    final swaps =
        ref.watch(pendingSwapsProvider).valueOrNull ?? const <PendingSwap>[];
    final exercises = applyPendingSwaps(
      session.exercises,
      swaps,
      workout?.clientId,
    );
    // El plan cambió mientras el inicio esperaba en la cola: se relee la
    // sesión vigente (y el plan).
    ref.listen(planOutdatedProvider, (_, next) {
      if (next.hasValue) {
        ref.invalidate(todaySessionProvider);
        ref.invalidate(currentPlanProvider);
      }
    });
    ref.listen(pendingSwapsProvider, (prev, next) {
      final before = prev?.valueOrNull?.map((s) => s.key).toSet() ?? {};
      final now = next.valueOrNull?.map((s) => s.key).toSet() ?? {};
      if (before.any((k) => !now.contains(k))) {
        ref.invalidate(todaySessionProvider);
      }
    });
    // Una nota que deja de estar pendiente ya está en la API: se relee la
    // sesión para mostrar la versión del servidor.
    ref.listen(pendingNotesProvider, (prev, next) {
      final before = prev?.valueOrNull?.keys ?? const <String>[];
      final now = next.valueOrNull?.keys.toSet() ?? const <String>{};
      if (before.any((k) => !now.contains(k))) {
        ref.invalidate(todaySessionProvider);
      }
    });

    return RefreshIndicator(
      onRefresh: () => ref.refresh(todaySessionProvider.future),
      child: ListView(
        key: const Key('today-list'),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (widget.cached.isStale && widget.cached.savedAt != null)
            NoticeBanner(
              key: const Key('today-stale'),
              text: l10n.todayStaleSession(
                l10n.shortDate(widget.cached.savedAt!),
              ),
              icon: Icons.history,
            )
          else if (widget.cached.fromCache && widget.cached.savedAt != null)
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
          for (final c
              in ref.watch(closedRemotelyProvider).valueOrNull ??
                  const <LocalWorkout>[])
            _ClosedRemotelyBanner(workout: c),
          if (session.activeBreak != null)
            NoticeBanner(
              key: const Key('today-break'),
              text: l10n.todayBreakNotice(
                l10n.shortDate(parseCalendarDate(session.activeBreak!.endsOn)),
              ),
              icon: Icons.beach_access_outlined,
            )
          else if (!session.scheduledToday)
            NoticeBanner(
              key: const Key('today-rest-day'),
              text: l10n.todayRestDayNotice,
              icon: Icons.bedtime_outlined,
            ),
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
          if (session.adjustment != null)
            AdjustmentBanner(
              adjustment: session.adjustment!,
              canRemove:
                  !hasLogged &&
                  session.workout == null &&
                  session.adjustment!.source == 'query',
            )
          else if (!hasLogged && session.workout == null)
            // Hueco bajo el botón antes del siguiente aviso.
            Padding(
              key: const Key('adjust-gap'),
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('adjust-open'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
                  ),
                  onPressed: () => showAdjustSheet(context),
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(l10n.adjustOpen),
                ),
              ),
            ),

          if (session.generalWarmupMinutes > 0)
            NoticeBanner(
              text: l10n.todayGeneralWarmup(
                session.generalWarmupMinutes.round(),
              ),
              icon: Icons.directions_walk,
            ),
          if (!hasLogged) NoticeBanner(text: l10n.todayStartHint),
          for (final e in exercises)
            ExerciseCard(
              key: Key('exercise-${e.planExerciseId}'),
              exercise: e,
              swapPending: swaps.any(
                (s) =>
                    !s.failed &&
                    s.workoutClientId == workout?.clientId &&
                    s.planExerciseId == e.planExerciseId,
              ),
              note: pendingNotes.containsKey(e.exercise.id)
                  ? pendingNotes[e.exercise.id]
                  : e.note,
              notePending: pendingNotes.containsKey(e.exercise.id),
              onEditNote: (current) => showNoteSheet(
                context,
                exerciseId: e.exercise.id,
                exerciseName: e.exercise.nameEs,
                current: current,
              ),
              logged: mergeSets(e, local),
              onLog: (index, reps, load, rir) =>
                  _logSet(e, index, reps, load, rir),
              onEditSet: _editSet,
              onDeleteSet: _deleteSet,
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
          if (workout != null ||
              session.workout?.status == WorkoutStatus.inProgress)
            Align(
              child: TextButton.icon(
                key: const Key('abandon-workout'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
                ),
                onPressed: () => _abandon(workout),
                icon: const Icon(Icons.close),
                label: Text(l10n.todayAbandon),
              ),
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
    final outdated = workout.lastError == ApiErrorCode.planSessionOutdated;
    final theme = Theme.of(context);
    final count = visibleSets(
      ref.watch(localSetsProvider(workout.clientId)).valueOrNull ?? const [],
    ).length;
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
            outdated
                ? l10n.todayPlanOutdatedBody(count)
                : l10n.todayConflictBody(count),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              // Con un plan nuevo, reintentar no sirve: sus series son de
              // la sesión antigua. Se conserva en el móvil hasta descartarlo.
              if (!outdated)
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

/// El servidor cerró un entrenamiento que la persona no había terminado
/// (abandono automático tras 12 h sin actividad, o terminado en otro
/// dispositivo): se explica qué series no se subieron.
class _ClosedRemotelyBanner extends ConsumerWidget {
  const _ClosedRemotelyBanner({required this.workout});

  final LocalWorkout workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lost =
        (ref.watch(localSetsProvider(workout.clientId)).valueOrNull ??
                const <LocalSetLog>[])
            .where((s) => !s.confirmed && !s.deleted)
            .length;
    return Padding(
      key: Key('workout-closed-${workout.clientId}'),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NoticeBanner(
            text: l10n.todayClosedRemotely(lost),
            icon: Icons.info_outline,
          ),
          TextButton(
            key: const Key('workout-closed-dismiss'),
            onPressed: () => ref
                .read(syncServiceProvider)
                .dismissClosedNotice(workout.clientId),
            child: Text(l10n.actionUnderstood),
          ),
        ],
      ),
    );
  }
}

typedef LogSetCallback =
    Future<void> Function(int setIndex, int reps, double loadKg, int? rir);

typedef EditSetCallback =
    Future<void> Function(LoggedSetView set, int reps, double loadKg, int? rir);

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.logged,
    required this.onLog,
    required this.onSwap,
    this.note,
    this.notePending = false,
    this.onEditNote,
    this.onEditSet,
    this.onDeleteSet,
    this.swapPending = false,
  });

  /// Cambio de ejercicio guardado en la cola sin confirmar (#23).
  final bool swapPending;

  final TodayExercise exercise;
  final List<LoggedSetView> logged;
  final LogSetCallback onLog;
  final VoidCallback onSwap;

  /// Corregir o borrar una serie registrada (#22).
  final EditSetCallback? onEditSet;
  final Future<void> Function(LoggedSetView set)? onDeleteSet;

  /// Nota fija (la local pendiente manda sobre la de la API).
  final String? note;
  final bool notePending;
  final void Function(String? current)? onEditNote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = exercise.prescription;
    final weighted = exercise.loadType == LoadType.weighted;
    final noLoad = weighted && p.loadKg == null;
    final total = p.sets > logged.length ? p.sets : logged.length;
    final done = logged.length >= p.sets;
    final implement = exercise.loadImplement;
    final step = exercise.loadStepKg;
    final barKg = exercise.plates?.barKg ?? barKgFor(implement);

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
                      if (exercise.pinned)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Row(
                            key: Key('pinned-${exercise.planExerciseId}'),
                            children: [
                              Icon(
                                Icons.push_pin,
                                size: AppSpacing.md,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  exercise.substitutedFrom == null
                                      ? l10n.pinnedBadge
                                      : l10n.pinnedInsteadOf(
                                          exercise.substitutedFrom!.nameEs,
                                        ),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (exercise.substitutedFrom != null)
                        Text(
                          l10n.todaySubstitutedFrom(
                            exercise.substitutedFrom!.nameEs,
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      if (swapPending)
                        Row(
                          key: Key('swap-pending-${exercise.planExerciseId}'),
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                Icons.cloud_upload_outlined,
                                size: AppSpacing.md,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                l10n.swapPendingBadge,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
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
            if (onEditNote != null)
              _NoteBox(
                planExerciseId: exercise.planExerciseId,
                note: note,
                pending: notePending,
                onEdit: () => onEditNote!(note),
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
                    l10n.todaySuggestedLoad(l10n.kgPrecise(p.loadKg!)),
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  Chip(
                    key: Key('estimate-${exercise.planExerciseId}'),
                    avatar: const Icon(Icons.tune),
                    label: Text(l10n.todayInitialEstimate),
                  ),
                if (weighted && implement != null && step != null)
                  Text(
                    l10n.todayLoadStep(
                      l10n.loadImplementLabel(implement.wire),
                      l10n.kgPrecise(step),
                    ),
                    key: Key('load-step-${exercise.planExerciseId}'),
                    style: theme.textTheme.bodySmall,
                  ),
                if (weighted && barKg != null && p.loadKg != null)
                  TextButton.icon(
                    key: Key('plates-${exercise.planExerciseId}'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
                    ),
                    onPressed: () => showPlatesSheet(
                      context,
                      totalKg: p.loadKg!,
                      barKg: barKg,
                      breakdown: exercise.plates,
                    ),
                    icon: const Icon(Icons.fitness_center),
                    label: Text(
                      l10n.platesButton,
                      semanticsLabel: l10n.platesButtonFor(
                        l10n.kgPrecise(p.loadKg!),
                      ),
                    ),
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
                _LoggedSetRow(
                  index: i,
                  set: logged[i],
                  weighted: weighted,
                  onEdit: onEditSet,
                  onDelete: onDeleteSet,
                )
              else if (i == logged.length)
                ActiveSetRow(
                  key: Key('active-${exercise.planExerciseId}-$i'),
                  planExerciseId: exercise.planExerciseId,
                  index: i,
                  weighted: weighted,
                  loadStepKg: step,
                  barKg: barKg,
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

/// Nota fija del ejercicio, o «Añadir nota» si no hay.
class _NoteBox extends StatelessWidget {
  const _NoteBox({
    required this.planExerciseId,
    required this.note,
    required this.pending,
    required this.onEdit,
  });

  final String planExerciseId;
  final String? note;
  final bool pending;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = note;
    if (text == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: Key('note-add-$planExerciseId'),
          style: TextButton.styleFrom(
            minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
          ),
          onPressed: onEdit,
          icon: const Icon(Icons.sticky_note_2_outlined),
          label: Text(l10n.noteAdd),
        ),
      );
    }
    return Container(
      key: Key('note-$planExerciseId'),
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.only(left: AppSpacing.ms),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          // Icono de nota; la chincheta es solo del cambio fijado.
          ExcludeSemantics(
            child: Icon(
              Icons.sticky_note_2_outlined,
              key: Key('note-icon-$planExerciseId'),
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              label: l10n.noteLabel,
              child: Text(text, style: theme.textTheme.bodyMedium),
            ),
          ),
          if (pending)
            Tooltip(
              message: l10n.syncStatusPending,
              child: Icon(
                Icons.cloud_upload_outlined,
                key: Key('note-pending-$planExerciseId'),
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          IconButton(
            key: Key('note-edit-$planExerciseId'),
            tooltip: l10n.noteEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
        ],
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

enum _SetAction { edit, delete }

class _LoggedSetRow extends ConsumerWidget {
  const _LoggedSetRow({
    required this.index,
    required this.set,
    required this.weighted,
    this.onEdit,
    this.onDelete,
  });

  final int index;
  final LoggedSetView set;
  final bool weighted;
  final EditSetCallback? onEdit;
  final Future<void> Function(LoggedSetView set)? onDelete;

  Future<void> _edit(BuildContext context) async {
    final edited = await showEditSetSheet(
      context,
      setNumber: index + 1,
      weighted: weighted,
      reps: set.reps,
      loadKg: set.loadKg,
      rir: set.rir,
    );
    if (edited == null) return;
    await onEdit?.call(set, edited.reps, edited.loadKg, edited.rir);
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.setDeleteTitle(index + 1)),
        content: Text(l10n.setDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('set-delete-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.setDelete),
          ),
        ],
      ),
    );
    if (ok == true) await onDelete?.call(set);
  }

  /// «Descartar» una serie rechazada (#21): se pide confirmación y se quita
  /// de la cola local (con `DELETE` si llegó a existir en el servidor).
  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.setDiscardTitle(index + 1)),
        content: Text(l10n.setDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('set-discard-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.setDiscard),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(syncServiceProvider).deleteSet(set.clientId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final failed = set.status == SetSyncStatus.failed;
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
    const labelWidth = AppSpacing.xxl + AppSpacing.md;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: ExcludeSemantics(
              child: Text(
                l10n.todaySetLabel(index + 1),
                style: theme.textTheme.labelLarge,
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              label: '${l10n.todaySetLabel(index + 1)}: $summary. $label',
              excludeSemantics: true,
              child: Text(summary, style: theme.textTheme.bodyLarge),
            ),
          ),
          Tooltip(
            message: label,
            excludeFromSemantics: true,
            child: Icon(
              icon,
              color: color,
              key: Key('sync-${set.clientId}-${set.status.name}'),
            ),
          ),
          if (onEdit != null || onDelete != null)
            PopupMenuButton<_SetAction>(
              key: Key('set-menu-${set.clientId}'),
              tooltip: l10n.setActionsFor(index + 1),
              onSelected: (a) => switch (a) {
                _SetAction.edit => _edit(context),
                _SetAction.delete => _delete(context),
              },
              itemBuilder: (_) => [
                if (onEdit != null)
                  PopupMenuItem(
                    key: const Key('set-action-edit'),
                    value: _SetAction.edit,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(l10n.setEdit),
                    ),
                  ),
                // Una rechazada se quita con «Descartar» (debajo).
                if (onDelete != null && !failed)
                  PopupMenuItem(
                    key: const Key('set-action-delete'),
                    value: _SetAction.delete,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_outline),
                      title: Text(l10n.setDelete),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
    if (!failed) return row;
    final reason = setRejectionReason(l10n, set.lastError);
    return Column(
      key: Key('set-failed-${set.clientId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.only(left: labelWidth),
          child: Text(
            reason,
            key: Key('set-reason-${set.clientId}'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: labelWidth - AppSpacing.sm),
          child: Wrap(
            spacing: AppSpacing.xs,
            children: [
              TextButton.icon(
                key: Key('set-retry-${set.clientId}'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
                ),
                onPressed: () => ref.read(syncServiceProvider).retryFailed(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.syncRetry),
              ),
              TextButton.icon(
                key: Key('set-discard-${set.clientId}'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: () => _discard(context, ref),
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  l10n.setDiscard,
                  semanticsLabel: l10n.setDiscardFor(index + 1),
                ),
              ),
            ],
          ),
        ),
      ],
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
    this.loadStepKg,
    this.barKg,
  });

  final String planExerciseId;
  final int index;
  final bool weighted;

  /// Paso real del material (kg totales): lo que mueven − y +.
  final double? loadStepKg;

  /// Barra vacía si se puede desglosar en discos.
  final double? barKg;
  final int initialReps;
  final double? initialLoad;
  final int initialRir;
  final Future<void> Function(int reps, double load, int? rir) onConfirm;

  @override
  State<ActiveSetRow> createState() => _ActiveSetRowState();
}

class _ActiveSetRowState extends State<ActiveSetRow> {
  late final _reps = TextEditingController(text: '${widget.initialReps}');
  final _load = TextEditingController();
  bool _loadPrefilled = false;
  late int _rir = widget.initialRir;
  String? _repsError;
  String? _loadError;
  bool _busy = false;

  /// `62,5` en castellano (separador decimal del idioma, hasta 2 decimales).
  String _fmt(double v) =>
      formatDecimalInput(v, AppLocalizations.of(context).localeName);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // La carga precargada necesita el idioma (contexto), así que se escribe
    // aquí y una sola vez; luego el campo es de la persona.
    if (!_loadPrefilled) {
      _loadPrefilled = true;
      final initial = widget.initialLoad;
      if (initial != null) _load.text = _fmt(initial);
    }
  }

  @override
  void dispose() {
    _reps.dispose();
    _load.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final reps = int.tryParse(_reps.text.trim());
    final load = widget.weighted ? parseDecimalInput(_load.text) : 0.0;
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

  double? get _currentLoad => parseDecimalInput(_load.text);

  /// − / +: mueve la carga un paso real del material (nunca por debajo de 0).
  void _stepLoad(int direction) {
    final step = widget.loadStepKg;
    if (step == null) return;
    final current = _currentLoad ?? 0;
    final next = (current + direction * step).clamp(0, 1000).toDouble();
    setState(() {
      _load.text = _fmt((next * 100).round() / 100);
      _loadError = null;
    });
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
          // Hueco para la etiqueta flotante (Reps / Kg) del campo, que se
          // dibuja por encima del borde.
          const SizedBox(height: AppSpacing.ms),
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
          if (widget.weighted &&
              (widget.loadStepKg != null || widget.barKg != null))
            Wrap(
              spacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.loadStepKg != null) ...[
                  IconButton.outlined(
                    key: Key('load-minus-$id'),
                    tooltip: l10n.loadDecrease(
                      l10n.kgPrecise(widget.loadStepKg!),
                    ),
                    onPressed: () => _stepLoad(-1),
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton.outlined(
                    key: Key('load-plus-$id'),
                    tooltip: l10n.loadIncrease(
                      l10n.kgPrecise(widget.loadStepKg!),
                    ),
                    onPressed: () => _stepLoad(1),
                    icon: const Icon(Icons.add),
                  ),
                ],
                if (widget.barKg != null)
                  TextButton.icon(
                    key: Key('row-plates-$id'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
                    ),
                    onPressed: () {
                      final load = _currentLoad;
                      if (load == null) return;
                      showPlatesSheet(
                        context,
                        totalKg: load,
                        barKg: widget.barKg!,
                      );
                    },
                    icon: const Icon(Icons.fitness_center),
                    label: Text(l10n.platesButton),
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
