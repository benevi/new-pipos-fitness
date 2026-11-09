// El descanso se calcula contra el reloj (endsAt), no contando ticks: si la
// app se suspende y no llegan ticks, al volver el tiempo restante es el real.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/offline/offline_providers.dart';
import 'package:pipos_fitness/features/today/today_providers.dart';

void main() {
  testWidgets('app suspendida 45 s: al siguiente tick quedan 14 s, no 59', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 11, 9, 8);
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(restTimerProvider, (_, _) {});
    addTearDown(sub.close);
    final timer = container.read(restTimerProvider.notifier);

    timer.start(60);
    expect(container.read(restTimerProvider)!.remaining, 60);

    // Suspendida: el reloj avanza 45 s sin que lleguen ticks.
    now = now.add(const Duration(seconds: 45));
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(container.read(restTimerProvider)!.remaining, 14);

    // «+15 s» mueve el final.
    timer.add(15);
    expect(container.read(restTimerProvider)!.remaining, 29);

    // Pasado el final, termina aunque falten ticks.
    now = now.add(const Duration(minutes: 5));
    timer.refresh();
    expect(container.read(restTimerProvider)!.done, isTrue);
    timer.skip();
  });
}
