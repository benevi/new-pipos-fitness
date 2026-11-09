import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Respuesta simulada.
class FakeResponse {
  const FakeResponse(this.status, [this.body]);

  /// Simula que no hay red (DioExceptionType.connectionError).
  const FakeResponse.offline() : status = 0, body = null;

  final int status;
  final Object? body;

  bool get isOffline => status == 0;
}

typedef FakeHandler = FutureOr<FakeResponse> Function(RequestOptions options);

/// Adaptador HTTP en memoria con rutas `"MÉTODO /ruta"` y registro de
/// peticiones, para probar Dio + interceptores sin red.
class FakeHttpAdapter implements HttpClientAdapter {
  final Map<String, FakeHandler> _handlers = {};
  final List<RequestOptions> requests = [];

  void on(String method, String path, FakeHandler handler) {
    _handlers['${method.toUpperCase()} $path'] = handler;
  }

  void reply(String method, String path, int status, [Object? body]) {
    on(method, path, (_) async => FakeResponse(status, body));
  }

  int count(String method, String path) => requests
      .where(
        (r) => r.method.toUpperCase() == method.toUpperCase() && r.path == path,
      )
      .length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final handler =
        _handlers['${options.method.toUpperCase()} ${options.path}'];
    final response = handler == null
        ? const FakeResponse(404, {'message': 'Not found'})
        : await handler(options);
    if (response.isOffline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline (fake)',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Respuesta típica de /auth/login y /auth/register.
Map<String, dynamic> authResponseJson({
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
  String id = 'user-1',
  String email = 'ana@pipos.app',
}) => {
  'accessToken': accessToken,
  'refreshToken': refreshToken,
  'expiresIn': 900,
  'user': {'id': id, 'email': email},
};

Map<String, dynamic> meJson({
  String id = 'user-1',
  String email = 'ana@pipos.app',
}) => {
  'id': id,
  'email': email,
  'role': 'user',
  'locale': 'es',
  'createdAt': '2026-11-09T08:00:00.000Z',
};
