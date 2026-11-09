import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/auth/login_screen.dart';

import 'helpers/app_harness.dart';

void main() {
  testWidgets('la app arranca sin sesión y muestra el login (sin plugins)', (
    tester,
  ) async {
    final harness = AppHarness();
    await harness.pump(tester);
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
