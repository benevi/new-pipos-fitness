import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'today_providers.dart';

/// Barra del descanso (abajo, sobre la navegación). Respeta
/// `MediaQuery.disableAnimations`: sin la barra de progreso, solo el texto.
class RestTimerBar extends ConsumerStatefulWidget {
  const RestTimerBar({super.key});

  static String format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  ConsumerState<RestTimerBar> createState() => _RestTimerBarState();
}

class _RestTimerBarState extends ConsumerState<RestTimerBar> {
  // En segundo plano, aviso local al terminar el descanso (#24); al volver
  // a primer plano se cancela y se recalcula al instante (sin esperar al
  // siguiente tick).
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onHide: () {
      final l10n = AppLocalizations.of(context);
      ref
          .read(restTimerProvider.notifier)
          .onBackground(
            title: l10n.restNotificationTitle,
            body: l10n.restNotificationBody,
          );
    },
    onResume: () => ref.read(restTimerProvider.notifier).onForeground(),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(restTimerProvider);
    if (timer == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final controller = ref.read(restTimerProvider.notifier);
    final text = timer.done
        ? l10n.restTimerDone
        : l10n.restTimerRemaining(RestTimerBar.format(timer.remaining));

    return Material(
      key: const Key('rest-timer'),
      color: theme.colorScheme.primaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!reduceMotion && !timer.done)
                ExcludeSemantics(
                  child: LinearProgressIndicator(
                    value: timer.remaining / timer.total,
                  ),
                ),
              Row(
                children: [
                  const ExcludeSemantics(child: Icon(Icons.timer_outlined)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Semantics(
                      // Solo se anuncia al terminar (no cada segundo).
                      liveRegion: timer.done,
                      child: Text(text, style: theme.textTheme.titleMedium),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.restTimerAdd,
                    icon: const Icon(Icons.more_time),
                    onPressed: () => controller.add(15),
                  ),
                  IconButton(
                    key: const Key('rest-skip'),
                    tooltip: timer.done ? l10n.actionClose : l10n.restTimerSkip,
                    icon: Icon(timer.done ? Icons.close : Icons.skip_next),
                    onPressed: controller.skip,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
