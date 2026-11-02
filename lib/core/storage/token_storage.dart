import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/auth_tokens.dart';
import '../error/exceptions.dart';

/// Persists the session's token pair. Tokens are secrets, so they never go
/// to shared_preferences or SQLite.
abstract interface class TokenStorage {
  Future<AuthTokens?> read();
  Future<void> save(AuthTokens tokens);
  Future<void> clear();
}

/// Keychain (iOS/macOS), Android Keystore-backed encryption, libsecret
/// (Linux) and DPAPI (Windows), via flutter_secure_storage.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // Readable after first unlock, so background refreshes work; not
            // included in device-to-device backups.
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
          );

  final FlutterSecureStorage _storage;

  static const accessTokenKey = 'vampior.accessToken';
  static const refreshTokenKey = 'vampior.refreshToken';
  static const accessExpiresAtKey = 'vampior.accessExpiresAt';

  @override
  Future<AuthTokens?> read() => _guard(() async {
    final values = await _storage.readAll();
    final access = values[accessTokenKey];
    final refresh = values[refreshTokenKey];
    final expires = DateTime.tryParse(values[accessExpiresAtKey] ?? '');
    if (access == null || refresh == null || expires == null) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh, accessExpiresAt: expires);
  });

  @override
  Future<void> save(AuthTokens tokens) => _guard(() async {
    await _storage.write(key: accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: refreshTokenKey, value: tokens.refreshToken);
    await _storage.write(
      key: accessExpiresAtKey,
      value: tokens.accessExpiresAt.toUtc().toIso8601String(),
    );
  });

  @override
  Future<void> clear() => _guard(() async {
    for (final key in const [accessTokenKey, refreshTokenKey, accessExpiresAtKey]) {
      await _storage.delete(key: key);
    }
  });

  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on Exception catch (e) {
      throw CacheException('Secure storage error: $e');
    }
  }
}
