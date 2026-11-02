import 'package:equatable/equatable.dart';

import '../../../../core/auth/auth_tokens.dart';
import 'user.dart';

/// A signed-in user and their token pair.
class AuthSession extends Equatable {
  const AuthSession({required this.user, required this.tokens});

  final User user;
  final AuthTokens tokens;

  @override
  List<Object?> get props => [user, tokens];
}
