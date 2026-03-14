import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipos_fitness/core/api/api_client.dart';
import 'package:pipos_fitness/features/exercises/exercise_detail_provider.dart';

void main() {
  group('ExerciseDetailNotifier', () {
    test('build returns detail when API returns exercise', () async {
      final fakeApi = _FakeDetailApi(
        response: {
          'id': 'ex-1',
          'slug': 'bench-press',
          'name': 'Bench Press',
          'description': 'A classic push.',
          'difficulty': 3,
          'movementPattern': 'push',
          'place': 'gym',
          'muscles': [],
          'media': [],
        },
      );
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);

      final detail = await container.read(exerciseDetailProvider('ex-1').future);

      expect(detail, isNotNull);
      expect(detail!.name, 'Bench Press');
      expect(detail.difficulty, 3);
    });

    test('build returns null when id is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final detail = await container.read(exerciseDetailProvider('').future);

      expect(detail, isNull);
    });

    test('build throws when API throws', () async {
      final fakeApi = _FakeDetailApi(throwOnGet: true);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);

      try {
        await container.read(exerciseDetailProvider('ex-1').future);
      } catch (_) {}
      final asyncState = container.read(exerciseDetailProvider('ex-1'));

      expect(asyncState.hasError, true);
    });
  });
}

class _FakeDetailApi extends ApiClient {
  _FakeDetailApi({
    Map<String, dynamic>? response,
    this.throwOnGet = false,
  })  : response = response,
        super(Dio());

  final Map<String, dynamic>? response;
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
