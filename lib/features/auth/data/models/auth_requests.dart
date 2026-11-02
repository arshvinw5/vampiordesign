/// Request bodies sent to the auth API.
class LoginRequest {
  const LoginRequest({required this.identifier, required this.password});
  final String identifier;
  final String password;

  Map<String, dynamic> toJson() => {'identifier': identifier, 'password': password};
}

class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.password,
  });
  final String fullName;
  final String email;

  /// 9 national digits.
  final String mobile;
  final String password;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'mobile': mobile,
        'password': password,
      };
}

class ForgotPasswordRequest {
  const ForgotPasswordRequest(this.identifier);
  final String identifier;

  Map<String, dynamic> toJson() => {'identifier': identifier};
}
