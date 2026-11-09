import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/progress/charts.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

Future<AppHarness> openProgress(
  WidgetTester tester,
  FakeBackend backend,
) async {
  usePhoneSize(tester);
  final harness = AppHarness.signedIn(backend: backend);
  await harness.pump(tester);
  await tester.pumpAndSettle();
  await tapKey(tester, 'nav-progress');
  return harness;
}

void main() {
  testWidgets('sin datos: un único estado vacío que explica qué hacer', (
    tester,
  ) async {
    final harness = await openProgress(
      tester,
      FakeBackend(progressEmpty: true),
    );
    expect(find.byKey(const Key('progress-empty')), findsOneWidget);
    expect(find.text('Tu progreso aparecerá aquí'), findsOneWidget);
    expect(find.byType(Sparkline), findsNothing);
    await harness.drainAndUnmount(tester);
  });

  testWidgets(
    'con datos: e1RM con tendencia, volumen frente al rango y adherencia',
    (tester) async {
      final harness = await openProgress(tester, FakeBackend());
      expect(find.byKey(const Key('progress-filled')), findsOneWidget);

      // e1RM.
      expect(find.text('Sentadilla trasera'), findsOneWidget);
      // Valor actual + máximo del eje.
      expect(find.text('82,5 kg'), findsNWidgets(2));
      // Contexto de ejes: mínimo/máximo con unidad y fechas primera/última.
      const chart = Key('e1rm-chart-00000000-0000-4000-8000-000000000040');
      Finder inChart(String key) => find.descendant(
        of: find.byKey(chart),
        matching: find.byKey(Key(key)),
      );
      expect(tester.widget<Text>(inChart('chart-min')).data, '78 kg');
      expect(tester.widget<Text>(inChart('chart-max')).data, '82,5 kg');
      expect(tester.widget<Text>(inChart('chart-first')).data, '26 oct');
      expect(tester.widget<Text>(inChart('chart-last')).data, '9 nov');
      expect(
        find.bySemanticsLabel(
          'Sentadilla trasera: de 78 a 82,5 kg entre el 26 oct y el 9 nov '
          '(3 sesiones)',
        ),
        findsOneWidget,
      );

      // Volumen semanal frente al objetivo (el significado también en texto).
      expect(find.byType(VolumeRangeBar), findsNWidgets(3));
      // Unidades en todas las filas, también sin objetivo («0 series»).
      expect(find.text('6 series · objetivo 8–12'), findsOneWidget);
      expect(find.text('11 series · objetivo 10–14'), findsOneWidget);
      expect(find.text('0 series'), findsOneWidget);
      // Leyenda y estado con icono + texto (no solo color).
      expect(find.byKey(const Key('volume-legend-below')), findsOneWidget);
      expect(find.byKey(const Key('volume-legend-within')), findsOneWidget);
      expect(find.byKey(const Key('volume-legend-above')), findsOneWidget);
      expect(find.text('Dentro del rango'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('volume-quads')),
          matching: find.byIcon(Icons.arrow_downward),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('volume-quads')),
          matching: find.text('por debajo'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('volume-glutes')),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Cuádriceps: 6 series, objetivo 8 a 12, por debajo'),
        ),
        findsOneWidget,
      );

      // Adherencia.
      await tester.scrollUntilVisible(
        find.text('2 de 3 sesiones (67 %)'),
        200,
        scrollable: verticalScrollable(),
      );
      expect(find.text('2 de 3 sesiones (67 %)'), findsOneWidget);
      await harness.drainAndUnmount(tester);
    },
  );
}
