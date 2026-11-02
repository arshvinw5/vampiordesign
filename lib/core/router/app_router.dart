import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/controllers/forgot_password_controller.dart';
import '../../features/auth/presentation/controllers/home_controller.dart';
import '../../features/auth/presentation/controllers/login_controller.dart';
import '../../features/auth/presentation/controllers/register_controller.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/success_page.dart';
import '../../features/onboarding/presentation/controllers/onboarding_controller.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/startup/presentation/controllers/startup_controller.dart';
import '../../features/startup/presentation/pages/startup_page.dart';
import '../di/service_locator.dart';
import '../theme/app_motion.dart';
import 'app_routes.dart';

/// Named-route table. Each screen gets a fresh controller from the service
/// locator (registered as a factory), provided to its subtree with Provider
/// and disposed when the route is removed.
abstract final class AppRouter {
  static Widget _scoped<T extends ChangeNotifier>(Widget page) =>
      ChangeNotifierProvider<T>(create: (_) => sl<T>(), child: page);

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.startup => _scoped<StartupController>(const StartupPage()),
      AppRoutes.onboarding => _scoped<OnboardingController>(const OnboardingPage()),
      AppRoutes.register => _scoped<RegisterController>(const RegisterPage()),
      AppRoutes.forgotPassword => _scoped<ForgotPasswordController>(
        ForgotPasswordPage(initialIdentifier: settings.arguments as String?),
      ),
      AppRoutes.success when settings.arguments is SuccessArgs => _scoped<HomeController>(
        SuccessPage(args: settings.arguments! as SuccessArgs),
      ),
      // Login is also the fallback for unknown routes or a Success with no data.
      _ => _scoped<LoginController>(const LoginPage()),
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
