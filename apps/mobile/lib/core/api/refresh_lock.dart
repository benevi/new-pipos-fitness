import 'dart:async';

/// Completer-based mutex that ensures only one refresh executes at a time.
///
/// When the first caller arrives, it runs the [action]. Subsequent callers
/// arriving while the action is in-flight receive the same Future result
/// instead of spawning a new refresh.
class RefreshLock {
  Completer<String?>? _completer;

  bool get isRefreshing => _completer != null;

  /// Runs [action] if no refresh is in-flight. Otherwise waits for the
  /// existing refresh result.
  Future<String?> execute(Future<String?> Function() action) {
    if (_completer != null) {
      return _completer!.future;
    }

    _completer = Completer<String?>();

    action().then((result) {
      _completer?.complete(result);
    }).catchError((Object error) {
      _completer?.completeError(error);
    }).whenComplete(() {
      _completer = null;
    });

    return _completer!.future;
  }
}
