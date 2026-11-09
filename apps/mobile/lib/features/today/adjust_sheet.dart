/// Ajuste de hoy (idea 4, ADR-0013; CUJ-9): poco tiempo o volumen reducido.
/// Vista previa con `GET /sessions/today?minutes=&mode=` (solo lectura: ni
/// guarda nada ni crea una versión del plan); al aceptar, la sesión ajustada
/// se guarda en caché (sirve sin red) y el ajuste viaja en `POST /workouts`
/// al confirmar la primera serie.
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
import 'today_providers.dart';

/// Minutos que se ofrecen (dentro de 15-90 del contrato).
const adjustMinuteOptions = [20, 30, 45, 60];

Future<void> showAdjustSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => const _AdjustSheet(),
  );
}

class _AdjustSheet extends ConsumerStatefulWidget {
  const _AdjustSheet();

  @override
  ConsumerState<_AdjustSheet> createState() => _AdjustSheetState();
}

class _AdjustSheetState extends ConsumerState<_AdjustSheet> {
  int? _minutes;
  bool _reduced = false;
  bool _busy = false;
  String? _error;
  TodaySession? _preview;

  WorkoutAdjustment get _choice =>
      WorkoutAdjustment(availableMinutes: _minutes, reducedVolume: _reduced);

  void _changed(VoidCallback change) => setState(() {
    change();
    _preview = null;
    _error = null;
  });

  Future<void> _loadPreview() async {
    final l10n = AppLocalizations.of(context);
    if (_choice.isNone) {
      setState(() => _error = l10n.adjustPickSomething);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await ref
          .read(workoutApiProvider)
          .getToday(adjustment: _choice);
      if (!mounted) return;
      setState(() => _preview = preview);
    } catch (e) {
      if (!mounted) return;
      final f = ApiFailure.from(e);
      setState(
        () => _error = f.isConnectivity
            ? l10n.errorOfflineAction
            : f.localized(l10n),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    final preview = _preview;
    if (preview == null) return;
    final navigator = Navigator.of(context);
    // La sesión ajustada queda en caché: si se va la red, Hoy abre con ella.
    await ref.read(cacheStoreProvider).write(CacheKeys.today, preview.toJson());
    ref.read(todayAdjustmentProvider.notifier).state = _choice;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final preview = _preview;
    final adjustment = preview?.adjustment;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          key: const Key('adjust-sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.adjustTitle, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.adjustIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.adjustMinutesLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final m in adjustMinuteOptions)
                  ChoiceChip(
                    key: Key('adjust-minutes-$m'),
                    label: Text(l10n.adjustMinutesChip(m)),
                    selected: _minutes == m,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: (on) =>
                        _changed(() => _minutes = on ? m : null),
                  ),
              ],
            ),
            SwitchListTile(
              key: const Key('adjust-reduced'),
              contentPadding: EdgeInsets.zero,
              value: _reduced,
              onChanged: (v) => _changed(() => _reduced = v),
              title: Text(l10n.adjustReducedLabel),
              subtitle: Text(l10n.adjustReducedHelp),
            ),
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: NoticeBanner(
                  key: const Key('adjust-error'),
                  text: _error!,
                  icon: Icons.error_outline,
                ),
              ),
            if (preview == null)
              FilledButton(
                key: const Key('adjust-preview'),
                onPressed: _busy ? null : _loadPreview,
                child: _busy
                    ? const SizedBox.square(
                        dimension: AppSpacing.lg - AppSpacing.xs,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.adjustPreview),
              )
            else ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.adjustEstimated(
                    (adjustment?.estimatedMinutes ?? preview.estimatedMinutes)
                        .round(),
                  ),
                  key: const Key('adjust-estimated'),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (adjustment == null || adjustment.dropped.isEmpty)
                Text(l10n.adjustNothingDropped)
              else ...[
                Text(
                  l10n.adjustDroppedTitle,
                  style: theme.textTheme.titleSmall,
                ),
                for (final d in adjustment.dropped)
                  Text(
                    '• ${d.exercise.nameEs}',
                    key: Key('adjust-dropped-${d.planExerciseId}'),
                  ),
              ],
              if (adjustment != null && !adjustment.fits)
                NoticeBanner(
                  key: const Key('adjust-not-fits'),
                  text: l10n.adjustDoesNotFit,
                  icon: Icons.warning_amber_outlined,
                ),
              if (adjustment != null)
                RationaleExpander(lines: adjustment.rationale),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                key: const Key('adjust-apply'),
                onPressed: _apply,
                child: Text(l10n.adjustApply),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Aviso en Hoy con el ajuste aplicado y, antes de empezar, la opción de
/// volver a la sesión completa.
class AdjustmentBanner extends ConsumerWidget {
  const AdjustmentBanner({
    super.key,
    required this.adjustment,
    required this.canRemove,
  });

  final TodayAdjustment adjustment;
  final bool canRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final minutes = adjustment.availableMinutes;
    final title = minutes != null && adjustment.reducedVolume
        ? l10n.adjustBannerBoth(minutes)
        : minutes != null
        ? l10n.adjustBannerMinutes(minutes)
        : l10n.adjustBannerReduced;
    return Card(
      key: const Key('adjust-banner'),
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.ms),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.timer_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
              ],
            ),
            Text(l10n.adjustEstimated(adjustment.estimatedMinutes.round())),
            if (adjustment.dropped.isNotEmpty)
              Text(
                l10n.adjustBannerDropped(
                  adjustment.dropped.map((d) => d.exercise.nameEs).join(', '),
                ),
              ),
            if (!adjustment.fits)
              Text(
                l10n.adjustDoesNotFit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            RationaleExpander(lines: adjustment.rationale),
            if (canRemove)
              TextButton(
                key: const Key('adjust-remove'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
                ),
                onPressed: () =>
                    ref.read(todayAdjustmentProvider.notifier).state = null,
                child: Text(l10n.adjustRemove),
              ),
          ],
        ),
      ),
    );
  }
}
