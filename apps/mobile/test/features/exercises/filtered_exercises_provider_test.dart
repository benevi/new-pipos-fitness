import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipos_fitness/core/api/api_client.dart';
import 'package:pipos_fitness/features/exercises/filtered_exercises_provider.dart';

void main() {
  group('FilteredExercisesNotifier', () {
    test('build returns success state when API returns items', () async {
      final fakeApi = _FakeExercisesApi(
        response: {
          'items': [
            {
              'id': 'e1',
              'slug': 'bench-press',
              'name': 'Bench Press',
              'difficulty': 3,
              'place': 'gym',
            },
          ],
          'totalCount': 1,
          'page': 1,
          'limit': 20,
        },
      );
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(filteredExercisesProvider.future);

      expect(state.items.length, 1);
      expect(state.items.first.name, 'Bench Press');
      expect(state.totalCount, 1);
      expect(state.hasMore, false);
    });

    test('build returns error when API throws', () async {
      final fakeApi = _FakeExercisesApi(throwOnGet: true);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);

      try {
        await container.read(filteredExercisesProvider.future);
      } catch (_) {}
      final asyncState = container.read(filteredExercisesProvider);

      expect(asyncState.hasError, true);
    });

    test('refresh refetches page 1', () async {
      final fakeApi = _FakeExercisesApi(
        response: {
          'items': [
            {'id': 'e1', 'slug': 'e1', 'name': 'Squat', 'difficulty': 2, 'place': 'gym'},
          ],
          'totalCount': 1,
          'page': 1,
          'limit': 20,
        },
      );
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);

      await container.read(filteredExercisesProvider.future);
      fakeApi.response = {
        'items': [
          {'id': 'e2', 'slug': 'e2', 'name': 'Updated', 'difficulty': 1, 'place': 'home'},
        ],
        'totalCount': 1,
        'page': 1,
        'limit': 20,
      };
      await container.read(filteredExercisesProvider.notifier).refresh();

      final state = container.read(filteredExercisesProvider).value!;
      expect(state.items.first.name, 'Updated');
    });

    test('loadMore appends next page and hasMore becomes false when exhausted', () async {
      final fakeApi = _FakeExercisesApi(
        response: {
          'items': List.generate(
            20,
            (i) => {'id': 'e$i', 'slug': 'e$i', 'name': 'Ex $i', 'difficulty': 1, 'place': 'gym'},
          ),
          'totalCount': 25,
          'page': 1,
          'limit': 20,
        },
      );
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);

      await container.read(filteredExercisesProvider.future);
      var state = container.read(filteredExercisesProvider).value!;
      expect(state.items.length, 20);
      expect(state.hasMore, true);

      fakeApi.response = {
        'items': List.generate(
          5,
          (i) => {'id': 'p2-$i', 'slug': 'p2-$i', 'name': 'Page2 $i', 'difficulty': 1, 'place': 'gym'},
        ),
        'totalCount': 25,
        'page': 2,
        'limit': 20,
      };
      await container.read(filteredExercisesProvider.notifier).loadMore();

      state = container.read(filteredExercisesProvider).value!;
      expect(state.items.length, 25);
      expect(state.hasMore, false);
    });
  });
}

class _FakeExercisesApi extends ApiClient {
  _FakeExercisesApi({
    Map<String, dynamic>? response,
    this.throwOnGet = false,
  })  : response = response,
        super(Dio());

  Map<String, dynamic>? response;
  final bool throwOnGet;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (throwOnGet) {
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
