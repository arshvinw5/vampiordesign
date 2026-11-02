import 'package:dio/dio.dart';

import '../auth/auth_tokens.dart';
import '../auth/session_events.dart';
import '../error/exceptions.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';

/// Attaches `Authorization: Bearer <access>` and keeps the session alive.
///
/// 1. **Before sending**: if the stored access token is (about to be)
///    expired, refresh first.
/// 2. **On 401**: refresh once, retry the request once with the new token.
///    If another request already refreshed while this one was in flight,
///    just retry with the newer token (no second refresh).
/// 3. **Refresh rejected (401)**: clear stored tokens and raise
///    [SessionEvents.sessionExpired], so the app returns to Login.
///    Network errors during refresh keep the session (the user may be offline).
///
/// It's a [QueuedInterceptor], so concurrent requests are serialized here and
/// a burst of 401s triggers only one `/auth/refresh`.
///
/// Requests flagged with [ApiEndpoints.publicRequest] are passed through.
/// Refresh and retry go through [_bareDio], which has no AuthInterceptor,
/// so they can't deadlock this queue or recurse.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this._storage,
    required this._bareDio,
    required this._events,
    this._clock = systemClock,
  });

  final TokenStorage _storage;
  final Dio _bareDio;
  final SessionEvents _events;
  final Clock _clock;

  static const _retriedKey = 'authRetried';

  static bool _isPublic(RequestOptions o) => o.extra[ApiEndpoints.authExtraKey] == false;
  static String _bearer(AuthTokens t) => 'Bearer ${t.accessToken}';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isPublic(options)) return handler.next(options);

    var tokens = await _read();
    if (tokens == null) return handler.next(options); // server answers 401
    if (tokens.isAccessExpired(_clock())) {
      try {
        tokens = await _refresh(tokens);
      } on DioException catch (e) {
        return handler.reject(e.copyWith(requestOptions: options));
      }
    }
    options.headers['Authorization'] = _bearer(tokens);
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final unauthorized = err.response?.statusCode == 401;
    if (!unauthorized || _isPublic(options) || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    final current = await _read();
    if (current == null) {
      await _expireSession();
      return handler.next(err);
    }

    try {
      // Refresh only if the rejected token is the one we still hold.
      final tokens = options.headers['Authorization'] == _bearer(current)
          ? await _refresh(current)
          : current;
      final retry = options.copyWith(
        headers: {...options.headers, 'Authorization': _bearer(tokens)},
        extra: {...options.extra, _retriedKey: true},
      );
      handler.resolve(await _bareDio.fetch<dynamic>(retry));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Exchanges the refresh token for a new pair and stores it.
  /// Throws the [DioException] if refreshing fails.
  Future<AuthTokens> _refresh(AuthTokens tokens) async {
    try {
      final res = await _bareDio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refreshToken': tokens.refreshToken},
        options: Options(extra: ApiEndpoints.publicRequest),
      );
      final fresh = AuthTokens.fromJson(res.data!, now: _clock());
      await _storage.save(fresh);
      return fresh;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await _expireSession();
      rethrow;
    }
  }

  Future<AuthTokens?> _read() async {
    try {
      return await _storage.read();
    } on CacheException {
      return null;
    }
  }

  Future<void> _expireSession() async {
    try {
      await _storage.clear();
    } on CacheException {
      // Nothing else to do; the user is being signed out anyway.
    }
    _events.sessionExpired();
  }
}
