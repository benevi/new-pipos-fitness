/// Progreso → «Cuerpo» (idea 7, ADR-0013; CUJ-10): tendencia de peso frente
/// al ritmo del objetivo (media de 7 días), IMC con la categoría de la OMS y
/// % de grasa estimado (método de la Marina), siempre como «Estimación — no
/// es un diagnóstico» y con sus límites, y perímetros con su cambio a 4 y 12
/// semanas. Las explicaciones vienen de la API (castellano).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tokens.dart';
import '../../core/offline/app_database.dart';
import '../../core/offline/mutation_sender.dart';
import '../../core/offline/offline_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/body.dart';
import '../../models/enums.dart';
import '../../models/notes_breaks.dart';
import '../../models/profile.dart';
import '../../shared/widgets.dart';
import '../settings/settings_providers.dart';
import 'body_providers.dart';
import 'charts.dart';
import 'measurement_form.dart';

class BodyProgressView extends ConsumerWidget {
  const BodyProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final consent = ref.watch(healthConsentProvider);
    // Una medida que deja de estar pendiente ya está en la API: se relee.
    ref.listen(pendingMeasurementsProvider, (prev, next) {
      final before = prev?.valueOrNull?.keys ?? const <String>[];
      final now = next.valueOrNull?.keys.toSet() ?? const <String>{};
      if (before.any((k) => !now.contains(k))) {
        ref.invalidate(bodyProgressProvider);
        ref.invalidate(measurementsProvider);
      }
    });
    return consent.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(healthConsentProvider),
      ),
      data: (c) {
        if (!c.covers(HealthDataScope.weight)) return _ConsentGate(consent: c);
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(measurementsProvider);
            ref.invalidate(bodyProgressProvider);
            await ref.read(bodyProgressProvider.future);
          },
          child: ListView(
            key: const Key('body-list'),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (!c.covers(HealthDataScope.bodyMeasurements))
                const _ConsentUpgrade(key: Key('body-consent-upgrade')),
              FilledButton.icon(
                key: const Key('body-add'),
                onPressed: () => openMeasurementForm(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.bodyAddMeasurement),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _BodyProgressSections(),
              const _History(),
            ],
          ),
        );
      },
    );
  }
}

class _ConsentGate extends ConsumerWidget {
  const _ConsentGate({required this.consent});

  final HealthConsentStatus consent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        EmptyState(
          key: const Key('body-consent-gate'),
          icon: Icons.health_and_safety_outlined,
          title: l10n.bodyConsentNeededTitle,
          body: l10n.bodyConsentNeededBody,
          actionLabel: l10n.bodyConsentReview,
          onAction: () => askHealthConsent(context, ref),
        ),
      ],
    );
  }
}

class _ConsentUpgrade extends ConsumerWidget {
  const _ConsentUpgrade({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.ms),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.bodyConsentUpgradeBody),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              key: const Key('body-consent-review'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, AppSpacing.xxl),
              ),
              onPressed: () => askHealthConsent(context, ref),
              child: Text(l10n.bodyConsentReview),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyProgressSections extends ConsumerWidget {
  const _BodyProgressSections();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final body = ref.watch(bodyProgressProvider);
    return body.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LoadingView(),
      ),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(bodyProgressProvider),
      ),
      data: (b) => b.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(l10n.bodyEmpty, key: const Key('body-empty')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WeightCard(body: b),
                _BmiCard(block: b.bmi),
                _BodyFatCard(block: b.bodyFat),
                _CircumferencesCard(items: b.circumferences),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    b.disclaimer,
                    key: const Key('body-disclaimer'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
    );
  }
}

