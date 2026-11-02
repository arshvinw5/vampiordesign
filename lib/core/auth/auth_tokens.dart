import 'package:equatable/equatable.dart';

/// Injectable time source, so token expiry can be tested deterministically.
typedef Clock = DateTime Function();

DateTime systemClock() => DateTime.now().toUtc();

/// Access + refresh token pair issued by the auth API.
///
/// Lives in `core` (not a feature) because the networking layer's
/// `AuthInterceptor` and `TokenStorage` need it too.
class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
  });

  /// Parses `{accessToken, refreshToken, expiresIn}` (expiresIn in seconds).
  factory AuthTokens.fromJson(Map<String, dynamic> json, {required DateTime now}) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    accessExpiresAt: now.add(Duration(seconds: (json['expiresIn'] as num).toInt())),
  );

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;

  /// Refresh a little before the real expiry, so a request doesn't
  /// leave with a token that dies in flight.
  static const expirySkew = Duration(seconds: 10);

  bool isAccessExpired(DateTime now) => !now.isBefore(accessExpiresAt.subtract(expirySkew));

  Duration accessTimeLeft(DateTime now) {
    final left = accessExpiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, accessExpiresAt];
}
