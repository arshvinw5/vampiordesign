import '../../../../core/presentation/form_controller.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/register_user.dart';

class RegisterController extends FormController {
  RegisterController({required this._registerUser});

  final RegisterUser _registerUser;

  Future<AuthSession?> register({
    required String fullName,
    required String email,
    required String mobileDigits,
    required String password,
  }) async {
    final result = await run(
      () => _registerUser(
        RegisterParams(
          fullName: fullName.trim(),
          email: email.trim(),
          mobile: mobileDigits,
          password: password,
        ),
      ),
    );
    return result?.fold((_) => null, (session) => session);
  }
}
