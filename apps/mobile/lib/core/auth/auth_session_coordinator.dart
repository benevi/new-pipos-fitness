/// Auth Session Coordinator
///
/// Punto único por el que termina una sesión, tanto si la cierra el usuario
/// (logout) como si la fuerza el [AuthInterceptor] (refresh fallido o 401
/// repetido tras reintentar).
///
/// Cómo se resetea el estado:
/// la app corre dentro de un `ProviderScope` cuya clave posee `PiposRoot`.
/// Terminar la sesión llama a [SessionEndCallback], que hace que `PiposRoot`
/// reconstruya el `ProviderScope` con una clave nueva. Así se descartan TODOS
/// los providers (datos de usuario, cachés, router...) sin mantener una lista
/// manual de providers a invalidar.
///
/// Dependencias (sin ciclos):
///   AuthInterceptor ──llama──> AuthSessionCoordinator ──llama──> PiposRoot
///   AuthNotifier.logout ──llama──> AuthSessionCoordinator
///
/// Cada `ProviderScope` tiene su propio coordinador (provider), de modo que
/// la guarda de re-entrada es por sesión.
library;

/// Motivo por el que terminó una sesión.
enum SessionEndReason {
  /// El usuario cerró sesión.
  logout,

  /// El servidor rechazó la sesión (refresh inválido o 401 tras reintento).
  expired,
}

typedef SessionEndCallback = void Function(SessionEndReason reason);

class AuthSessionCoordinator {
  AuthSessionCoordinator({required SessionEndCallback onSessionEnded})
    : _onSessionEnded = onSessionEnded;

  final SessionEndCallback _onSessionEnded;
  bool _ended = false;

  /// `true` cuando esta sesión ya ha terminado (y el reset está en curso).
  bool get hasEnded => _ended;

  /// El servidor invalidó la sesión. Idempotente: varias peticiones que
  /// fallen a la vez solo provocan un reset.
  void onSessionExpired() => _end(SessionEndReason.expired);

  /// Logout explícito del usuario. Idempotente.
  void onLoggedOut() => _end(SessionEndReason.logout);

  /// Una sesión nueva empezó (login/registro) dentro del mismo scope.
  void onSessionStarted() {
    _ended = false;
  }

  void _end(SessionEndReason reason) {
    if (_ended) return;
    _ended = true;
    _onSessionEnded(reason);
  }
}
