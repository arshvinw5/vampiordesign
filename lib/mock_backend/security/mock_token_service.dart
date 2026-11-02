import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../core/auth/auth_tokens.dart';

/// Issues and verifies JWT-shaped access tokens (`header.payload.signature`,
/// HMAC-SHA256) and opaque random refresh tokens.
///
/// It works like a real server, but the secret is a constant in the app,
/// so it's only for demos and tests.
class MockTokenService {
  MockTokenService({
    this.accessTtl = const Duration(seconds: 60),
    this.refreshTtl = const Duration(days: 7),
    this._clock = systemClock,
    Random? random,
  }) : _random = random ?? Random.secure();

  final Duration accessTtl;
  final Duration refreshTtl;
  final Clock _clock;
  final Random _random;

  static const _secret = 'vampior-mock-signing-secret';
  static final _hmac = Hmac(sha256, utf8.encode(_secret));
  static final _header = _b64(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));

  DateTime get now => _clock();

  String issueAccessToken(int userId) {
    final iat = now.millisecondsSinceEpoch ~/ 1000;
    final payload = _b64(
      utf8.encode(jsonEncode({'sub': userId, 'iat': iat, 'exp': iat + accessTtl.inSeconds})),
    );
    return '$_header.$payload.${_sign('$_header.$payload')}';
  }

  String issueRefreshToken() => _b64(List<int>.generate(32, (_) => _random.nextInt(256)));

  DateTime refreshExpiry() => now.add(refreshTtl);

  /// Returns the user id, or throws [InvalidTokenException].
  int verifyAccessToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw const InvalidTokenException('Malformed access token');
    if (_sign('${parts[0]}.${parts[1]}') != parts[2]) {
      throw const InvalidTokenException('Invalid access token signature');
    }
    final Map<String, dynamic> claims;
    try {
      claims = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
    } on FormatException {
      throw const InvalidTokenException('Malformed access token');
    }
    final exp = claims['exp'] as int;
    if (now.millisecondsSinceEpoch ~/ 1000 >= exp) {
      throw const InvalidTokenException('Access token expired');
    }
    return claims['sub'] as int;
  }

  static String _sign(String input) => _b64(_hmac.convert(utf8.encode(input)).bytes);
  static String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');
}

class InvalidTokenException implements Exception {
  const InvalidTokenException(this.message);
  final String message;
}
