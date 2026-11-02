import 'dart:convert';
import 'dart:math';

import '../../../features/auth/data/datasources/user_local_data_source.dart';
import '../../error/exceptions.dart';
import '../../utils/password_hasher.dart';
import '../api_endpoints.dart';

/// HTTP-like response produced by [MockAuthServer].
class MockResponse {
  const MockResponse(this.statusCode, this.body);
  final int statusCode;
  final Map<String, dynamic> body;

  bool get ok => statusCode >= 200 && statusCode < 300;
}

/// Thrown to simulate the device being offline.
class MockConnectionError implements Exception {
  const MockConnectionError();
}

/// A fake auth backend backed by SQLite. It plays the server's role, so the
/// app's Dio data source can't tell it apart from a real API.
///
/// Demo hooks: identifiers starting with `network@` simulate no
/// connection; `server@` simulates a 500.
class MockAuthServer {
  MockAuthServer(this._users, {Random? random}) : _random = random ?? Random.secure();

  final UserLocalDataSource _users;
  final Random _random;

  Future<MockResponse> handle(String method, String path, Object? data) async {
    final body = (data as Map?)?.cast<String, dynamic>() ?? const {};
    final probe = '${body['identifier'] ?? body['email'] ?? ''}'.trim().toLowerCase();
    if (probe.startsWith('network@')) throw const MockConnectionError();
    if (probe.startsWith('server@')) {
      return const MockResponse(500, {'message': 'Internal server error'});
    }
    return switch ((method.toUpperCase(), path)) {
      ('POST', ApiEndpoints.login) => _login(body),
      ('POST', ApiEndpoints.register) => _register(body),
      ('POST', ApiEndpoints.forgotPassword) => _forgotPassword(body),
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
    return MockResponse(200, {'user': user.toModel().toJson(), 'token': _token(user.id)});
  }

  Future<MockResponse> _register(Map<String, dynamic> body) async {
    try {
      final user = await _users.insertUser(
        fullName: '${body['fullName']}',
        email: '${body['email']}',
        mobile: '${body['mobile']}',
        passwordHash: PasswordHasher.hash('${body['password']}'),
      );
      return MockResponse(201, {'user': user.toModel().toJson(), 'token': _token(user.id)});
    } on DuplicateUserException catch (e) {
      return MockResponse(409, {'message': e.message, 'field': e.field});
    }
  }

  Future<MockResponse> _forgotPassword(Map<String, dynamic> body) async {
    final user = await _users.findByIdentifier('${body['identifier'] ?? ''}');
    if (user == null) {
      return const MockResponse(404, {'message': 'No account found for that email or mobile number'});
    }
    return const MockResponse(200, {'message': 'Reset link sent'});
  }

  String _token(int userId) {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    return 'mock.$userId.${base64Url.encode(bytes)}';
  }
}
