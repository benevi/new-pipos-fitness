/// Envío a la API de las escrituras offline de [PendingMutations]
/// (ADR-0013): nota fija por ejercicio y medidas corporales.
library;

import 'dart:convert';

import '../../data/pipos_api.dart';
import '../../models/body.dart';
import '../../models/notes_breaks.dart';
import 'app_database.dart';
import 'sync_service.dart';

/// Claves lógicas de la cola.
class MutationKeys {
  MutationKeys._();
  static const notePrefix = 'note:';
  static const measurementPrefix = 'measurement:';

  static String note(String exerciseId) => '$notePrefix$exerciseId';
  static String measurement(String date) => '$measurementPrefix$date';
}

class ApiMutationSender implements MutationSender {
  ApiMutationSender({required NotesApi notes, required BodyApi body})
    : _notes = notes,
      _body = body;

  final NotesApi _notes;
  final BodyApi _body;

  @override
  Future<void> send(PendingMutation m) async {
    final p = (jsonDecode(m.payload) as Map).cast<String, dynamic>();
    switch (m.kind) {
      case MutationKind.notePut:
        await _notes.putNote(
          p['exerciseId'] as String,
          ExerciseNoteRequest(
            text: p['text'] as String,
            clientUpdatedAt: m.updatedAt,
          ),
        );
      case MutationKind.noteDelete:
        await _notes.deleteNote(p['exerciseId'] as String);
      case MutationKind.measurementPut:
        await _body.putMeasurement(BodyMeasurement.fromJson(p));
      case MutationKind.measurementDelete:
        await _body.deleteMeasurement(p['date'] as String);
    }
  }
}
