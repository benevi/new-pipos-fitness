// Pulido de Hoy: kg con el separador decimal del idioma (y entrada con coma
// o punto), hueco bajo «¿Poco tiempo hoy?», etiquetas flotantes con aire
// bajo «Serie 1» e icono de nota distinto de la chincheta del cambio fijado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/shared/decimal_input.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

const squat = '00000000-0000-4000-8000-000000000030';

String _load(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(const Key('load-$squat')))
    .controller!
    .text;

void main() {
  group('parseDecimalInput', () {
    test('acepta coma y punto, con espacios', () {
      expect(parseDecimalInput('62,5'), 62.5);
      expect(parseDecimalInput('62.5'), 62.5);
      expect(parseDecimalInput(' 62,25 '), 62.25);
      expect(parseDecimalInput('60'), 60);
      expect(parseDecimalInput(',5'), 0.5);
      expect(parseDecimalInput('62,'), 62);
    });

    test('rechaza lo que no es un número con un solo separador', () {
      for (final bad in ['', ' ', 'abc', '62,5,0', '1.062,5', '6 2a', '-5']) {
        expect(parseDecimalInput(bad), isNull, reason: bad);
      }
    });

    test('formatDecimalInput usa el separador del idioma, sin miles', () {
      expect(formatDecimalInput(62.5, 'es'), '62,5');
      expect(formatDecimalInput(62.25, 'es'), '62,25');
      expect(formatDecimalInput(60, 'es'), '60');
      expect(formatDecimalInput(1062.5, 'es'), '1062,5');
      expect(formatDecimalInput(62.5, 'en'), '62.5');
    });
  });

  testWidgets('Hoy: kg con coma, entrada con punto o coma y espaciados', (
    tester,
  ) async {
    usePhoneSize(tester);
    final semantics = tester.ensureSemantics();
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();

    // Hueco bajo «¿Poco tiempo hoy?» antes del siguiente aviso.
    expect(find.byKey(const Key('adjust-open')), findsOneWidget);
    final block = tester.getRect(find.byKey(const Key('adjust-gap')));
    final button = tester.getRect(find.byKey(const Key('adjust-open')));
    expect(block.bottom - button.bottom, greaterThanOrEqualTo(8));

    // Carga sugerida mostrada con coma decimal.
    expect(_load(tester), '62,5');
    // Con punto también se entiende: − / + parten del valor escrito.
    await tester.enterText(find.byKey(const Key('load-$squat')), '60.5');
    await tapKey(tester, 'load-plus-$squat');
    expect(_load(tester), '63');
    await tester.enterText(find.byKey(const Key('load-$squat')), '60,5');
    await tapKey(tester, 'load-minus-$squat');
    expect(_load(tester), '58');

    // Etiqueta flotante (Reps) con aire bajo «Serie 1».
    final setLabel = tester.getRect(find.text('Serie 1').first);
    final reps = tester.getRect(find.byKey(const Key('reps-$squat')));
    expect(reps.top - setLabel.bottom, greaterThanOrEqualTo(12));

    // La nota usa un icono de nota, no la chincheta del cambio fijado.
    final note = find.byKey(const Key('note-$squat'));
    expect(
      find.descendant(
        of: note,
        matching: find.byIcon(Icons.sticky_note_2_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: note, matching: find.byIcon(Icons.push_pin_outlined)),
      findsNothing,
    );
    await tester.ensureVisible(note);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Tu nota')), findsWidgets);
    semantics.dispose();
    await harness.drainAndUnmount(tester);
  });
}
