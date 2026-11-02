import 'dart:async';

/// App-wide auth signals raised by the networking layer, which has no
/// BuildContext. The root widget listens and routes to Login.
class SessionEvents {
  final _expired = StreamController<void>.broadcast();

  /// Fires when the refresh token is rejected, so the user must sign in again.
  Stream<void> get onSessionExpired => _expired.stream;

  void sessionExpired() {
    if (!_expired.isClosed) _expired.add(null);
  }

  Future<void> dispose() => _expired.close();
}
