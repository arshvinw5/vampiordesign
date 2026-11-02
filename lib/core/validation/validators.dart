/// Pure field validators (DESIGN.md §7). Each returns `null` when valid,
/// so they plug straight into `TextFormField.validator`.
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _phone = RegExp(r'^\+?\d{9,15}$');
  static final _name = RegExp(r"^[A-Za-z][A-Za-z .'-]+$");
  static final _lkMobile = RegExp(r'^7\d{8}$');

  static String _digits(String s) => s.replaceAll(RegExp(r'[\s()-]'), '');

  static bool isEmail(String v) => _email.hasMatch(v.trim());
  static bool isPhone(String v) => _phone.hasMatch(_digits(v));

  /// Login / reset identifier: email or 9–15 digit mobile.
  static String? identifier(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email or mobile number is required';
    if (isEmail(s) || isPhone(s)) return null;
    return 'Enter a valid email or mobile number';
  }

  static String? loginPassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password is required';
    if (s.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? fullName(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Full name is required';
    if (!_name.hasMatch(s)) return 'Use letters only';
    if (s.split(RegExp(r'\s+')).length < 2) return 'Enter first and last name';
    return null;
  }

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email address is required';
    if (!isEmail(s)) return 'Enter a valid email address';
    return null;
  }

  /// [digits] are the 9 national digits (no +94, no spaces).
  static String? mobile(String? digits) {
    final s = (digits ?? '').replaceAll(RegExp(r'\D'), '');
    if (s.isEmpty) return 'Mobile number is required';
    if (!_lkMobile.hasMatch(s)) return 'Enter a 9-digit number starting with 7';
    return null;
  }

  static String? newPassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password is required';
    if (s.length < 8) return 'At least 8 characters';
    if (!RegExp('[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
      return 'Use letters and at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    final s = v ?? '';
    if (s.isEmpty) return 'Please confirm your password';
    if (s != original) return 'Passwords do not match';
    return null;
  }
}
