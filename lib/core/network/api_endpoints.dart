/// REST contract shared by the app and the (mock) backend.
abstract final class ApiEndpoints {
  static const baseUrl = 'https://api.vampior.mock/v1';

  // Public: no Authorization header (see [publicRequest]).
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';

  // Protected: `Authorization: Bearer <accessToken>`.
  static const me = '/auth/me';

  /// `Options.extra` flag read by `AuthInterceptor`.
  static const authExtraKey = 'auth';
  static const publicRequest = {authExtraKey: false};
}
