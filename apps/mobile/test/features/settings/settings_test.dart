import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/core/offline/offline_providers.dart';
import 'package:pipos_fitness/features/auth/auth_provider.dart';
import 'package:pipos_fitness/features/auth/login_screen.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

Future<AppHarness> openSettings(
  WidgetTester tester, {
  FakeBackend? backend,
}) async {
  usePhoneSize(tester);
  final harness = AppHarness.signedIn(backend: backend);
  await harness.pump(tester);
  await tester.pumpAndSettle();
  await tapKey(tester, 'nav-settings');
  return harness;
}

/// Deja que drift (que aquí necesita tiempo real) resuelva sus consultas.
Future<void> _settleDb(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('borrar cuenta', () {
    testWidgets(
      'confirmación clara; contraseña incorrecta (403) no borra ni cierra sesión',
      (tester) async {
        final harness = await openSettings(tester);
        await tapKey(tester, 'settings-delete');

        expect(find.text('¿Borrar tu cuenta?'), findsOneWidget);
        expect(find.textContaining('No se puede deshacer'), findsOneWidget);

        // Sin contraseña no se envía nada.
        await tapKey(tester, 'delete-confirm');
        expect(find.text('Introduce tu contraseña'), findsOneWidget);
        expect(harness.backend.calls, isNot(contains('DELETE /me')));

        await tester.enterText(
          find.byKey(const Key('delete-password')),
          'mala',
        );
        await tapKey(tester, 'delete-confirm');
        expect(find.text('La contraseña no es correcta.'), findsOneWidget);
        expect(harness.backend.accountDeleted, isFalse);
        expect(
          harness.container(tester).read(authProvider).isAuthenticated,
          isTrue,
        );
        expect(harness.storage.accessToken, isNotNull);
        await harness.drainAndUnmount(tester);
      },
    );

    testWidgets(
      'contraseña correcta: borra, limpia la sesión local y vuelve al login',
      (tester) async {
        final harness = await openSettings(tester);
        await tapKey(tester, 'settings-delete');
        await tester.enterText(
          find.byKey(const Key('delete-password')),
          'correcta',
        );
        await tapKey(tester, 'delete-confirm');

        expect(harness.backend.accountDeleted, isTrue);
        expect(harness.storage.accessToken, isNull);
        expect(find.byType(LoginScreen), findsOneWidget);
        await harness.drainAndUnmount(tester);
      },
    );
  });

  testWidgets('exportar mis datos entrega el JSON', (tester) async {
    final harness = await openSettings(tester);
    await tapKey(tester, 'settings-export');
    expect(harness.backend.exports, 1);
    expect(harness.exportSaver.saved.single, 'pipos-fitness-2026-11-09.json');
    expect(find.text('Exportación lista'), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets(
    'nutrición: 422 → «completa estos datos» con los campos que faltan',
    (tester) async {
      final backend = FakeBackend()
        ..nutritionFailure = const ApiFailure(
          type: ApiFailureType.badRequest,
          message: 'missing',
          statusCode: 422,
          code: ApiErrorCode.nutritionInputIncomplete,
          issues: [
            FieldIssue(path: 'weightKg', message: 'Required'),
            FieldIssue(path: 'birthYear', message: 'Required'),
          ],
        );
      final harness = await openSettings(tester, backend: backend);
      expect(find.byKey(const Key('nutrition-incomplete')), findsOneWidget);
      expect(
        find.text('Completa estos datos para calcularlos:'),
        findsOneWidget,
      );
      expect(find.text('• Peso'), findsOneWidget);
      expect(find.text('• Año de nacimiento'), findsOneWidget);
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets('nutrición: objetivos diarios', (tester) async {
    final harness = await openSettings(tester);
    expect(find.text('2350 kcal al día'), findsOneWidget);
    expect(
      find.text('Proteína 125 g · Grasa 70 g · Hidratos 300 g'),
      findsOneWidget,
    );
    await harness.drainAndUnmount(tester);
  });

  testWidgets(
    'retirar el consentimiento pide confirmación y borra los datos de salud',
    (tester) async {
      final harness = await openSettings(tester);
      expect(find.text('Consentimiento dado (health-2026-11)'), findsOneWidget);
      await tapKey(tester, 'health-withdraw');
      expect(find.text('¿Retirar el consentimiento?'), findsOneWidget);
      await tapKey(tester, 'withdraw-confirm');
      expect(harness.backend.calls, contains('DELETE /me/consents/health'));
      expect(
        find.text(
          'Consentimiento retirado. Tus datos de salud se han borrado.',
        ),
        findsOneWidget,
      );
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets(
    'editar el perfil crea una nueva versión del plan y lo explica (CUJ-6)',
    (tester) async {
      final harness = await openSettings(tester);
      await tapKey(tester, 'settings-profile');
      expect(find.text('Perfil de entrenamiento'), findsWidgets);
      await tapKey(tester, 'goal-strength');
      for (var i = 0; i < 6; i++) {
        if (find.text('Guardar cambios').evaluate().isNotEmpty) break;
        await tapKey(tester, 'onboarding-next');
      }
      await tapKey(tester, 'onboarding-next');

      expect(harness.backend.profileRequests.single.goal.wire, 'strength');
      expect(find.text('Nueva versión del plan'), findsOneWidget);
      expect(find.textContaining('hemos creado la versión 3'), findsOneWidget);
      await harness.drainAndUnmount(tester);
    },
  );

  group('cerrar sesión', () {
    testWidgets('avisa de las series sin enviar; cancelar no borra nada', (
      tester,
    ) async {
      final harness = await openSettings(tester);
      harness.setOnline(false);
      final sync = harness.container(tester).read(syncServiceProvider);
      await tester.runAsync(() async {
        final w = await sync.startWorkout(planSessionId: 'ps-1');
        await sync.logSet(
          workoutClientId: w.clientId,
          planExerciseId: null,
          exerciseId: 'ex-1',
          setIndex: 0,
          reps: 8,
          loadKg: 50,
        );
      });
      await tapKey(tester, 'settings-logout', settle: false);
      await _settleDb(tester);
      expect(find.textContaining('Hay 1 serie sin enviar'), findsOneWidget);

      await tapText(tester, 'Cancelar');
      expect(
        harness.container(tester).read(authProvider).isAuthenticated,
        isTrue,
      );
      final db = harness.database;
      expect(
        await tester.runAsync(() => db.select(db.localSetLogs).get()),
        hasLength(1),
      );
      await harness.drainAndUnmount(tester);
    });

    testWidgets('al confirmar borra los datos locales del usuario', (
      tester,
    ) async {
      final harness = await openSettings(tester);
      final db = harness.database;
      expect(
        await tester.runAsync(() => db.select(db.cachedPayloads).get()),
        isNotEmpty,
        reason: 'el plan/sesión se cachearon al abrir la app',
      );
      await tapKey(tester, 'settings-logout', settle: false);
      await _settleDb(tester);
      expect(find.byKey(const Key('logout-body')), findsOneWidget);
      await tapKey(tester, 'logout-confirm', settle: false);
      await _settleDb(tester);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(harness.storage.accessToken, isNull);
      expect(
        await tester.runAsync(() => db.select(db.cachedPayloads).get()),
        isEmpty,
      );
      await harness.drainAndUnmount(tester);
    });
  });
}
