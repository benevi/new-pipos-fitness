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
      expect(find.text('82,5 kg'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(
            'Tendencia de Sentadilla trasera: de 78 a 82,5 kg en 3 sesiones',
          ),
        ),
        findsOneWidget,
      );

      // Volumen semanal frente al objetivo (el significado también en texto).
      expect(find.byType(VolumeRangeBar), findsNWidgets(3));
      expect(find.text('6 series (objetivo 8–12)'), findsOneWidget);
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
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('2 de 3 sesiones (67 %)'), findsOneWidget);
      await harness.drainAndUnmount(tester);
    },
  );
}
