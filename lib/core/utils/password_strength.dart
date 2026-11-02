/// Password strength 0–4: length ≥ 8, mixed case, digit, symbol.
enum PasswordStrength {
  none(''),
  weak('Weak'),
  fair('Fair'),
  good('Good'),
  strong('Strong');

  const PasswordStrength(this.label);
  final String label;

  static PasswordStrength of(String pw) {
    if (pw.isEmpty) return none;
    final score = [
      pw.length >= 8,
      RegExp('[a-z]').hasMatch(pw) && RegExp('[A-Z]').hasMatch(pw),
      RegExp(r'\d').hasMatch(pw),
      RegExp(r'[^A-Za-z0-9]').hasMatch(pw),
    ].where((b) => b).length;
    return values[score];
  }
}
