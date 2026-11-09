// Idea 1 (ADR-0013): carga real según el material. La hoja «Discos» muestra
// el desglose por lado de la carga sugerida (el de la API) y, al mover la
// carga con − / + (paso real del material), el recalculado sin red.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/today/plates.dart';
import 'package:pipos_fitness/models/enums.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

const squat = '00000000-0000-4000-8000-000000000030';
const row = '00000000-0000-4000-8000-000000000031';
const pushup = '00000000-0000-4000-8000-000000000032';

String _loadText(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(const Key('load-$squat')))
    .controller!
    .text;

void main() {
  group('plateBreakdown (misma regla que el motor)', () {
    test('62,5 kg en barra de 20: 20 + 1,25 por lado, exacto', () {
      final b = plateBreakdown(62.5, 20)!;
      expect(b.perSide, [20, 1.25]);
      expect(b.remainderKg, 0);
    });

    test('lo que no cuadra va en remainderKg', () {
      final b = plateBreakdown(63, 20)!;
      expect(b.perSide, [20, 1.25]);
      expect(b.remainderKg, 0.5);
    });

    test('menos que la barra: null; solo la barra: sin discos', () {
      expect(plateBreakdown(15, 20), isNull);
      expect(plateBreakdown(20, 20)!.perSide, isEmpty);
      expect(plateBreakdown(140, 20)!.perSide, [25, 25, 10]);
    });

    test('solo se desglosan las barras con peso conocido', () {
      expect(barKgFor(LoadImplement.barbell), 20);
      expect(barKgFor(LoadImplement.smithMachine), isNull);
      expect(barKgFor(LoadImplement.dumbbell), isNull);
    });
  });

  testWidgets('Discos de la carga sugerida y − / + por el paso real', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();

    // Material y paso real; «Discos» solo en la barra.
    expect(find.text('Barra · de 2,5 kg en 2,5 kg'), findsOneWidget);
    expect(find.byKey(const Key('plates-$row')), findsNothing);
    expect(find.byKey(const Key('load-minus-$pushup')), findsNothing);

    await tapKey(tester, 'plates-$squat');
    expect(find.text('Discos para 62,5 kg'), findsOneWidget);
    expect(find.text('Barra: 20 kg'), findsOneWidget);
    expect(find.text('Por lado: 20 kg + 1,25 kg'), findsOneWidget);
    expect(find.byKey(const Key('plates-remainder')), findsNothing);
    Navigator.of(tester.element(find.byKey(const Key('plates-sheet')))).pop();
    await tester.pumpAndSettle();

    expect(_loadText(tester), '62,5');
    await tapKey(tester, 'load-plus-$squat');
    expect(_loadText(tester), '65');
    await tapKey(tester, 'row-plates-$squat');
    expect(find.text('Por lado: 20 kg + 2,5 kg'), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const Key('plates-sheet')))).pop();
    await tester.pumpAndSettle();

    await tapKey(tester, 'load-minus-$squat');
    await tapKey(tester, 'load-minus-$squat');
    expect(_loadText(tester), '60');

    // Mancuernas: el paso es de 2 kg; sin barra no hay «Discos».
    await tester.scrollUntilVisible(
      find.text('Mancuernas · de 2 kg en 2 kg'),
      200,
      scrollable: verticalScrollable(),
    );
    await tester.enterText(find.byKey(const Key('load-$row')), '20');
    await tapKey(tester, 'load-plus-$row');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('load-$row')))
          .controller!
          .text,
      '22',
    );
    expect(find.byKey(const Key('row-plates-$row')), findsNothing);
    await harness.drainAndUnmount(tester);
  });
}
