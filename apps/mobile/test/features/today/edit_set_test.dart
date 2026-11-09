// #22: corregir o borrar una serie ya registrada desde su fila, sin red;
// la cola la envía (PATCH / DELETE) al volver la conexión.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

Finder byKeyPrefix(String prefix) => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(prefix),
);

void main() {
  const squat = '00000000-0000-4000-8000-000000000030';

  testWidgets('editar (con coma decimal) y borrar una serie sincronizada '
      'sin red: se ve al momento y al volver la red va PATCH y DELETE', (
    tester,
  ) async {
    usePhoneSize(tester);
    var now = DateTime.utc(2026, 11, 9, 8);
    final harness = AppHarness.signedIn(clock: () => now);
    final backend = harness.backend;
    await harness.pump(tester);
    await tester.pumpAndSettle();

    await tapKey(tester, 'confirm-$squat', settle: false);
    await pumpFrames(tester);
    await tapKey(tester, 'rest-skip', settle: false);
    expect(backend.sets, hasLength(1));
    final clientId = backend.sets.keys.single;

    harness.setOnline(false);
    now = now.add(const Duration(minutes: 2));
    await tapKey(tester, 'set-menu-$clientId');
    await tester.tap(find.byKey(const Key('set-action-edit')));
    await tester.pumpAndSettle();
    expect(find.text('Corregir la serie 1'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('edit-set-load')),
        matching: find.text('62,5'),
      ),
      findsOneWidget,
      reason: 'kg con el separador del idioma',
    );

    await tester.enterText(find.byKey(const Key('edit-set-reps')), '10');
    await tester.enterText(find.byKey(const Key('edit-set-load')), '60,5');
    await tester.tap(find.byKey(const Key('edit-set-rir-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('edit-set-save')));
    await pumpFrames(tester);

    // Optimista: la fila ya muestra lo corregido, pendiente de enviar.
    expect(find.text('10 × 60,5 kg · RIR 1'), findsOneWidget);
    expect(find.byKey(Key('sync-$clientId-pending')), findsOneWidget);
    expect(backend.patches, isEmpty);

    harness.setOnline(true);
    await pumpFrames(tester);
    final patch = backend.patches.single;
    expect(patch.request.reps, 10);
    expect(patch.request.loadKg, 60.5);
    expect(patch.request.rir, 1);
    expect(backend.sets[clientId]!.reps, 10);
    expect(find.byKey(Key('sync-$clientId-synced')), findsOneWidget);

    // Borrar (sin red): se oculta al momento; DELETE al volver la red.
    harness.setOnline(false);
    expect(find.byTooltip('Opciones de la serie 1'), findsOneWidget);
    await tapKey(tester, 'set-menu-$clientId');
    await tester.tap(find.byKey(const Key('set-action-delete')));
    await tester.pumpAndSettle();
    expect(find.text('¿Borrar la serie 1?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('set-delete-confirm')));
    await pumpFrames(tester);
    expect(find.text('10 × 60,5 kg · RIR 1'), findsNothing);
    expect(byKeyPrefix('set-menu-'), findsNothing);

    harness.setOnline(true);
    await pumpFrames(tester);
    expect(backend.deletedSets, [clientId]);
    expect(backend.sets[clientId]!.deletedAt, isNotNull);
    await harness.drainAndUnmount(tester);
  });
}
