/// Mapa de calor de la semana (ADR-0014, Fase 3b; promovido desde LATER en
/// ADR-0013): la figura del cuerpo con cada región según las series
/// efectivas de la semana de su grupo frente al rango objetivo
/// (`GET /progress/volume`).
///
/// Tres estados (por debajo, dentro, por encima) más «sin objetivo», cada
/// uno con color **y** trama propia, y leyenda visible. El texto dice solo
/// lo que es: «series de esta semana frente a tu objetivo»; nada de
/// recuperación ni predicciones (rechazado en ADR-0013). Las barras por
/// grupo de Progreso siguen debajo como alternativa en lista.
library;

import 'package:flutter/material.dart';

import '../../app/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/enums.dart';
import '../../models/progress.dart';
import '../../shared/widgets.dart';
import 'body_figure.dart';
import 'body_geometry.dart';
import 'exercises_screen.dart' show sideLabel;
import 'muscle_groups.dart';

/// Estilo de una región según el estado de su grupo (null: el músculo no
/// cuenta para ningún grupo).
RegionStyle heatRegionStyle(VolumeStatus? status, ColorScheme scheme) =>
    switch (status) {
      VolumeStatus.below => RegionStyle(
        fill: scheme.surface,
        pattern: RegionPattern.hatch,
        ink: scheme.onSurfaceVariant,
      ),
      VolumeStatus.within => RegionStyle(
        fill: scheme.primary,
        pattern: RegionPattern.solid,
        ink: scheme.primary,
      ),
      VolumeStatus.above => RegionStyle(
        fill: scheme.error.withValues(alpha: 0.2),
        pattern: RegionPattern.crossHatch,
        ink: scheme.error,
      ),
      VolumeStatus.noTarget || null => RegionStyle(
        fill: scheme.surfaceContainerHighest,
        pattern: RegionPattern.dots,
        ink: scheme.outline,
      ),
    };

class WeeklyHeatmap extends StatelessWidget {
  const WeeklyHeatmap({super.key, required this.week});

  final VolumeWeek? week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groups = week?.groups ?? const <GroupWeekVolume>[];
    final hasData = groups.any(
      (g) => g.effectiveSets > 0 || g.targetMax != null,
    );
    if (!hasData) {
      return SectionCard(
        key: const Key('heatmap'),
        title: l10n.progressHeatmapTitle,
        child: Text(
          l10n.progressHeatmapEmpty,
          key: const Key('heatmap-empty'),
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    final byGroup = {for (final g in groups) g.group: g};
    GroupWeekVolume? groupOf(Muscle m) {
      final g = muscleVolumeGroup[m];
      return g == null ? null : byGroup[g];
    }

    VolumeStatus? statusOf(Muscle m) {
      if (muscleVolumeGroup[m] == null) return null;
      return groupOf(m)?.status ?? VolumeStatus.noTarget;
    }

    String labelOf(BodyRegion r) {
      final muscle = l10n.muscleLabel(r.muscle.wire);
      final group = muscleVolumeGroup[r.muscle];
      if (group == null) return l10n.progressHeatmapRegionNoGroup(muscle);
      final v = groupOf(r.muscle);
      return l10n.progressHeatmapRegion(
        muscle,
        l10n.groupLabel(group.wire),
        l10n.number(v?.effectiveSets ?? 0),
        v?.targetMin == null ? '–' : l10n.number(v!.targetMin!),
        v?.targetMax == null ? '–' : l10n.number(v!.targetMax!),
        l10n.volumeStatusLabel((v?.status ?? VolumeStatus.noTarget).wire),
      );
    }

    final scheme = theme.colorScheme;
    Widget figure(BodySide side) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sideLabel(l10n, side),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        BodyFigure(
          key: Key('heatmap-figure-${side.name}'),
          side: side,
          styleFor: (r) => heatRegionStyle(statusOf(r.muscle), scheme),
          labelFor: labelOf,
        ),
      ],
    );

    return SectionCard(
      key: const Key('heatmap'),
      title: l10n.progressHeatmapTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.progressHeatmapSubtitle,
            key: const Key('heatmap-subtitle'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const HeatmapLegend(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: figure(BodySide.front)),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: figure(BodySide.back)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.progressHeatmapListNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Leyenda siempre visible: muestra de cada trama y su texto.
class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget item(VolumeStatus status, String label) => Row(
      key: Key('heatmap-legend-${status.wire}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        RegionSwatch(style: heatRegionStyle(status, theme.colorScheme)),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label, style: theme.textTheme.bodySmall)),
      ],
    );
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        item(VolumeStatus.below, l10n.progressVolumeLegendBelow),
        item(VolumeStatus.within, l10n.progressVolumeLegendWithin),
        item(VolumeStatus.above, l10n.progressVolumeLegendAbove),
        item(VolumeStatus.noTarget, l10n.progressHeatmapLegendNoTarget),
      ],
    );
  }
}
