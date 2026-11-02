abstract final class AppRoutes {
  /// Launch screen: decides onboarding / login / home (auto-login).
  static const startup = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const success = '/success';
}

/// Arguments for the success screen.
class SuccessArgs {
  const SuccessArgs({required this.title, required this.body, required this.rows});
  final String title;
  final String body;

  /// Label / value pairs shown in the summary.
  final List<(String, String)> rows;
}