String _date(AppLocalizations l10n, String iso) =>
    l10n.shortDate(parseCalendarDate(iso));

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.body});

  final BodyProgress body;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = body.trend;
    final latest = body.latestWeight;
    final avg = t.movingAverage;
    final ok = t.status == WeightTrendStatus.onTrack;
    final warn =
        t.status == WeightTrendStatus.tooFast ||
        t.status == WeightTrendStatus.tooSlow ||
        t.status == WeightTrendStatus.wrongDirection;
    return SectionCard(
      title: l10n.bodyWeightTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (latest != null)
            Text(
              l10n.bodyWeightLatest(
                l10n.kgPrecise(latest.value),
                _date(l10n, latest.date),
              ),
              style: theme.textTheme.titleMedium,
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            key: const Key('weight-status'),
            children: [
              Icon(
                ok
                    ? Icons.check_circle_outline
                    : warn
                    ? Icons.warning_amber_outlined
                    : Icons.info_outline,
                color: ok
                    ? theme.colorScheme.primary
                    : warn
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.bodyTrendStatus(t.status.wire),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          if (t.weeklyRatePct != null)
            Text(
              l10n.bodyTrendRate(
                '${t.weeklyRatePct! > 0 ? '+' : ''}'
                '${l10n.number(t.weeklyRatePct!, maxDecimals: 2)}',
              ),
            ),
          if (t.target != null)
            Text(
              l10n.bodyTrendTarget(
                t.target!.direction,
                l10n.number(t.target!.minPct, maxDecimals: 2),
                l10n.number(t.target!.maxPct, maxDecimals: 2),
              ),
              style: theme.textTheme.bodySmall,
            ),
          RationaleExpander(lines: t.rationale),
          if (avg.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.bodyChartTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            TrendChart(
              key: const Key('weight-chart'),
              values: [for (final p in avg) p.value],
              semanticLabel: l10n.bodyChartLabel(
                l10n.kgPrecise(avg.first.value),
                l10n.kgPrecise(avg.last.value),
                avg.length,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Etiqueta fija de las estimaciones.
class _EstimateLabel extends StatelessWidget {
  const _EstimateLabel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        AppLocalizations.of(context).bodyEstimateLabel,
        style: theme.textTheme.labelMedium,
      ),
    );
  }
}

class _Caveats extends StatelessWidget {
  const _Caveats({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in lines)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text('• $c', style: style),
          ),
      ],
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.block});

  final BmiBlock block;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final r = block.result;
    return SectionCard(
      key: const Key('bmi-card'),
      title: l10n.bodyBmiTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _EstimateLabel(),
          if (block.status == EstimateStatus.ok && r?.value != null) ...[
            Text(
              l10n.number(r!.value!),
              key: const Key('bmi-value'),
              style: theme.textTheme.headlineSmall,
            ),
            if (r.category != null) ...[
              Text(
                l10n.bmiCategoryLabel(r.category!.wire),
                style: theme.textTheme.titleSmall,
              ),
              Text(l10n.bodyBmiWhoNote, style: theme.textTheme.bodySmall),
            ],
            if (block.measuredOn != null)
              Text(
                l10n.bodyMeasuredOn(_date(l10n, block.measuredOn!)),
                style: theme.textTheme.bodySmall,
              ),
          ] else
            Text(
              block.status == EstimateStatus.insufficientData
                  ? l10n.bodyBmiMissing
                  : l10n.bodyEstimateStatus(block.status.wire),
            ),
          if (r != null) _Caveats(lines: r.caveats),
        ],
      ),
    );
  }
}

class _BodyFatCard extends StatelessWidget {
  const _BodyFatCard({required this.block});

