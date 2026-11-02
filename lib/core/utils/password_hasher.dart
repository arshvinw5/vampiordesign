import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 for the local mock backend. A real backend would use a
/// slow KDF (bcrypt/argon2) server-side.
abstract final class PasswordHasher {
  static const _salt = 'vampior.mock.v1';

  static String hash(String password) =>
      sha256.convert(utf8.encode('$_salt:$password')).toString();

  static bool verify(String password, String hashed) => hash(password) == hashed;
}
