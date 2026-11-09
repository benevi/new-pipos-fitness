/// Controles accesibles del cuestionario: opciones excluyentes, chips de
/// selección múltiple, mensaje de error de campo y selector de ejercicios.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tokens.dart';
import '../../data/pipos_api.dart';
import '../../l10n/app_localizations.dart';
import '../../models/progress.dart';
import 'profile_draft.dart';

/// Título de pregunta (anunciado como cabecera).
class QuestionTitle extends StatelessWidget {
  const QuestionTitle(this.text, {super.key, this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(text, style: theme.textTheme.titleLarge),
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(hint!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Error inline de un campo (se anuncia al aparecer).
class FieldErrorText extends StatelessWidget {
  const FieldErrorText(this.message, {super.key});

  final FieldMessage? message;

  @override
  Widget build(BuildContext context) {
    final m = message;
    if (m == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: AppSpacing.md + AppSpacing.xs,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                m(AppLocalizations.of(context)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de opciones excluyentes (una tarjeta por opción, ≥ 48 dp).
class SingleChoiceList<T> extends StatelessWidget {
  const SingleChoiceList({
    super.key,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.keyPrefix,
  });

  final List<T> options;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Semantics(
              inMutuallyExclusiveGroup: true,
              selected: o == selected,
              button: true,
              child: Material(
                color: o == selected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  key: keyPrefix == null
                      ? null
                      : Key('$keyPrefix-${_keyOf(o)}'),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => onSelected(o),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSpacing.xxl + AppSpacing.sm,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.ms,
                      ),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              o == selected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: o == selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.ms),
                          Expanded(
                            child: Text(
                              label(o),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _keyOf(Object? o) => o is Enum ? o.name : '$o';
}

/// Chips de selección múltiple (o única con [single]).
class ChipChoices<T> extends StatelessWidget {
  const ChipChoices({
    super.key,
    required this.options,
    required this.isSelected,
    required this.label,
    required this.onToggle,
    this.keyPrefix,
    this.single = false,
  });

  final List<T> options;
  final bool Function(T) isSelected;
  final String Function(T) label;
  final ValueChanged<T> onToggle;
  final String? keyPrefix;
  final bool single;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final o in options)
          single
              ? ChoiceChip(
                  key: keyPrefix == null
                      ? null
                      : Key('$keyPrefix-${SingleChoiceList._keyOf(o)}'),
                  label: Text(label(o)),
                  selected: isSelected(o),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => onToggle(o),
                )
              : FilterChip(
                  key: keyPrefix == null
                      ? null
                      : Key('$keyPrefix-${SingleChoiceList._keyOf(o)}'),
                  label: Text(label(o)),
                  selected: isSelected(o),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => onToggle(o),
                ),
      ],
    );
  }
}

/// Hoja de búsqueda en el catálogo (`GET /exercises?q=`).
Future<ExerciseSummary?> showExercisePicker(BuildContext context) {
  return showModalBottomSheet<ExerciseSummary>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ExercisePicker(),
  );
}

class _ExercisePicker extends ConsumerStatefulWidget {
  const _ExercisePicker();

  @override
  ConsumerState<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends ConsumerState<_ExercisePicker> {
  Timer? _debounce;
  List<ExerciseSummary> _results = const [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final page = await ref.read(catalogApiProvider).searchExercises(query: q);
      if (mounted) setState(() => _results = page.items);
    } catch (_) {
      if (mounted) setState(() => _results = const []);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _searched = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.exercisePickerTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('exercise-search'),
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.exercisePickerHint,
                prefixIcon: const Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: _search,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: _searched && _results.isEmpty && !_loading
                  ? Center(child: Text(l10n.exercisePickerEmpty))
                  : ListView(
                      children: [
                        for (final e in _results)
                          ListTile(
                            title: Text(e.localizedName(lang)),
                            onTap: () => Navigator.of(context).pop(e),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
