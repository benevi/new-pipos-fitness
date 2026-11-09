import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Fuente de conectividad desacoplada del plugin (sustituible en tests).
///
/// "Online" significa que hay alguna interfaz de red activa; no garantiza
/// que la API responda. El `SyncService` trata los fallos de red como
/// transitorios y reintenta con backoff de todos modos.
abstract class ConnectivitySource {
  Future<bool> isOnline();
  Stream<bool> get onlineChanges;
}

class PluginConnectivitySource implements ConnectivitySource {
  PluginConnectivitySource([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async {
    try {
      return _hasNetwork(await _connectivity.checkConnectivity());
    } catch (_) {
      // Si el plugin falla, asumimos online y dejamos que la red decida.
      return true;
    }
  }

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_hasNetwork).distinct();
}

/// Conectividad controlable manualmente (tests).
class ManualConnectivitySource implements ConnectivitySource {
  ManualConnectivitySource({bool online = true}) : _online = online;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  bool get online => _online;
  set online(bool value) {
    if (value == _online) return;
    _online = value;
    _controller.add(value);
  }

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  Future<void> dispose() => _controller.close();
}
