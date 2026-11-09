/// Cambiar un ejercicio (CUJ-4): 3 alternativas ordenadas
/// (`GET /exercises/:id/substitutes`) → `POST .../substitute`. Necesita red:
/// la sustitución la valida el servidor (material y limitaciones).
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

final _substitutesProvider = FutureProvider.autoDispose
    .family<SubstitutesResponse, String>(
      (ref, exerciseId) =>
          ref.watch(workoutApiProvider).getSubstitutes(exerciseId),
    );

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
      final serverId = await sync.ensureStartedOnServer(workout.clientId);
      await ref
          .read(workoutApiProvider)
          .substitute(
            workoutId: serverId,
            planExerciseId: widget.exercise.planExerciseId,
            exerciseId: option.exerciseId,
          );
      ref.invalidate(todaySessionProvider);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.swapDone(option.nameEs))),
      );
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
    final subs = ref.watch(_substitutesProvider(widget.exercise.exercise.id));
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

              if (failure != null)
                Semantics(
                  liveRegion: true,
                  child: NoticeBanner(
                    text: failure.isConnectivity
                        ? l10n.errorOfflineAction
                        : failure.localized(l10n),
                    icon: Icons.error_outline,
                  ),
                ),
              Flexible(
                child: subs.when(
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
                      _substitutesProvider(widget.exercise.exercise.id),
                    ),
                  ),
                  data: (r) => r.substitutes.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            l10n.swapEmpty,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final o in r.substitutes)
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.ms,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          o.nameEs,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        for (final line in o.rationale)
                                          Text(
                                            '• $line',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        const SizedBox(height: AppSpacing.sm),
                                        FilledButton(
                                          key: Key(
                                            'swap-choose-${o.exerciseId}',
                                          ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
