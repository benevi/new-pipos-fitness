/// Corregir una serie ya registrada (#22): reps, kg (con el separador
/// decimal del idioma) y RIR. Devuelve los valores nuevos o null si se
/// cancela; quien la abre los pasa a la cola offline (`SyncService`).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/decimal_input.dart';

typedef EditedSet = ({int reps, double loadKg, int? rir});

Future<EditedSet?> showEditSetSheet(
  BuildContext context, {
  required int setNumber,
  required bool weighted,
  required int reps,
  required double loadKg,
  required int? rir,
}) {
  return showModalBottomSheet<EditedSet>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => _EditSetSheet(
      setNumber: setNumber,
      weighted: weighted,
      reps: reps,
      loadKg: loadKg,
      rir: rir,
    ),
  );
}

class _EditSetSheet extends StatefulWidget {
  const _EditSetSheet({
    required this.setNumber,
    required this.weighted,
    required this.reps,
    required this.loadKg,
    required this.rir,
  });

  final int setNumber;
  final bool weighted;
  final int reps;
  final double loadKg;
  final int? rir;

  @override
  State<_EditSetSheet> createState() => _EditSetSheetState();
}

class _EditSetSheetState extends State<_EditSetSheet> {
  late final _reps = TextEditingController(text: '${widget.reps}');
  final _load = TextEditingController();
  late int? _rir = widget.rir;
  bool _loadPrefilled = false;
  String? _repsError;
  String? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadPrefilled) {
      _loadPrefilled = true;
      _load.text = formatDecimalInput(
        widget.loadKg,
        AppLocalizations.of(context).localeName,
      );
    }
  }

  @override
  void dispose() {
    _reps.dispose();
    _load.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final reps = int.tryParse(_reps.text.trim());
    final load = widget.weighted
        ? parseDecimalInput(_load.text)
        : widget.loadKg;
    setState(() {
      _repsError = reps == null || reps < 0 || reps > 100
          ? l10n.validationRange('0', '100')
          : null;
      _loadError = load == null || load < 0 || load > 1000
          ? l10n.validationRange('0', '1000')
          : null;
    });
    if (_repsError != null || _loadError != null) return;
    Navigator.of(context).pop((reps: reps!, loadKg: load!, rir: _rir));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.setEditTitle(widget.setNumber),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.setEditHint, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('edit-set-reps'),
                      controller: _reps,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l10n.fieldReps,
                        errorText: _repsError,
                        errorMaxLines: 2,
                      ),
                    ),
                  ),
                  if (widget.weighted) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        key: const Key('edit-set-load'),
                        controller: _load,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.fieldLoad,
                          errorText: _loadError,
                          errorMaxLines: 2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.rirPickerTitle, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var r = 0; r <= 5; r++)
                    ChoiceChip(
                      key: Key('edit-set-rir-$r'),
                      label: Text(l10n.rirValue(r)),
                      selected: _rir == r,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: (_) => setState(() => _rir = r),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const Key('edit-set-save'),
                onPressed: _save,
                child: Text(l10n.setEditSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
