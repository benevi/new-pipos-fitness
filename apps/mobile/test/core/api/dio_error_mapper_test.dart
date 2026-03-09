import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/core/api/dio_error_mapper.dart';

void main() {
  group('mapDioException', () {
    test('maps connectionTimeout to timeout failure', () {
      final e = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final f = mapDioException(e);
      expect(f.type, ApiFailureType.timeout);
    });

    test('maps sendTimeout to timeout failure', () {
      final e = DioException(
        type: DioExceptionType.sendTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      expect(mapDioException(e).type, ApiFailureType.timeout);
    });

    test('maps receiveTimeout to timeout failure', () {
      final e = DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      expect(mapDioException(e).type, ApiFailureType.timeout);
    });

    test('maps connectionError to network failure', () {
      final e = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/test'),
      );
      expect(mapDioException(e).type, ApiFailureType.network);
    });

    test('maps 401 response to unauthorized', () {
      final e = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'message': 'Token expired'},
        ),
      );
      final f = mapDioException(e);
      expect(f.type, ApiFailureType.unauthorized);
      expect(f.statusCode, 401);
      expect(f.message, 'Token expired');
    });

    test('maps 400 response to badRequest', () {
      final e = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {'message': 'Invalid email'},
        ),
      );
      final f = mapDioException(e);
      expect(f.type, ApiFailureType.badRequest);
      expect(f.message, 'Invalid email');
    });

    test('maps 500 response to server failure', () {
      final e = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      );
      expect(mapDioException(e).type, ApiFailureType.server);
    });

    test('maps cancel to unknown failure', () {
      final e = DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/test'),
      );
      expect(mapDioException(e).type, ApiFailureType.unknown);
    });

    test('uses server message when available', () {
      final e = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 422,
          data: {'message': 'Validation failed'},
        ),
      );
      expect(mapDioException(e).message, 'Validation failed');
    });

    test('falls back to default message when no server message', () {
      final e = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 403,
          data: 'not json',
        ),
      );
      expect(mapDioException(e).message, 'Invalid request.');
    });
  });
}
