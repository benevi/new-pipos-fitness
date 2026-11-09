import 'package:flutter/foundation.dart';

/// Configuración de entorno resuelta al arrancar.
///
/// `API_BASE_URL` se inyecta con `--dart-define=API_BASE_URL=https://...`.
/// - Release/profile: es obligatoria. Si falta, la app muestra una pantalla
///   de error de configuración en lugar de apuntar a un host inventado.
/// - Debug: si falta, se usa [debugFallbackBaseUrl] (host del emulador de
///   Android apuntando al backend local). Este valor NUNCA se usa fuera de
///   debug.
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Solo debug: `10.0.2.2` es el loopback del host visto desde el emulador.
  static const String debugFallbackBaseUrl = 'http://10.0.2.2:3000';

  /// Devuelve la configuración, o `null` si falta `API_BASE_URL` en un build
  /// que no es debug.
  static AppConfig? resolve({
    String fromEnvironment = _apiBaseUrlFromEnv,
    bool isDebug = kDebugMode,
  }) {
    final value = fromEnvironment.trim();
    if (value.isNotEmpty) return AppConfig(apiBaseUrl: value);
    if (isDebug) return const AppConfig(apiBaseUrl: debugFallbackBaseUrl);
    return null;
  }
}
