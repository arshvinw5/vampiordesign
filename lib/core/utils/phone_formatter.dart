import 'package:flutter/services.dart';

/// Sri Lankan mobile helpers: stored as 9 digits, shown as `77 123 4567`
/// after a fixed `+94` prefix.
abstract final class LkMobile {
  static const prefix = '+94';

  /// Strips non-digits, a pasted `94` country code and leading zeros.
  static String parse(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('94') && d.length > 9) d = d.substring(2);
    d = d.replaceFirst(RegExp(r'^0+'), '');
    return d.length > 9 ? d.substring(0, 9) : d;
  }

  static String format(String digits) {
    final parts = <String>[
      if (digits.isNotEmpty) digits.substring(0, digits.length.clamp(0, 2)),
      if (digits.length > 2) digits.substring(2, digits.length.clamp(2, 5)),
      if (digits.length > 5) digits.substring(5, digits.length.clamp(5, 9)),
    ];
    return parts.join(' ');
  }

  static String international(String digits) => '$prefix ${format(digits)}';
}

/// Keeps the field text formatted as `77 123 4567` while typing or pasting.
class LkMobileInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = LkMobile.format(LkMobile.parse(newValue.text));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
