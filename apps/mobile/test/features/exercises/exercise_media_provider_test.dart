import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipos_fitness/core/api/api_client.dart';
import 'package:pipos_fitness/features/exercises/exercise_media_provider.dart';

void main() {
  group('ExerciseMediaNotifier', () {
    test('build returns empty list when exerciseId is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final list = await container.read(exerciseMediaProvider('').future);

      expect(list, isEmpty);
    });

    test('build returns media list when API returns data', () async {
      final fakeApi = _FakeMediaApi(
        response: [
          {
            'id': 'm1',
            'exerciseId': 'ex1',
            'youtubeVideoId': 'abc',
            'channelName': 'Channel',
            'curationStatus': 'approved',
          },
        ],
      );
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);

      final list = await container.read(exerciseMediaProvider('ex1').future);

      expect(list.length, 1);
      expect(list.first.youtubeVideoId, 'abc');
      expect(list.first.channelName, 'Channel');
    });

    test('build returns empty list when API returns null', () async {
      final fakeApi = _FakeMediaApi(response: null);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);

      final list = await container.read(exerciseMediaProvider('ex1').future);

      expect(list, isEmpty);
    });

    test('build throws when API throws', () async {
      final fakeApi = _FakeMediaApi(throwOnGet: true);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => fakeApi),
        ],
      );
      addTearDown(container.dispose);

      try {
        await container.read(exerciseMediaProvider('ex1').future);
      } catch (_) {}
      final asyncState = container.read(exerciseMediaProvider('ex1'));

      expect(asyncState.hasError, true);
    });
  });
}

class _FakeMediaApi extends ApiClient {
  _FakeMediaApi({
    List<dynamic>? response,
    this.throwOnGet = false,
  })  : response = response,
        super(Dio());

  final List<dynamic>? response;
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
