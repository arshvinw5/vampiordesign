import '../../../../core/presentation/form_controller.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/get_remembered_identifier.dart';
import '../../domain/usecases/login_user.dart';

class LoginController extends FormController {
  LoginController({required this._loginUser, required GetRememberedIdentifier getRemembered})
      : initialIdentifier = getRemembered().fold((_) => null, (id) => id);

  final LoginUser _loginUser;

  /// Prefilled from "Remember me".
  final String? initialIdentifier;

  bool _rememberMe = true;
  bool get rememberMe => _rememberMe;

  void setRememberMe(bool value) {
    if (value == _rememberMe) return;
    _rememberMe = value;
    notifyListeners();
  }

  /// Returns the session on success, `null` on failure (see [errorMessage]).
  Future<AuthSession?> login({required String identifier, required String password}) async {
    final result = await run(
      () => _loginUser(
        LoginParams(identifier: identifier.trim(), password: password, rememberMe: _rememberMe),
      ),
    );
    return result?.fold((_) => null, (session) => session);
  }
}
