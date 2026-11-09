import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../app/constants.dart';
import '../../models/user.dart';

/// Persistencia de la sesión (tokens + usuario cacheado).
///
/// Es una abstracción para poder sustituir el almacenamiento seguro real por
/// uno en memoria en los tests (el plugin de secure storage no existe en el
/// entorno de `flutter test`).
abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Usuario de la última sesión validada. Permite entrar en modo offline
  /// (y asociar la cola offline a un usuario) sin red.
  Future<AuthUser?> readCachedUser();
  Future<void> saveCachedUser(AuthUser user);

  /// Borra tokens y usuario cacheado.
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() =>
      _storage.read(key: AppConstants.accessTokenKey);

  @override
  Future<String?> readRefreshToken() =>
      _storage.read(key: AppConstants.refreshTokenKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  @override
  Future<AuthUser?> readCachedUser() async {
    final raw = await _storage.read(key: AppConstants.cachedUserKey);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCachedUser(AuthUser user) => _storage.write(
    key: AppConstants.cachedUserKey,
    value: jsonEncode(user.toJson()),
  );

  @override
  Future<void> clear() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.cachedUserKey);
  }
}

/// Implementación en memoria (tests y previsualizaciones).
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage({this.accessToken, this.refreshToken, this.cachedUser});

  String? accessToken;
  String? refreshToken;
  AuthUser? cachedUser;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<AuthUser?> readCachedUser() async => cachedUser;

  @override
  Future<void> saveCachedUser(AuthUser user) async => cachedUser = user;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    cachedUser = null;
  }
}
