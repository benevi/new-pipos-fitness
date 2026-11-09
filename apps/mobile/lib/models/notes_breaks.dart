/// Notas fijas por ejercicio (contracts/src/schemas/notes.ts) y pausas
/// planificadas (contracts/src/schemas/breaks.ts). ADR-0013, ideas 2 y 6.
library;

import 'json.dart';

/// Longitud máxima de la nota (EXERCISE_NOTE_MAX).
const exerciseNoteMax = 280;

/// Duración máxima de una pausa, ambos extremos incluidos.
const trainingBreakMaxDays = 60;

class ExerciseNote {
  const ExerciseNote({
    required this.exerciseId,
    required this.slug,
    required this.text,
    required this.clientUpdatedAt,
    required this.updatedAt,
  });

  final String exerciseId;
  final String slug;
  final String text;
  final DateTime clientUpdatedAt;
  final DateTime updatedAt;

  factory ExerciseNote.fromJson(Json j) => ExerciseNote(
    exerciseId: j.str('exerciseId'),
    slug: j.str('slug'),
    text: j.str('text'),
    clientUpdatedAt: j.dateTime('clientUpdatedAt'),
    updatedAt: j.dateTime('updatedAt'),
  );

  Json toJson() => {
    'exerciseId': exerciseId,
    'slug': slug,
    'text': text,
    'clientUpdatedAt': isoUtc(clientUpdatedAt),
    'updatedAt': isoUtc(updatedAt),
  };
}

/// PUT /exercises/:id/note (última escritura gana por `clientUpdatedAt`).
class ExerciseNoteRequest {
  const ExerciseNoteRequest({
    required this.text,
    required this.clientUpdatedAt,
  });

  final String text;
  final DateTime clientUpdatedAt;

  Json toJson() => {'text': text, 'clientUpdatedAt': isoUtc(clientUpdatedAt)};
}

/// PATCH /me/profile/schedule (ISO: 1 = lunes … 7 = domingo).
class ProfileScheduleRequest {
  const ProfileScheduleRequest(this.trainingWeekdays);

  final List<int> trainingWeekdays;

  Json toJson() => {'trainingWeekdays': trainingWeekdays};
}

class ExerciseNoteList {
  const ExerciseNoteList(this.items);

  final List<ExerciseNote> items;

  factory ExerciseNoteList.fromJson(Json j) =>
      ExerciseNoteList(j.objList('items', ExerciseNote.fromJson));

  Json toJson() => {'items': items.map((n) => n.toJson()).toList()};
}

/// Fecha de calendario `YYYY-MM-DD` (sin zona).
String calendarDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Lee `YYYY-MM-DD` como fecha local a medianoche.
DateTime parseCalendarDate(String s) {
  final parts = s.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

class TrainingBreak {
  const TrainingBreak({
    required this.id,
    required this.clientId,
    required this.startsOn,
    required this.endsOn,
    required this.createdAt,
  });

  final String id;
  final String clientId;
  final String startsOn;
  final String endsOn;
  final DateTime createdAt;

  /// ¿La pausa cubre [day] (fecha local)?
  bool covers(DateTime day) {
    final d = calendarDate(day);
    return d.compareTo(startsOn) >= 0 && d.compareTo(endsOn) <= 0;
  }

  factory TrainingBreak.fromJson(Json j) => TrainingBreak(
    id: j.str('id'),
    clientId: j.str('clientId'),
    startsOn: j.str('startsOn'),
    endsOn: j.str('endsOn'),
    createdAt: j.dateTime('createdAt'),
  );

  Json toJson() => {
    'id': id,
    'clientId': clientId,
    'startsOn': startsOn,
    'endsOn': endsOn,
    'createdAt': isoUtc(createdAt),
  };
}

class TrainingBreakList {
  const TrainingBreakList(this.items);

  final List<TrainingBreak> items;

  factory TrainingBreakList.fromJson(Json j) =>
      TrainingBreakList(j.objList('items', TrainingBreak.fromJson));

  Json toJson() => {'items': items.map((b) => b.toJson()).toList()};
}

/// POST /me/breaks (idempotente por `clientId`).
class CreateTrainingBreakRequest {
  const CreateTrainingBreakRequest({
    required this.clientId,
    required this.startsOn,
    required this.endsOn,
  });

  final String clientId;
  final String startsOn;
  final String endsOn;

  factory CreateTrainingBreakRequest.fromJson(Json j) =>
      CreateTrainingBreakRequest(
        clientId: j.str('clientId'),
        startsOn: j.str('startsOn'),
        endsOn: j.str('endsOn'),
      );

  Json toJson() => {
    'clientId': clientId,
    'startsOn': startsOn,
    'endsOn': endsOn,
  };
}
