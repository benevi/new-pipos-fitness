/// Nota fija por ejercicio (idea 2, ADR-0013): ajustes de máquina, agarre…
/// Se guarda primero en la cola offline (drift) y se envía con
/// `PUT/DELETE /exercises/:id/note` (gana la última escritura por
/// `clientUpdatedAt`). Funciona en modo avión.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tokens.dart';
import '../../core/offline/app_database.dart';
import '../../core/offline/mutation_sender.dart';
import '../../core/offline/offline_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/notes_breaks.dart';

/// Notas editadas en el móvil y aún sin confirmar: exerciseId → texto
/// (null = borrada). Mandan sobre la nota que trae la sesión de hoy.
final pendingNotesProvider = StreamProvider.autoDispose<Map<String, String?>>((
  ref,
) {
  return ref
      .watch(syncServiceProvider)
      .watchMutations(MutationKeys.notePrefix)
      .map(
        (rows) => {
          for (final r in rows)
            r.mutationKey.substring(MutationKeys.notePrefix.length):
                r.kind == MutationKind.notePut ? _textOf(r.payload) : null,
        },
      );
});

String? _textOf(String payload) =>
    (jsonDecode(payload) as Map<String, dynamic>)['text'] as String?;

Future<void> showNoteSheet(
  BuildContext context, {
  required String exerciseId,
  required String exerciseName,
  required String? current,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => _NoteSheet(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      current: current,
    ),
  );
}

class _NoteSheet extends ConsumerStatefulWidget {
  const _NoteSheet({
    required this.exerciseId,
    required this.exerciseName,
    required this.current,
  });

  final String exerciseId;
  final String exerciseName;
  final String? current;

  @override
  ConsumerState<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends ConsumerState<_NoteSheet> {
  late final _text = TextEditingController(text: widget.current ?? '');
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = l10n.noteEmptyError);
      return;
    }
    await _enqueue(MutationKind.notePut, {
      'exerciseId': widget.exerciseId,
      'text': text,
    }, l10n.noteSaved);
  }

  Future<void> _delete() => _enqueue(MutationKind.noteDelete, {
    'exerciseId': widget.exerciseId,
  }, AppLocalizations.of(context).noteDeleted);

  Future<void> _enqueue(
    MutationKind kind,
    Map<String, dynamic> payload,
    String done,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await ref
        .read(syncServiceProvider)
        .enqueueMutation(
          key: MutationKeys.note(widget.exerciseId),
          kind: kind,
          payload: payload,
        );
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.noteSheetTitle(widget.exerciseName),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.noteHint, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('note-field'),
                controller: _text,
                autofocus: true,
                minLines: 2,
                maxLines: 5,
                maxLength: exerciseNoteMax,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.noteFieldLabel,
                  errorText: _error,
                  errorMaxLines: 2,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              Text(l10n.notePrivacy, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const Key('note-save'),
                onPressed: _save,
                child: Text(l10n.noteSave),
              ),
              if (widget.current != null) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  key: const Key('note-delete'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, AppSpacing.xxl),
                  ),
                  onPressed: _delete,
                  child: Text(l10n.noteDelete),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
