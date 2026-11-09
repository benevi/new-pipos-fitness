import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session_coordinator.dart';
import 'token_storage.dart';

/// Almacenamiento de sesión. `PiposRoot` lo inyecta (secure storage real);
/// los tests lo sustituyen por [InMemoryTokenStorage].
final tokenStorageProvider = Provider<TokenStorage>(
  (_) => SecureTokenStorage(),
);

/// Callback que ejecuta el reset completo del `ProviderScope`.
///
/// `PiposRoot` lo sobreescribe. Por defecto no hace nada (útil en tests de
/// providers aislados que no montan la app entera).
final sessionEndCallbackProvider = Provider<SessionEndCallback>((_) => (_) {});

/// Motivo por el que terminó la sesión anterior (si la hubo). Lo inyecta
/// `PiposRoot` al recrear el scope para que el login pueda mostrar
/// "tu sesión ha caducado".
final previousSessionEndProvider = Provider<SessionEndReason?>((_) => null);

final authSessionCoordinatorProvider = Provider<AuthSessionCoordinator>(
  (ref) => AuthSessionCoordinator(
    onSessionEnded: ref.watch(sessionEndCallbackProvider),
  ),
);
