import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/refresh_lock.dart';

void main() {
  group('RefreshLock', () {
    test('executes action and returns result', () async {
      final lock = RefreshLock();
      final result = await lock.execute(() async => 'token-abc');
      expect(result, 'token-abc');
    });

    test('only executes action once for concurrent callers', () async {
      final lock = RefreshLock();
      var callCount = 0;

      Future<String?> action() async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return 'token-shared';
      }

      final futures = [
        lock.execute(action),
        lock.execute(action),
        lock.execute(action),
      ];

      final results = await Future.wait(futures);
      expect(callCount, 1);
      expect(results, ['token-shared', 'token-shared', 'token-shared']);
    });

    test('allows new execution after previous completes', () async {
      final lock = RefreshLock();
      var callCount = 0;

      await lock.execute(() async {
        callCount++;
        return 'first';
      });

      await lock.execute(() async {
        callCount++;
        return 'second';
      });

      expect(callCount, 2);
    });

    test('propagates null result to all waiters', () async {
      final lock = RefreshLock();

      final futures = [
        lock.execute(() async {
          await Future.delayed(const Duration(milliseconds: 20));
          return null;
        }),
        lock.execute(() async => 'should-not-run'),
      ];

      final results = await Future.wait(futures);
      expect(results, [null, null]);
    });

    test('propagates error to all waiters', () async {
      final lock = RefreshLock();

      final f1 = lock.execute(() async {
        await Future.delayed(const Duration(milliseconds: 20));
        throw Exception('refresh failed');
      });
      final f2 = lock.execute(() async => 'should-not-run');

      await expectLater(f1, throwsA(isA<Exception>()));
      await expectLater(f2, throwsA(isA<Exception>()));
    });

    test('isRefreshing tracks state correctly', () async {
      final lock = RefreshLock();
      expect(lock.isRefreshing, isFalse);

      final completer = Completer<String?>();
      final future = lock.execute(() => completer.future);

      expect(lock.isRefreshing, isTrue);

      completer.complete('done');
      await future;

      // After completion, lock is released
      expect(lock.isRefreshing, isFalse);
    });
  });
}
