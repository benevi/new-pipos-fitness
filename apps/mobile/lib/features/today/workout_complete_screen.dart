import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tokens.dart';
import '../../core/offline/offline_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import 'today_providers.dart';

/// Fin del entrenamiento: resumen y estado de la sincronización.
class WorkoutCompleteScreen extends ConsumerWidget {
  const WorkoutCompleteScreen({super.key, this.summary});

  final WorkoutSummary? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sync = ref.watch(syncSummaryProvider).valueOrNull;
    final pending = sync != null && !sync.isClean;
    final s = summary;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: AppSpacing.xxl * 2,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.completeTitle,
                    key: const Key('complete-title'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                if (s != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.completeSummary(
                      s.sets,
                      l10n.number(s.volumeKg, maxDecimals: 0),
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pending
                            ? Icons.cloud_upload_outlined
                            : Icons.cloud_done_outlined,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          pending ? l10n.completePending : l10n.completeSynced,
                          key: Key(
                            pending ? 'complete-pending' : 'complete-synced',
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(todaySessionProvider);
                    context.go('/today');
                  },
                  child: Text(l10n.completeBack),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
