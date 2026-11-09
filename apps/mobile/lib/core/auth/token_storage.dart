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

  /// Guarda los dos tokens A LA VEZ (y el id del usuario dueño). Si no se
  /// pasa [userId] (refresh) se conserva el guardado.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  });

  /// Id del usuario dueño de los tokens: permite asociar la cola offline a
  /// su usuario aunque falte el usuario cacheado.
  Future<String?> readUserId();

  /// Usuario de la última sesión validada. Permite entrar en modo offline
  /// (y asociar la cola offline a un usuario) sin red. Si falta su clave
  /// propia se usa la copia guardada con los tokens (id + email).
  Future<AuthUser?> readCachedUser();

  /// Guarda el usuario completo (id + email) en su clave Y junto a los
  /// tokens, para que la entrada offline nunca tenga solo el id.
  Future<void> saveCachedUser(AuthUser user);

  /// Borra tokens y usuario cacheado.
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage(aOptions: androidOptions);

  /// flutter_secure_storage 10 reescribió el almacenamiento de Android (sin
  /// Jetpack Security) y migra solo los datos de la 9 a los cifrados nuevos
  /// (`migrateOnAlgorithmChange`, por defecto). `migrateWithBackup` guarda una
  /// copia antes de migrar para que un cierre a mitad no pierda la sesión.
  /// Las copias quedan en SharedPreferences, excluidas del backup
  /// (res/xml/backup_rules.xml y data_extraction_rules.xml).
  static const androidOptions = AndroidOptions(migrateWithBackup: true);

  final FlutterSecureStorage _storage;

  /// Tokens + userId en UN solo valor JSON: escribirlos por separado podía
  /// dejar un access de una sesión con el refresh de otra si la app moría a
  /// mitad. Las claves sueltas antiguas se migran al leer.
  Future<_Session?> _readSession() async {
    final raw = await _storage.read(key: AppConstants.sessionKey);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        return _Session(
          j['accessToken'] as String,
          j['refreshToken'] as String,
          j['userId'] as String?,
          j['email'] as String?,
        );
      } catch (_) {
        return null;
      }
    }
    final access = await _storage.read(key: AppConstants.accessTokenKey);
    final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
    if (access == null || refresh == null) return null;
    final session = _Session(access, refresh, null, null);
    await _writeSession(session);
    await _deleteLegacy();
    return session;
  }

  Future<void> _writeSession(_Session s) => _storage.write(
    key: AppConstants.sessionKey,
    value: jsonEncode({
      'accessToken': s.accessToken,
      'refreshToken': s.refreshToken,
      if (s.userId != null) 'userId': s.userId,
      if (s.userId != null && s.email != null) 'email': s.email,
    }),
  );

  Future<void> _deleteLegacy() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  @override
  Future<String?> readAccessToken() async =>
      (await _readSession())?.accessToken;

  @override
  Future<String?> readRefreshToken() async =>
      (await _readSession())?.refreshToken;

  @override
  Future<String?> readUserId() async => (await _readSession())?.userId;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    final previous = await _readSession();
    final owner = userId ?? previous?.userId;
    // El email guardado solo vale para el mismo dueño.
    final email = owner != null && owner == previous?.userId
        ? previous?.email
        : null;
    await _writeSession(_Session(accessToken, refreshToken, owner, email));
  }

  @override
  Future<AuthUser?> readCachedUser() async {
    final raw = await _storage.read(key: AppConstants.cachedUserKey);
    if (raw != null) {
      try {
        return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    final session = await _readSession();
    final id = session?.userId;
    final email = session?.email;
    return id == null || email == null ? null : AuthUser(id: id, email: email);
  }

  @override
  Future<void> saveCachedUser(AuthUser user) async {
    await _storage.write(
      key: AppConstants.cachedUserKey,
      value: jsonEncode(user.toJson()),
    );
    final session = await _readSession();
    if (session != null) {
      await _writeSession(
        _Session(
          session.accessToken,
          session.refreshToken,
          user.id,
          user.email,
        ),
      );
    }
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: AppConstants.sessionKey);
    await _deleteLegacy();
    await _storage.delete(key: AppConstants.cachedUserKey);
  }
}

class _Session {
  const _Session(this.accessToken, this.refreshToken, this.userId, this.email);

  final String accessToken;
  final String refreshToken;
  final String? userId;

  /// Email del dueño (copia del usuario cacheado; issue #26).
  final String? email;
}

/// Implementación en memoria (tests y previsualizaciones).
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage({
    this.accessToken,
    this.refreshToken,
    this.cachedUser,
    this.userId,
    this.userEmail,
  });

  String? accessToken;
  String? refreshToken;
  AuthUser? cachedUser;
  String? userId;

  /// Email guardado junto a los tokens (como [SecureTokenStorage]).
  String? userEmail;

  @override
  Future<String?> readUserId() async => userId;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    if (userId != null && userId != this.userId) {
      this.userId = userId;
      userEmail = null;
    }
  }

  @override
  Future<AuthUser?> readCachedUser() async {
    final cached = cachedUser;
    if (cached != null) return cached;
    final id = userId;
    final email = userEmail;
    return id == null || email == null ? null : AuthUser(id: id, email: email);
  }

  @override
  Future<void> saveCachedUser(AuthUser user) async {
    cachedUser = user;
    if (accessToken != null) {
      userId = user.id;
      userEmail = user.email;
    }
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    cachedUser = null;
    userId = null;
    userEmail = null;
  }
}
