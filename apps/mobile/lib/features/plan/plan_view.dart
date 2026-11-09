/// Vista de un plan: reparto y por qué, avisos del motor, volumen semanal
/// por grupo y sesiones con cada ejercicio (series × reps, RIR, descanso y
/// su explicación desplegable). La usan «Plan», el resultado del
/// cuestionario y el historial de versiones.
library;

import 'package:flutter/material.dart';

import '../../app/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/enums.dart';
import '../../models/plan.dart';

import '../../shared/widgets.dart';

class PlanOverview extends StatelessWidget {
  const PlanOverview({
    super.key,
    required this.plan,
    this.rationaleExpanded = false,
    this.header,
    this.onUnpin,
  });

  final PlanVersion plan;
  final bool rationaleExpanded;
  final Widget? header;

  /// Volver al ejercicio original de un hueco fijado (solo el plan vigente).
  final Future<void> Function(PlanExercise exercise)? onUnpin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        ?header,
        SectionCard(
          title: l10n.splitLabel(plan.splitType.wire),
          trailing: Text(
            l10n.planVersionLabel(plan.version),
            style: theme.textTheme.bodySmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.planWhySplit, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              for (final line in [...plan.splitRationale, ...plan.rationale])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text('• $line', style: theme.textTheme.bodyMedium),
                ),
            ],
          ),
        ),
        if (plan.warnings.isNotEmpty)
          SectionCard(
            title: l10n.planWarnings,
            child: Column(
              key: const Key('plan-warnings'),
              children: [
                for (final (i, w) in plan.warnings.indexed)
                  NoticeBanner(
                    key: w.code == WarningCode.pinnedSubstitutionDropped
                        ? const Key('warning-pin-dropped')
                        : null,
                    text: w.code == WarningCode.pinnedSubstitutionDropped
                        ? '${l10n.pinDroppedTitle} ${w.message}'
                        : w.message,
                    icon: w.code == WarningCode.pinnedSubstitutionDropped
                        ? Icons.push_pin_outlined
                        : Icons.warning_amber_outlined,
                    // Sin hueco extra al final de la tarjeta.
                    margin: EdgeInsets.only(
                      bottom: i == plan.warnings.length - 1 ? 0 : AppSpacing.sm,
                    ),
                  ),
              ],
            ),
          ),
        if (plan.weeklyVolume.isNotEmpty)
          SectionCard(
            title: l10n.planWeeklyVolume,
            child: Column(
              children: [
                for (final g in plan.weeklyVolume)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(child: Text(l10n.groupLabel(g.group.wire))),
                        Flexible(
                          child: Text(
                            l10n.planVolumeRange(
                              l10n.number(g.effectiveSets),
                              l10n.number(g.min),
                              l10n.number(g.max),
                            ),
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Semantics(
            header: true,
            child: Text(l10n.planSessions, style: theme.textTheme.titleLarge),
          ),
        ),
        for (final s in plan.sessions)
          _SessionCard(
            session: s,
            expanded:
                (rationaleExpanded && s.order == 0) ||
                s.exercises.any((e) => e.pinned != null),
            onUnpin: onUnpin,
          ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.expanded,
    this.onUnpin,
  });

  final PlanSession session;
  final bool expanded;
  final Future<void> Function(PlanExercise exercise)? onUnpin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: expanded,
        minTileHeight: AppSpacing.xxl + AppSpacing.md,
        title: Text(session.name, style: theme.textTheme.titleMedium),
        subtitle: Text(
          l10n.planSessionMeta(
            l10n.weekdayLabel('${session.dayIndex}'),
            session.estimatedMinutes.round(),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RationaleExpander(lines: session.rationale),
          for (final e in session.exercises)
            _ExerciseRow(exercise: e, onUnpin: onUnpin),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, this.onUnpin});

  final PlanExercise exercise;
  final Future<void> Function(PlanExercise exercise)? onUnpin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exercise.pinned != null) ...[
            Text(exercise.pinned!.nameEs, style: theme.textTheme.titleSmall),
            Row(
              key: Key('plan-pinned-${exercise.id}'),
              children: [
                Icon(
                  Icons.push_pin,
                  size: AppSpacing.md,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.pinnedInsteadOf(exercise.nameEs),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (onUnpin != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: Key('unpin-${exercise.id}'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
                  ),
                  onPressed: () => onUnpin!(exercise),
                  icon: const Icon(Icons.undo),
                  label: Text(l10n.unpinAction(exercise.nameEs)),
                ),
              ),
          ] else
            Text(exercise.nameEs, style: theme.textTheme.titleSmall),
          Text(
            l10n.planExerciseLine(
              exercise.sets,
              exercise.repMin,
              exercise.repMax,
              exercise.targetRir,
              exercise.restSeconds,
            ),
            style: theme.textTheme.bodyMedium,
          ),
          if (exercise.initialLoadKg != null)
            Text(
              exercise.initialLoadIsEstimate
                  ? '${l10n.todayInitialEstimate}: ${l10n.kg(exercise.initialLoadKg!)}'
                  : l10n.todaySuggestedLoad(l10n.kg(exercise.initialLoadKg!)),
              style: theme.textTheme.bodySmall,
            )
          else if (exercise.initialLoadIsEstimate)
            Text(l10n.todayInitialEstimate, style: theme.textTheme.bodySmall),
          RationaleExpander(lines: exercise.rationale),
          const Divider(),
        ],
      ),
    );
  }
}
