import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipos_fitness/core/api/api_client.dart';
import 'package:pipos_fitness/features/ai_coach/ai_coach_provider.dart';

void main() {
  group('AICoachNotifier', () {
    test('initial state is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(aiCoachProvider);
      expect(state.messages, isEmpty);
      expect(state.sending, false);
      expect(state.error, isNull);
    });

    test('sendQuestion does nothing for empty trimmed input', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(aiCoachProvider.notifier).sendQuestion('');
      await container.read(aiCoachProvider.notifier).sendQuestion('   ');
      expect(container.read(aiCoachProvider).messages, isEmpty);
    });

    test('sendQuestion does nothing when over 500 chars', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => _FakeApiClient()),
        ],
      );
      addTearDown(container.dispose);
      final long = 'x' * 501;
      await container.read(aiCoachProvider.notifier).sendQuestion(long);
      expect(container.read(aiCoachProvider).messages, isEmpty);
    });

    test('sendQuestion appends user message and assistant on success', () async {
      final fakeApi = _FakeApiClient(
        response: {
          'responseType': 'answer',
          'content': 'Hello from AI',
        },
      );
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);

      await container.read(aiCoachProvider.notifier).sendQuestion('Hi');

      final state = container.read(aiCoachProvider);
      expect(state.sending, false);
      expect(state.error, isNull);
      expect(state.messages.length, 2);
      expect(state.messages[0].role.name, 'user');
      expect(state.messages[0].content, 'Hi');
      expect(state.messages[1].role.name, 'assistant');
      expect(state.messages[1].content, 'Hello from AI');
    });

    test('sendQuestion sets error on API failure', () async {
      final fakeApi = _FakeApiClient(throwException: true);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);

      await container.read(aiCoachProvider.notifier).sendQuestion('Hi');

      final state = container.read(aiCoachProvider);
      expect(state.sending, false);
      expect(state.messages.length, 1);
      expect(state.error, isNotNull);
    });

    test('clearError removes error', () async {
      final fakeApi = _FakeApiClient(throwException: true);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);
      await container.read(aiCoachProvider.notifier).sendQuestion('Hi');
      expect(container.read(aiCoachProvider).error, isNotNull);

      container.read(aiCoachProvider.notifier).clearError();
      expect(container.read(aiCoachProvider).error, isNull);
    });

    test('concurrent send prevented when sending is true', () async {
      final fakeApi = _FakeApiClient(
        response: {'responseType': 'answer', 'content': 'OK'},
        delay: const Duration(milliseconds: 50),
      );
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(aiCoachProvider.notifier);
      notifier.sendQuestion('First');
      await Future.delayed(const Duration(milliseconds: 5));
      notifier.sendQuestion('Second');

      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(aiCoachProvider);
      expect(state.messages.length, 2);
      expect(state.messages[0].content, 'First');
      expect(state.messages[1].content, 'OK');
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    this.response,
    this.throwException = false,
    this.delay = Duration.zero,
  }) : super(Dio());

  final Map<String, dynamic>? response;
  final bool throwException;
  final Duration delay;

  @override
  Future<Response<T>> post<T>(String path, {Object? data}) async {
    await Future.delayed(delay);
    if (throwException) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
      );
    }
    return Response(
      requestOptions: RequestOptions(path: path),
      data: response as T?,
    );
  }
}
