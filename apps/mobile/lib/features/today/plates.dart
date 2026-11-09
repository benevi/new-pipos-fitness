/// Carga real según el material y discos (idea 1, ADR-0013;
/// PROGRAMACION.md §16.16). La API da el desglose de la carga sugerida
/// (`TodayExercise.plates`); al editar la carga se recalcula aquí sin red con
/// la misma regla que el motor (`plateBreakdown`, voraz de mayor a menor).
library;

import 'package:flutter/material.dart';

import '../../app/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/enums.dart';
import '../../models/workout.dart';

/// Discos estándar por lado (kg), de mayor a menor (`PROGRAMMING.load.platesKg`).
const standardPlatesKg = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

/// Barra vacía por material (`PROGRAMMING.load.barKg`); la guiada no se
/// desglosa porque su peso varía.
double? barKgFor(LoadImplement? implement) => switch (implement) {
  LoadImplement.barbell => 20,
  LoadImplement.ezBar => 10,
  LoadImplement.trapBar => 25,
  _ => null,
};

double _cents(double v) => (v * 100).round() / 100;

/// Discos por lado para montar [totalKg] en una barra de [barKg]. null si el
/// total es menor que la barra. Misma regla que `plateBreakdown` del motor.
PlateBreakdown? plateBreakdown(
  double totalKg,
  double barKg, {
  List<double> plates = standardPlatesKg,
}) {
  const eps = 1e-9;
  if (!totalKg.isFinite || totalKg < barKg - eps) return null;
  var side = (totalKg - barKg) / 2;
  final perSide = <double>[];
  for (final p in plates) {
    while (side >= p - eps) {
      perSide.add(p);
      side = _cents(side - p);
    }
  }
  final loaded = barKg + 2 * perSide.fold<double>(0, (s, p) => s + p);
  return PlateBreakdown(
    barKg: barKg,
    perSide: perSide,
    remainderKg: _cents(totalKg - loaded).clamp(0, double.infinity),
  );
}

/// Hoja «Discos»: barra, discos por lado y lo que no cuadra.
Future<void> showPlatesSheet(
  BuildContext context, {
  required double totalKg,
  required double barKg,
  PlateBreakdown? breakdown,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) => _PlatesSheet(
      totalKg: totalKg,
      barKg: barKg,
      breakdown: breakdown ?? plateBreakdown(totalKg, barKg),
    ),
  );
}

class _PlatesSheet extends StatelessWidget {
  const _PlatesSheet({
    required this.totalKg,
    required this.barKg,
    required this.breakdown,
  });

  final double totalKg;
  final double barKg;
  final PlateBreakdown? breakdown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final b = breakdown;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          key: const Key('plates-sheet'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.platesTitle(l10n.kgPrecise(totalKg)),
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.platesBar(l10n.kgPrecise(barKg)),
              key: const Key('plates-bar'),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (b == null)
              Text(
                l10n.platesBelowBar(l10n.kgPrecise(barKg)),
                key: const Key('plates-below-bar'),
              )
            else ...[
              Text(
                b.perSide.isEmpty
                    ? l10n.platesOnlyBar
                    : l10n.platesPerSide(
                        b.perSide.map(l10n.kgPrecise).join(' + '),
                      ),
                key: const Key('plates-per-side'),
                style: theme.textTheme.titleMedium,
              ),
              if (b.perSide.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final p in b.perSide)
                      Chip(
                        avatar: const Icon(Icons.circle_outlined),
                        label: Text(l10n.kgPrecise(p)),
                      ),
                  ],
                ),
              ],
              if (b.remainderKg > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.platesRemainder(l10n.kgPrecise(b.remainderKg)),
                  key: const Key('plates-remainder'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.platesHelp, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