  final BodyFatBlock block;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final r = block.result;
    return SectionCard(
      key: const Key('body-fat-card'),
      title: l10n.bodyFatTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _EstimateLabel(),
          if (block.status == EstimateStatus.ok && r?.percent != null) ...[
            Text(
              l10n.bodyFatValue(l10n.number(r!.percent!)),
              key: const Key('body-fat-value'),
              style: theme.textTheme.headlineSmall,
            ),
            if (block.measuredOn != null)
              Text(
                l10n.bodyMeasuredOn(_date(l10n, block.measuredOn!)),
                style: theme.textTheme.bodySmall,
              ),
            Text(l10n.bodyFatMethod, style: theme.textTheme.bodySmall),
          ] else if (block.status == EstimateStatus.notApplicable)
            Text(
              l10n.bodyNotApplicable,
              key: const Key('body-fat-not-applicable'),
              style: theme.textTheme.titleSmall,
            )
          else
            Text(
              block.status == EstimateStatus.insufficientData
                  ? l10n.bodyFatMissing
                  : l10n.bodyEstimateStatus(block.status.wire),
            ),
          if (r != null) ...[
            for (final i in r.issues)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(i, style: theme.textTheme.bodyMedium),
              ),
            _Caveats(lines: r.caveats),
          ],
        ],
      ),
    );
  }
}

class _CircumferencesCard extends StatelessWidget {
  const _CircumferencesCard({required this.items});

  final List<CircumferenceTrend> items;

  String _change(AppLocalizations l10n, double v) =>
      l10n.bodyCm('${v > 0 ? '+' : ''}${l10n.number(v)}');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: l10n.bodyCircumferencesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in items)
            Padding(
              key: Key('circ-${c.field.wire}'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.bodyFieldLabel(c.field.wire),
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    c.latest == null
                        ? l10n.bodyNoValue
                        : l10n.bodyLatestValue(
                            l10n.bodyCm(l10n.number(c.latest!.value)),
                            _date(l10n, c.latest!.date),
                          ),
                  ),
                  if (c.change4w != null || c.change12w != null)
                    Wrap(
                      spacing: AppSpacing.md,
                      children: [
                        if (c.change4w != null)
                          Text(
                            l10n.bodyChange('w4', _change(l10n, c.change4w!)),
                            style: theme.textTheme.bodySmall,
                          ),
                        if (c.change12w != null)
                          Text(
                            l10n.bodyChange('w12', _change(l10n, c.change12w!)),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          Text(l10n.bodyCircumferencesNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Registros (los pendientes de enviar, marcados) con borrado por día.
class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final server = ref.watch(measurementsProvider).valueOrNull;
    final pending =
        ref.watch(pendingMeasurementsProvider).valueOrNull ??
        const <String, BodyMeasurement?>{};
    if (server == null && pending.isEmpty) return const SizedBox.shrink();
    final items = mergeMeasurements(server ?? const [], pending).take(10);
    if (items.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: l10n.bodyHistoryTitle,
      child: Column(
        children: [
          for (final e in items)
            ListTile(
              key: Key('measurement-${e.measurement.measuredOn}'),
              contentPadding: EdgeInsets.zero,
              minTileHeight: AppSpacing.xxl,
              title: Text(_date(l10n, e.measurement.measuredOn)),
              subtitle: Text(
                [
                  for (final f in BodyField.values)
                    if (e.measurement[f] != null)
                      '${l10n.bodyFieldLabel(f.wire)} '
                          '${f == BodyField.weightKg ? l10n.kgPrecise(e.measurement[f]!) : l10n.bodyCm(l10n.number(e.measurement[f]!))}',
                ].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (e.pending)
                    Tooltip(
                      message: l10n.syncStatusPending,
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        key: Key(
                          'measurement-pending-${e.measurement.measuredOn}',
                        ),
                      ),
                    ),
                  IconButton(
                    key: Key('measurement-delete-${e.measurement.measuredOn}'),
                    tooltip: l10n.bodyHistoryDelete(
                      _date(l10n, e.measurement.measuredOn),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ref
                          .read(syncServiceProvider)
                          .enqueueMutation(
                            key: MutationKeys.measurement(
                              e.measurement.measuredOn,
                            ),
                            kind: MutationKind.measurementDelete,
                            payload: {'date': e.measurement.measuredOn},
                          );
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.bodyHistoryDeleted)),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
