/// Progreso (CUJ-7): e1RM por ejercicio con tendencia, series semanales por
/// grupo frente al rango objetivo y adherencia. Cada bloque tiene su estado
/// vacío; si todo está vacío se muestra un único estado vacío general.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tokens.dart';
import '../../data/pipos_api.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/enums.dart';
import '../../models/notes_breaks.dart' show parseCalendarDate;
import '../../models/progress.dart';
import '../../shared/widgets.dart';
import 'body_view.dart';
import 'charts.dart';

class ProgressData {
  const ProgressData({
    required this.e1rm,
    required this.volume,
    required this.adherence,
  });

  final E1rmResponse e1rm;
  final VolumeResponse volume;
  final AdherenceResponse adherence;

  VolumeWeek? get currentWeek =>
      volume.weeks.isEmpty ? null : volume.weeks.last;

  bool get isEmpty =>
      e1rm.series.isEmpty &&
      (currentWeek == null ||
          currentWeek!.groups.every((g) => g.effectiveSets == 0)) &&
      adherence.completedSessions == 0;
}

final progressProvider = FutureProvider.autoDispose<ProgressData>((ref) async {
  final api = ref.watch(progressApiProvider);
  final results = await Future.wait([
    api.getE1rm(),
    api.getVolume(weeks: 4),
    api.getAdherence(weeks: 4),
  ]);
  return ProgressData(
    e1rm: results[0] as E1rmResponse,
    volume: results[1] as VolumeResponse,
    adherence: results[2] as AdherenceResponse,
  );
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(progressProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.progressTitle),
          bottom: TabBar(
            tabs: [
              Tab(
                key: const Key('progress-tab-training'),
                text: l10n.progressTabTraining,
              ),
              Tab(
                key: const Key('progress-tab-body'),
                text: l10n.progressTabBody,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _trainingTab(context, ref, data),
            const BodyProgressView(),
          ],
        ),
      ),
    );
  }

  Widget _trainingTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<ProgressData> data,
  ) {
    final l10n = AppLocalizations.of(context);
    return data.when(
      loading: () => const LoadingView(),
      error: (e, _) =>
          ErrorView(error: e, onRetry: () => ref.invalidate(progressProvider)),
      data: (d) => RefreshIndicator(
        onRefresh: () => ref.refresh(progressProvider.future),
        child: d.isEmpty
            ? ListView(
                children: [
                  EmptyState(
                    key: const Key('progress-empty'),
                    icon: Icons.insights_outlined,
                    title: l10n.progressEmptyTitle,
                    body: l10n.progressEmptyBody,
                  ),
                ],
              )
            : ListView(
                key: const Key('progress-filled'),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _E1rmSection(series: d.e1rm.series),
                  _VolumeSection(week: d.currentWeek),
                  _AdherenceSection(adherence: d.adherence),
                ],
              ),
      ),
    );
  }
}

class _E1rmSection extends StatelessWidget {
  const _E1rmSection({required this.series});

  final List<E1rmSeries> series;

