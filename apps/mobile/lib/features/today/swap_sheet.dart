/// Cambiar un ejercicio (CUJ-4): 3 alternativas ordenadas
/// (`GET /exercises/:id/substitutes`, guardadas en caché con la sesión de
/// hoy) → `POST .../substitute`. El cambio de hoy va por la cola offline
/// (#23) y se envía antes que las series del sustituto; fijarlo en el plan
/// (idea 3) necesita red.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tokens.dart';
import '../../core/api/api_failure.dart';
import '../../core/offline/offline_providers.dart';
import '../../data/pipos_api.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/workout.dart';
import '../../shared/exercise_muscles.dart';
import '../../shared/widgets.dart';
import '../plan/plan_providers.dart';
import 'today_providers.dart';

Future<void> showSwapSheet(
  BuildContext context, {
  required TodayExercise exercise,
  required String planSessionId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) =>
        _SwapSheet(exercise: exercise, planSessionId: planSessionId),
  );
}

class _SwapSheet extends ConsumerStatefulWidget {
  const _SwapSheet({required this.exercise, required this.planSessionId});

  final TodayExercise exercise;
  final String planSessionId;

  @override
  ConsumerState<_SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends ConsumerState<_SwapSheet> {
  String? _busyId;
  ApiFailure? _failure;

  /// «Usar siempre este cambio en este plan» (idea 3): fija el cambio en el
  /// plan en vez de cambiarlo solo en el entrenamiento de hoy.
  bool _pin = false;

  Future<void> _choose(SubstituteOption option) async {
    if (_pin) return _pinChoice(option);
    setState(() {
      _busyId = option.exerciseId;
      _failure = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final sync = ref.read(syncServiceProvider);
      final workout = await sync.startWorkout(
        planSessionId: widget.planSessionId,
      );
      final slot = widget.exercise.planExerciseId;
      await sync.enqueueSubstitution(
        workoutClientId: workout.clientId,
        planExerciseId: slot,
        exercise: ExerciseRef(
          id: option.exerciseId,
          slug: option.slug,
          nameEs: option.nameEs,
        ),
        substitutedFrom:
            widget.exercise.substitutedFrom ?? widget.exercise.exercise,
      );
      // Con red sale ya (en orden con las series pendientes); sin red queda
      // en la cola y la sesión lo muestra como pendiente.
      await sync.syncNow();
      final queued = (await sync.pendingSwaps()).where(
        (s) =>
            s.workoutClientId == workout.clientId && s.planExerciseId == slot,
      );
      final failed = queued.where((s) => s.failed).toList();
      if (failed.isNotEmpty) {
        // La API lo rechazó: se quita de la cola y se explica aquí.
        for (final s in failed) {
          await sync.discardMutation(s.key!);
        }
        throw ApiFailure(
          type: ApiFailureType.badRequest,
          message: failed.last.lastError ?? '',
          code: failed.last.lastError,
        );
      }
      navigator.pop();
      if (queued.isEmpty) {
        ref.invalidate(todaySessionProvider);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.swapDone(option.nameEs))),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.swapQueued(option.nameEs))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyId = null;
        _failure = ApiFailure.from(e);
      });
    }
  }

  Future<void> _pinChoice(SubstituteOption option) async {
    setState(() {
      _busyId = option.exerciseId;
      _failure = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(planApiProvider)
          .pinExercise(
            planExerciseId: widget.exercise.planExerciseId,
            exerciseId: option.exerciseId,
          );
      ref.invalidate(todaySessionProvider);
      ref.invalidate(currentPlanProvider);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.swapPinnedDone(option.nameEs))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyId = null;
        _failure = ApiFailure.from(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final subs = ref.watch(substitutesProvider(widget.exercise.exercise.id));
    final offline = subs.valueOrNull?.fromCache ?? false;
    final failure = _failure;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          // Toda la hoja se desplaza: con texto grande, la cabecera sola ya
          // no cabe (sin desbordes al 200 %).
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.swapTitle(widget.exercise.exercise.nameEs),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.swapHint, style: theme.textTheme.bodyMedium),
                SwitchListTile(
                  key: const Key('swap-pin'),
                  contentPadding: EdgeInsets.zero,
                  value: _pin,
                  onChanged: _busyId == null
                      ? (v) => setState(() => _pin = v)
                      : null,
                  title: Text(l10n.swapPinLabel),
                  subtitle: Text(l10n.swapPinHelp),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (offline && failure == null)
                  NoticeBanner(
                    key: const Key('swap-offline'),
                    text: l10n.swapOfflineNotice,
                    icon: Icons.cloud_off_outlined,
                  ),
                if (failure != null)
                  Semantics(
                    liveRegion: true,
                    child: NoticeBanner(
                      key: const Key('swap-error'),
                      text: failure.isConnectivity
                          ? (_pin
                                ? l10n.swapPinNeedsNetwork
                                : l10n.errorOfflineAction)
                          : failure.localized(l10n),
                      icon: Icons.error_outline,
                    ),
                  ),
                subs.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: LoadingView(),
                  ),
                  error: (e, _) => ErrorView(
                    error: e,
                    message: ApiFailure.from(e).isConnectivity
                        ? l10n.errorOfflineAction
                        : null,
                    onRetry: () => ref.invalidate(
                      substitutesProvider(widget.exercise.exercise.id),
                    ),
                  ),
                  data: (cached) => cached.value.substitutes.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            l10n.swapEmpty,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final o in cached.value.substitutes)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.ms),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        o.nameEs,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      MusclesWorksLine(
                                        key: Key(
                                          'swap-muscles-${o.exerciseId}',
                                        ),
                                        muscles: o.primaryMuscles,
                                      ),
                                      for (final line in o.rationale)
                                        Text(
                                          '• $line',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      const SizedBox(height: AppSpacing.sm),
                                      FilledButton(
                                        key: Key('swap-choose-${o.exerciseId}'),
                                        onPressed: _busyId == null
                                            ? () => _choose(o)
                                            : null,
                                        child: _busyId == o.exerciseId
                                            ? const SizedBox.square(
                                                dimension:
                                                    AppSpacing.lg -
                                                    AppSpacing.xs,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(l10n.swapChoose(o.nameEs)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
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
