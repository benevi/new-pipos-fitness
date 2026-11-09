/// Músculos visibles en cada ejercicio (ADR-0014, Fase 1): «Trabaja: …» con
/// los principales y, desplegable, «También: …» con los secundarios. Los usan
/// la tarjeta de Hoy, el Plan y la hoja de cambiar ejercicio. Los datos
/// vienen del catálogo vía la API, ya ordenados (principales primero, en el
/// orden del enum).
library;

import 'package:flutter/material.dart';

import '../app/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/workout.dart';

/// «Cuádriceps, Glúteos» en el idioma de la interfaz.
String muscleNames(AppLocalizations l10n, Iterable<Muscle> muscles) =>
    muscles.map((m) => l10n.muscleLabel(m.wire)).join(', ');

/// Línea «Trabaja: …» (principales). TalkBack la lee tal cual. Nada si no
/// hay músculos (respuesta anterior a la Fase 1 o cambio aún sin confirmar).
class MusclesWorksLine extends StatelessWidget {
  const MusclesWorksLine({super.key, required this.muscles, this.style});

  final List<Muscle> muscles;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (muscles.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Text(
      l10n.musclesWorks(muscleNames(l10n, muscles)),
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// Tarjeta de Hoy: «Trabaja: …» y un botón que despliega «También: …».
class ExerciseMusclesSummary extends StatefulWidget {
  const ExerciseMusclesSummary({
    super.key,
    required this.id,
    required this.muscles,
  });

  /// Sufijo de las claves de test (`muscles-<id>`, …).
  final String id;
  final List<ExerciseMuscleRef> muscles;

  @override
  State<ExerciseMusclesSummary> createState() => _ExerciseMusclesSummaryState();
}

class _ExerciseMusclesSummaryState extends State<ExerciseMusclesSummary> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final primary = widget.muscles.primary;
    final secondary = widget.muscles.secondary;
    if (primary.isEmpty && secondary.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final id = widget.id;
    final icon = ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: Icon(
          Icons.accessibility_new,
          size: AppSpacing.md,
          color: theme.colorScheme.primary,
        ),
      ),
    );
    final works = primary.isEmpty
        ? l10n.musclesAlso(muscleNames(l10n, secondary))
        : l10n.musclesWorks(muscleNames(l10n, primary));
    final line = Text(
      works,
      key: Key('muscles-primary-$id'),
      style: theme.textTheme.bodyMedium,
    );
    // Sin secundarios (o sin principales): solo la línea, sin desplegable.
    if (secondary.isEmpty || primary.isEmpty) {
      return Padding(
        key: Key('muscles-$id'),
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Row(
          children: [
            icon,
            Expanded(child: line),
          ],
        ),
      );
    }
    // La propia línea «Trabaja: …» despliega «También: …» (un solo toque,
    // área ≥ 48 dp). TalkBack lee «Trabaja: …», con estado y pista.
    return Column(
      key: Key('muscles-$id'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          hint: _open
              ? l10n.musclesHideSecondary
              : l10n.musclesShowSecondaryHint,
          child: InkWell(
            key: Key('muscles-toggle-$id'),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
              child: Row(
                children: [
                  icon,
                  Expanded(child: line),
                  ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _open ? '' : '+${secondary.length}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Icon(
                          _open ? Icons.expand_less : Icons.expand_more,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md + AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              l10n.musclesAlso(muscleNames(l10n, secondary)),
              key: Key('muscles-secondary-$id'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Plan: chips de los principales y, detrás de «También:», los secundarios
/// con menos énfasis. El rol se distingue por el texto, no solo por el color.
/// TalkBack lee el grupo entero: «Trabaja: …. También: …».
class ExerciseMuscleChips extends StatelessWidget {
  const ExerciseMuscleChips({
    super.key,
    required this.id,
    required this.muscles,
  });

  final String id;
  final List<ExerciseMuscleRef> muscles;

  @override
  Widget build(BuildContext context) {
    final primary = muscles.primary;
    final secondary = muscles.secondary;
    if (primary.isEmpty && secondary.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = [
      if (primary.isNotEmpty) l10n.musclesWorks(muscleNames(l10n, primary)),
      if (secondary.isNotEmpty) l10n.musclesAlso(muscleNames(l10n, secondary)),
    ].join('. ');
    Widget chip(Muscle m, {required bool main}) => Chip(
      key: Key('muscle-chip-$id-${m.wire}'),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: main
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.surface,
      side: main ? BorderSide.none : BorderSide(color: theme.dividerColor),
      labelStyle:
          (main ? theme.textTheme.labelLarge : theme.textTheme.bodySmall)
              ?.copyWith(
                color: main
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
      label: Text(l10n.muscleLabel(m.wire)),
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Semantics(
        key: Key('muscle-chips-$id'),
        container: true,
        label: label,
        child: ExcludeSemantics(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final m in primary) chip(m, main: true),
              if (secondary.isNotEmpty)
                Text(
                  l10n.musclesAlsoLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              for (final m in secondary) chip(m, main: false),
            ],
          ),
        ),
      ),
    );
  }
}