  /// Tendencia con fechas primera/última y mínimo/máximo en kg.
  Widget _e1rmChart(AppLocalizations l10n, E1rmSeries s) {
    final values = [for (final p in s.points) p.e1rmKg];
    final first = parseCalendarDate(s.points.first.date);
    final last = parseCalendarDate(s.points.last.date);
    return Sparkline(
      key: Key('e1rm-chart-${s.exerciseId}'),
      values: values,
      minLabel: l10n.kg(values.reduce(math.min)),
      maxLabel: l10n.kg(values.reduce(math.max)),
      firstLabel: l10n.dayMonth(first),
      lastLabel: l10n.dayMonth(last),
      semanticLabel: l10n.progressE1rmTrend(
        s.nameEs,
        l10n.number(values.first),
        l10n.number(values.last),
        l10n.dayMonth(first),
        l10n.dayMonth(last),
        s.points.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: l10n.progressE1rmTitle,
      child: series.isEmpty
          ? Text(l10n.progressE1rmEmpty, style: theme.textTheme.bodyMedium)
          : Column(
              children: [
                for (final s in series)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(s.nameEs, style: theme.textTheme.titleSmall),
                        Text(
                          l10n.progressE1rmValue(l10n.number(s.latestE1rmKg)),
                          style: theme.textTheme.titleMedium,
                        ),
                        if (s.points.length > 1) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _e1rmChart(l10n, s),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _VolumeSection extends StatelessWidget {
  const _VolumeSection({required this.week});

  final VolumeWeek? week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groups = week?.groups ?? const <GroupWeekVolume>[];
    final hasData = groups.any(
      (g) => g.effectiveSets > 0 || g.targetMax != null,
    );
    final scale = groups.fold<double>(
      1,
      (m, g) => math.max(m, math.max(g.effectiveSets, g.targetMax ?? 0)),
    );
    return SectionCard(
      title: l10n.progressVolumeTitle,
      child: !hasData
          ? Text(l10n.progressVolumeEmpty, style: theme.textTheme.bodyMedium)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _VolumeLegend(),
                for (final g in groups) _VolumeRow(group: g, scale: scale),
              ],
            ),
    );
  }
}

/// Qué significa cada color de la barra (siempre con icono y texto).
class _VolumeLegend extends StatelessWidget {
  const _VolumeLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget item(VolumeStatus status, String label) {
      final style = volumeStatusStyle(status, scheme);
      return Row(
        key: Key('volume-legend-${status.wire}'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: AppSpacing.md, color: style.color),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              item(VolumeStatus.below, l10n.progressVolumeLegendBelow),
              item(VolumeStatus.within, l10n.progressVolumeLegendWithin),
              item(VolumeStatus.above, l10n.progressVolumeLegendAbove),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.progressVolumeLegendBand, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({required this.group, required this.scale});

  final GroupWeekVolume group;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final g = group;
    final style = volumeStatusStyle(g.status, theme.colorScheme);
    final sets = l10n.progressVolumeSets(
      g.effectiveSets,
      l10n.number(g.effectiveSets),
    );
    final detail = g.targetMin == null || g.targetMax == null
        ? sets
        : '$sets · ${l10n.progressVolumeTarget(l10n.number(g.targetMin!), l10n.number(g.targetMax!))}';
    // Una sola lectura para el lector de pantalla (grupo, series, objetivo y
    // estado); lo visible repite lo mismo con texto e icono.
    return Semantics(
      key: Key('volume-${g.group.wire}'),
      container: true,
      excludeSemantics: true,
      label: l10n.progressVolumeBar(
        l10n.groupLabel(g.group.wire),
        l10n.number(g.effectiveSets),
        g.targetMin == null ? '–' : l10n.number(g.targetMin!),
        g.targetMax == null ? '–' : l10n.number(g.targetMax!),
        l10n.volumeStatusLabel(g.status.wire),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.groupLabel(g.group.wire),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Icon(style.icon, size: AppSpacing.md, color: style.color),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    l10n.volumeStatusLabel(g.status.wire),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            VolumeRangeBar(
              value: g.effectiveSets,
              min: g.targetMin,
              max: g.targetMax,
              scaleMax: scale,
              status: g.status,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(detail, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AdherenceSection extends StatelessWidget {
  const _AdherenceSection({required this.adherence});

  final AdherenceResponse adherence;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final planned = adherence.plannedSessions;
    final breakDays = adherence.weeks.fold<int>(0, (s, w) => s + w.breakDays);

    return SectionCard(
      title: l10n.progressAdherenceTitle,
      child: planned == 0
          ? Text(l10n.progressAdherenceEmpty, style: theme.textTheme.bodyMedium)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.progressAdherenceValue(
                    adherence.completedSessions,
                    planned,
                    (adherence.sessionRatio * 100).round(),
                  ),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                ExcludeSemantics(
                  child: LinearProgressIndicator(
                    value: adherence.sessionRatio.clamp(0, 1),
                  ),
                ),
                if (breakDays > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      l10n.progressAdherenceBreakDays(breakDays),
                      key: const Key('adherence-break-days'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
    );
  }
}
