import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/domain/usecases/get_remembered_identifier.dart';
import '../../features/auth/domain/usecases/login_user.dart';
import '../../features/auth/domain/usecases/register_user.dart';
import '../../features/auth/domain/usecases/request_password_reset.dart';
import '../../features/auth/presentation/controllers/forgot_password_controller.dart';
import '../../features/auth/presentation/controllers/login_controller.dart';
import '../../features/auth/presentation/controllers/register_controller.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/success_page.dart';
import '../../features/onboarding/domain/usecases/onboarding_usecases.dart';
import '../../features/onboarding/presentation/controllers/onboarding_controller.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../theme/app_motion.dart';
import 'app_routes.dart';

/// Named-route table. Each screen gets its own controller, scoped to the
/// route, so state is disposed when the screen is popped.
abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.onboarding => ChangeNotifierProvider(
          create: (c) => OnboardingController(completeOnboarding: c.read<CompleteOnboarding>()),
          child: const OnboardingPage(),
        ),
      AppRoutes.register => ChangeNotifierProvider(
          create: (c) => RegisterController(registerUser: c.read<RegisterUser>()),
          child: const RegisterPage(),
        ),
      AppRoutes.forgotPassword => ChangeNotifierProvider(
          create: (c) => ForgotPasswordController(requestReset: c.read<RequestPasswordReset>()),
          child: ForgotPasswordPage(initialIdentifier: settings.arguments as String?),
        ),
      AppRoutes.success when settings.arguments is SuccessArgs =>
        SuccessPage(args: settings.arguments! as SuccessArgs),
      // Login is also the fallback for unknown routes or a Success with no data.
      _ => ChangeNotifierProvider(
          create: (c) => LoginController(
            loginUser: c.read<LoginUser>(),
            getRemembered: c.read<GetRememberedIdentifier>(),
          ),
          child: const LoginPage(),
        ),
    };
    return FadeSlidePageRoute(settings: settings, child: page);
  }
}

/// Screen change: fade + 24px horizontal slide, 260ms ease-out. Forward
/// pushes enter from the right; pops reverse. Reduced motion → fade only.
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  FadeSlidePageRoute({required Widget child, super.settings})
      : super(
          transitionDuration: AppMotion.screen,
          reverseTransitionDuration: AppMotion.screen,
          pageBuilder: (context, _, _) => child,
          transitionsBuilder: (context, animation, _, child) {
            final curved = CurvedAnimation(parent: animation, curve: AppMotion.easeOut);
            final reduced = AppMotion.reduced(context);
            return FadeTransition(
              opacity: curved,
              child: reduced
                  ? child
                  : AnimatedBuilder(
                      animation: curved,
                      child: child,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(24 * (1 - curved.value), 0),
                        child: child,
                      ),
                    ),
            );
          },
        );
}
