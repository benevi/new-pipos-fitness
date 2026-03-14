import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipos_fitness/app/theme.dart';
import 'package:pipos_fitness/core/api/api_client.dart';
import 'package:pipos_fitness/features/exercises/exercise_detail_screen.dart';

void main() {
  group('ExerciseDetailScreen', () {
    testWidgets('shows no video available when media endpoint returns empty', (tester) async {
      final fakeApi = _FakeDetailAndMediaApi(
        detailResponse: {
          'id': 'e1',
          'slug': 'bench',
          'name': 'Bench Press',
          'difficulty': 2,
          'place': 'gym',
          'muscles': [],
          'media': [],
        },
        mediaResponse: [],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith((ref) => fakeApi),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const ExerciseDetailScreen(exerciseId: 'e1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No video available yet'), findsOneWidget);
    });

    testWidgets('shows media from media endpoint when present', (tester) async {
      final fakeApi = _FakeDetailAndMediaApi(
        detailResponse: {
          'id': 'e1',
          'slug': 'bench',
          'name': 'Bench Press',
          'difficulty': 2,
          'place': 'gym',
          'muscles': [],
          'media': [],
        },
        mediaResponse: [
          {
            'id': 'm1',
            'exerciseId': 'e1',
            'youtubeVideoId': 'abc123',
            'channelName': 'Fitness Channel',
            'curationStatus': 'approved',
          },
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith((ref) => fakeApi),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const ExerciseDetailScreen(exerciseId: 'e1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No video available yet'), findsNothing);
      expect(find.text('Fitness Channel'), findsOneWidget);
    });

    testWidgets('shows detail content and media error when media endpoint fails', (tester) async {
      final fakeApi = _FakeDetailAndMediaApi(
        detailResponse: {
          'id': 'e1',
          'slug': 'bench',
          'name': 'Bench Press',
          'difficulty': 2,
          'place': 'gym',
          'muscles': [],
          'media': [],
        },
        mediaFails: true,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith((ref) => fakeApi),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const ExerciseDetailScreen(exerciseId: 'e1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Couldn\'t load videos'), findsOneWidget);
    });
  });
}

class _FakeDetailAndMediaApi extends ApiClient {
  _FakeDetailAndMediaApi({
    Map<String, dynamic>? detailResponse,
    List<dynamic>? mediaResponse,
    this.mediaFails = false,
  })  : detailResponse = detailResponse,
        mediaResponse = mediaResponse ?? [],
        super(Dio());

  final Map<String, dynamic>? detailResponse;
  final List<dynamic> mediaResponse;
  final bool mediaFails;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (path.endsWith('/media')) {
      if (mediaFails) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
        );
      }
      return Response(
        requestOptions: RequestOptions(path: path),
        data: mediaResponse as T?,
      );
    }
    return Response(
      requestOptions: RequestOptions(path: path),
      data: detailResponse as T?,
    );
  }
}
