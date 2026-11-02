import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/auth/auth_tokens.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/presentation/form_controller.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/get_current_session.dart';
import '../../domain/usecases/logout_user.dart';

/// State for the signed-in (Success) screen: loads the profile through the
/// protected `/auth/me` endpoint, shows a live access-token countdown, and
/// logs out.
class HomeController extends ChangeNotifier {
  HomeController({
    required this._getCurrentSession,
    required this._logoutUser,
    this._clock = systemClock,
  });

  final GetCurrentSession _getCurrentSession;
  final LogoutUser _logoutUser;
  final Clock _clock;

  RequestStatus _status = RequestStatus.idle;
  RequestStatus get status => _status;
  bool get isLoading => _status == RequestStatus.loading;

  AuthSession? _session;
  AuthSession? get session => _session;

  Failure? _failure;
  Failure? get failure => _failure;
  bool get sessionExpired => _failure is SessionExpiredFailure;

  bool _loggingOut = false;
  bool get loggingOut => _loggingOut;

  Timer? _ticker;
  bool _disposed = false;

  /// Seconds until the access token expires. Hitting 0 is fine: the next
  /// API call refreshes it silently.
  int get accessSecondsLeft => _session?.tokens.accessTimeLeft(_clock()).inSeconds ?? 0;

  Future<void> load() async {
    if (isLoading) return;
    _status = RequestStatus.loading;
    _failure = null;
    _notify();
    final result = await _getCurrentSession(const NoParams());
    result.fold(
      (f) {
        _status = RequestStatus.failure;
        _failure = f;
      },
      (s) {
        _status = RequestStatus.success;
        _session = s;
        _startTicker();
      },
    );
    _notify();
  }

  Future<void> logout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    _notify();
    await _logoutUser(const NoParams()); // always clears local tokens
    _ticker?.cancel();
    _loggingOut = false;
    _notify();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      _notify();
      if (accessSecondsLeft == 0) t.cancel();
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
