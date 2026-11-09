// Idea 2 (ADR-0013): nota fija por ejercicio. Se edita en modo avión, se ve
// al momento como pendiente y, al volver la red, se envía una sola vez.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

const squat = '00000000-0000-4000-8000-000000000030';
const squatExercise = '00000000-0000-4000-8000-000000000040';
const row = '00000000-0000-4000-8000-000000000031';
const rowExercise = '00000000-0000-4000-8000-000000000043';

void main() {
  testWidgets(
    'editar la nota sin red → pendiente → al volver la red se envía',
    (tester) async {
      usePhoneSize(tester);
      final harness = AppHarness.signedIn();
      await harness.pump(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Asiento en el 4; barra a la altura del pecho.'),
        findsOneWidget,
      );

      harness.setOnline(false);
      await tapKey(tester, 'note-edit-$squat');
      await tester.enterText(find.byKey(const Key('note-field')), '   ');
      await tapKey(tester, 'note-save');
      expect(find.text('Escribe la nota o bórrala.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('note-field')),
        'Asiento en el 5',
      );
      await tapKey(tester, 'note-save', settle: false);
      await pumpFrames(tester);
      expect(find.text('Asiento en el 5'), findsOneWidget);
      expect(find.byKey(const Key('note-pending-$squat')), findsOneWidget);
      expect(harness.backend.notePuts, 0);

      harness.setOnline(true);
      await pumpFrames(tester, frames: 20);
      expect(harness.backend.notePuts, 1);
      expect(harness.backend.notes[squatExercise]!.text, 'Asiento en el 5');
      expect(find.byKey(const Key('note-pending-$squat')), findsNothing);
      expect(find.text('Asiento en el 5'), findsOneWidget);
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets('añadir y borrar una nota con red', (tester) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();

    await tapKey(tester, 'note-add-$row');
    await tester.enterText(
      find.byKey(const Key('note-field')),
      'Agarre neutro',
    );
    await tapKey(tester, 'note-save', settle: false);
    await pumpFrames(tester, frames: 20);
    expect(harness.backend.notes[rowExercise]!.text, 'Agarre neutro');
    expect(find.text('Agarre neutro'), findsOneWidget);

    await tapKey(tester, 'note-edit-$row');
    await tapKey(tester, 'note-delete', settle: false);
    await pumpFrames(tester, frames: 20);
    expect(harness.backend.notes.containsKey(rowExercise), isFalse);
    expect(find.text('Agarre neutro'), findsNothing);
    expect(find.byKey(const Key('note-add-$row')), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });
}
