import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/usecases/restore_session.dart';
import '../../../onboarding/domain/usecases/onboarding_usecases.dart';

enum StartupDestination { onboarding, login, home }

class StartupDecision {
  const StartupDecision(this.destination, {this.session, this.failure});
  final StartupDestination destination;

  /// Set when the profile loaded (destination == home).
  final AuthSession? session;

  /// Set when home is shown despite a transient error (offline / 5xx).
  final Failure? failure;
}

/// Decides the first real screen at launch:
///
/// ```
/// onboarding not seen              → onboarding
/// no stored session / not "keep me signed in" / refresh rejected → login
/// /auth/me OK                      → home
/// /auth/me failed: offline or 5xx  → home (tokens are still valid; Home can retry)
/// ```
class StartupController extends ChangeNotifier {
  StartupController({required this._checkOnboardingSeen, required this._restoreSession});

  final CheckOnboardingSeen _checkOnboardingSeen;
  final RestoreSession _restoreSession;

  Future<StartupDecision>? _decision;

  /// Memoized, so rebuilds never run the check twice.
  Future<StartupDecision> decide() => _decision ??= _decide();

  Future<StartupDecision> _decide() async {
    if (!_checkOnboardingSeen()) return const StartupDecision(StartupDestination.onboarding);

    final result = await _restoreSession(const NoParams());
    return result.fold(
      (failure) => switch (failure) {
        NetworkFailure() ||
        ServerFailure() => StartupDecision(StartupDestination.home, failure: failure),
        _ => const StartupDecision(StartupDestination.login),
      },
      (session) => StartupDecision(StartupDestination.home, session: session),
    );
  }
}
