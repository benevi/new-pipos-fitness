import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../shared/widgets.dart';
import '../setup/setup_provider.dart';
import 'plan_providers.dart';
import 'plan_view.dart';

/// Pestaña «Plan»: plan actual y acceso al historial de versiones.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plan = ref.watch(currentPlanProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.planTitle),
        actions: [
          IconButton(
            key: const Key('plan-history'),
            tooltip: l10n.planHistory,
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/plan/history'),
          ),
        ],
      ),
      body: plan.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(currentPlanProvider),
        ),
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
          return RefreshIndicator(
            onRefresh: () => ref.refresh(currentPlanProvider.future),
            child: PlanOverview(
              plan: cached.value,
              header: cached.fromCache && cached.savedAt != null
                  ? NoticeBanner(
                      text: l10n.cachedDataNotice(
                        l10n.dateTime(cached.savedAt!),
                      ),
                      icon: Icons.cloud_off_outlined,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

/// Historial de versiones (CUJ-6: la anterior sigue consultable).
class PlanHistoryScreen extends ConsumerWidget {
  const PlanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final versions = ref.watch(planVersionsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.planHistory)),
      body: versions.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(planVersionsProvider),
        ),
        data: (page) {
          if (page.items.length <= 1 && page.items.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.history,
                title: l10n.planHistory,
                body: l10n.planHistoryEmpty,
              ),
            );
          }
          final newest = page.items
              .map((v) => v.version)
              .fold<int>(0, (a, b) => a > b ? a : b);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (page.items.length == 1)
                NoticeBanner(text: l10n.planHistoryEmpty),
              for (final v in page.items)
                Card(
                  child: ListTile(
                    minTileHeight: AppSpacing.xxl + AppSpacing.md,
                    title: Text(
                      l10n.planHistoryItem(
                        v.version,
                        l10n.shortDate(v.createdAt),
                      ),
                    ),
                    subtitle: Text(l10n.splitLabel(v.splitType.wire)),
                    trailing: v.version == newest
                        ? Chip(label: Text(l10n.planCurrentBadge))
                        : const Icon(Icons.chevron_right),
                    onTap: () => context.go('/plan/history/${v.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class PlanVersionScreen extends ConsumerWidget {
  const PlanVersionScreen({super.key, required this.versionId});

  final String versionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final version = ref.watch(planVersionProvider(versionId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          version.valueOrNull == null
              ? l10n.planHistory
              : l10n.planVersionLabel(version.value!.version),
        ),
      ),
      body: version.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(planVersionProvider(versionId)),
        ),
        data: (plan) => PlanOverview(plan: plan),
      ),
    );
  }
}
