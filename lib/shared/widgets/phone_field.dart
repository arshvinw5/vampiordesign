import 'package:flutter/material.dart';

import '../../core/utils/phone_formatter.dart';
import '../../core/validation/validators.dart';
import 'app_text_field.dart';

/// Prebuilt Sri Lankan mobile number input (DESIGN.md §5 PhoneField).
///
/// - Fixed, non-editable `+94` prefix: users never type the country code.
/// - Formats as you type or paste: `0771234567`, `+94771234567` and
///   `77 123 4567` all become `77 123 4567`.
/// - Numeric phone keyboard, `telephoneNumberNational` autofill, 9-digit cap.
/// - Built-in validation (9 digits starting with 7), overridable with [validator].
///
/// Read the clean value with [PhoneField.digitsOf] (e.g. `771234567`), or
/// [LkMobile.international] for display (`+94 77 123 4567`).
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.fieldKey,
    this.label = 'Mobile number',
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.forceValidation = false,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final Key? fieldKey;
  final String label;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final bool forceValidation;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;

  /// The 9 national digits typed into [controller], e.g. `771234567`.
  static String digitsOf(TextEditingController controller) => LkMobile.parse(controller.text);

  /// Default rule: [Validators.mobile] on the parsed digits.
  static String? validate(String? text) => Validators.mobile(LkMobile.parse(text ?? ''));

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      fieldKey: fieldKey,
      controller: controller,
      focusNode: focusNode,
      label: label,
      placeholder: '77 123 4567',
      icon: Icons.smartphone,
      prefixText: LkMobile.prefix,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [LkMobileInputFormatter()],
      maxLength: 11, // "77 123 4567"
      validator: validator ?? validate,
      forceValidation: forceValidation,
      onSubmitted: onSubmitted,
    );
  }
}
