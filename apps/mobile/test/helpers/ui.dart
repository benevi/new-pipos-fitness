import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Desplaza hasta el widget (si hace falta) y lo pulsa.
Future<void> tapKey(
  WidgetTester tester,
  String key, {
  bool settle = true,
}) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    // Listas perezosas: el elemento aún no está construido. Se busca
    // primero hacia arriba y luego hacia abajo.
    try {
      await tester.scrollUntilVisible(
        finder,
        -200,
        scrollable: verticalScrollable(),
        maxScrolls: 30,
      );
    } on StateError {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: verticalScrollable(),
      );
    }
  }
  // Centrado: que no quede bajo la AppBar ni bajo la barra inferior.
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump();
  await tester.tap(finder);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// Tamaño de móvil (390 × 844 lógicos).
void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Deja correr frames y microtareas (drift, cola de sync, Dio) sin
/// esperar a que se asiente (el temporizador de descanso no se asienta).
Future<void> pumpFrames(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Vuelve al principio de la lista de Hoy.
Future<void> scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byKey(const Key('today-list')), const Offset(0, 3000));
  await pumpFrames(tester, frames: 5);
}

/// La lista vertical visible más interna (no el Scrollable de un TextField).
Finder verticalScrollable() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .last;
