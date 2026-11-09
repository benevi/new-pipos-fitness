/// Constantes de red y almacenamiento compartidas por la app.
class AppConstants {
  AppConstants._();

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String cachedUserKey = 'cached_user';
}

/// Timeouts de red. Se aplican tanto al Dio principal como al Dio público
/// (login/registro/refresh), de modo que un refresh nunca puede quedarse
/// colgado indefinidamente.
class ApiTimeouts {
  ApiTimeouts._();

  static const Duration connect = Duration(seconds: 10);
  static const Duration receive = Duration(seconds: 20);
  static const Duration send = Duration(seconds: 20);
}
