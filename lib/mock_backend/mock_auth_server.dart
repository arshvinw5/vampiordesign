import '../core/network/api_endpoints.dart';
import 'security/mock_token_service.dart';
import 'security/password_hasher.dart';
import 'stores/session_store.dart';
import 'stores/user_store.dart';

/// HTTP-like response produced by [MockAuthServer].
class MockResponse {
  const MockResponse(this.statusCode, [this.body = const {}]);
  final int statusCode;
  final Map<String, dynamic> body;

  bool get ok => statusCode >= 200 && statusCode < 300;
}

/// Thrown to simulate the device being offline.
class MockConnectionError implements Exception {
  const MockConnectionError();
}

/// A fake auth REST backend: the code a real server would run.
///
/// | Method | Path | Auth | Success | Errors |
/// |---|---|---|---|---|
/// | POST | /auth/login | – | 200 tokens + user | 401, 422 |
/// | POST | /auth/register | – | 201 tokens + user | 409 |
/// | POST | /auth/refresh | – | 200 new token pair (rotation) | 401 |
/// | POST | /auth/logout | – | 204 (revokes refresh token) | – |
/// | POST | /auth/forgot-password | – | 200 | 404 |
/// | GET | /auth/me | Bearer | 200 user | 401 |
///
/// Demo hooks: identifiers starting with `network@` simulate no
/// connection; `server@` simulates a 500.
class MockAuthServer {
  MockAuthServer({required this._users, required this._sessions, required this._tokens});

  final UserStore _users;
  final SessionStore _sessions;
  final MockTokenService _tokens;

  Future<MockResponse> handle(
    String method,
    String path,
    Object? data, {
    Map<String, dynamic> headers = const {},
  }) async {
    final body = (data as Map?)?.cast<String, dynamic>() ?? const {};
    final probe = '${body['identifier'] ?? body['email'] ?? ''}'.trim().toLowerCase();
    if (probe.startsWith('network@')) throw const MockConnectionError();
    if (probe.startsWith('server@')) {
      return const MockResponse(500, {'message': 'Internal server error'});
    }
    return switch ((method.toUpperCase(), path)) {
      ('POST', ApiEndpoints.login) => _login(body),
      ('POST', ApiEndpoints.register) => _register(body),
      ('POST', ApiEndpoints.refresh) => _refresh(body),
      ('POST', ApiEndpoints.logout) => _logout(body),
      ('POST', ApiEndpoints.forgotPassword) => _forgotPassword(body),
      ('GET', ApiEndpoints.me) => _me(headers),
      _ => Future.value(const MockResponse(404, {'message': 'Not found'})),
    };
  }

  Future<MockResponse> _login(Map<String, dynamic> body) async {
    final identifier = '${body['identifier'] ?? ''}';
    final password = '${body['password'] ?? ''}';
    if (identifier.isEmpty || password.isEmpty) {
      return const MockResponse(422, {'message': 'Identifier and password are required'});
    }
    final user = await _users.findByIdentifier(identifier);
    if (user == null || !PasswordHasher.verify(password, user.passwordHash)) {
      return const MockResponse(401, {'message': 'Incorrect email/mobile or password'});
    }
    return MockResponse(200, {'user': user.toJson(), ...await _issueTokens(user.id)});
  }

  Future<MockResponse> _register(Map<String, dynamic> body) async {
    try {
      final user = await _users.insertUser(
        fullName: '${body['fullName']}',
        email: '${body['email']}',
        mobile: '${body['mobile']}',
        passwordHash: PasswordHasher.hash('${body['password']}'),
      );
      return MockResponse(201, {'user': user.toJson(), ...await _issueTokens(user.id)});
    } on DuplicateUserException catch (e) {
      return MockResponse(409, {'message': e.message, 'field': e.field});
    }
  }

  /// Refresh-token rotation: the presented token is revoked and a new pair
  /// is issued. A revoked token being replayed is rejected.
  Future<MockResponse> _refresh(Map<String, dynamic> body) async {
    final token = '${body['refreshToken'] ?? ''}';
    final session = token.isEmpty ? null : await _sessions.find(token);
    if (session == null || !session.isUsable(_tokens.now)) {
      return const MockResponse(401, {'message': 'Refresh token invalid or expired'});
    }
    await _sessions.revoke(token);
    return MockResponse(200, await _issueTokens(session.userId));
  }

  Future<MockResponse> _logout(Map<String, dynamic> body) async {
    final token = '${body['refreshToken'] ?? ''}';
    if (token.isNotEmpty) await _sessions.revoke(token);
    return const MockResponse(204);
  }

  Future<MockResponse> _forgotPassword(Map<String, dynamic> body) async {
    final user = await _users.findByIdentifier('${body['identifier'] ?? ''}');
    if (user == null) {
      return const MockResponse(404, {
        'message': 'No account found for that email or mobile number',
      });
    }
    return const MockResponse(200, {'message': 'Reset link sent'});
  }

  Future<MockResponse> _me(Map<String, dynamic> headers) async {
    final auth = '${headers['Authorization'] ?? headers['authorization'] ?? ''}';
    if (!auth.startsWith('Bearer ')) {
      return const MockResponse(401, {'message': 'Missing access token'});
    }
    try {
      final userId = _tokens.verifyAccessToken(auth.substring(7));
      final user = await _users.findById(userId);
      if (user == null) return const MockResponse(401, {'message': 'User no longer exists'});
      return MockResponse(200, {'user': user.toJson()});
    } on InvalidTokenException catch (e) {
      return MockResponse(401, {'message': e.message});
    }
  }

  Future<Map<String, dynamic>> _issueTokens(int userId) async {
    final refreshToken = _tokens.issueRefreshToken();
    await _sessions.create(
      refreshToken: refreshToken,
      userId: userId,
      expiresAt: _tokens.refreshExpiry(),
    );
    return {
      'accessToken': _tokens.issueAccessToken(userId),
      'refreshToken': refreshToken,
      'tokenType': 'Bearer',
      'expiresIn': _tokens.accessTtl.inSeconds,
    };
  }
}
