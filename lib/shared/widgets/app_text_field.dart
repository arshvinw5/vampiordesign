import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text_styles.dart';

/// The design-system text field (DESIGN.md §5 TextField).
///
/// - Label above, 48px box, 2px border: pale idle · sky valid · blue focus · red error.
/// - Leading icon (or fixed text prefix such as `+94`) coloured by state.
/// - Trailing eye toggle when [obscurable], or a check when valid.
/// - A 16px message row is always reserved (error › hint) so the layout never jumps.
/// - Validation shows after the field is blurred with content, or once
///   [forceValidation] is set (after a submit attempt), then updates live.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.fieldKey,
    this.validator,
    this.hint,
    this.placeholder,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.obscurable = false,
    this.prefixText,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.focusNode,
    this.showValidCheck = true,
    this.forceValidation = false,
    this.maxLength,
    this.below,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  /// Key applied to the inner `TextField` (handy for tests).
  final Key? fieldKey;
  final FormFieldValidator<String>? validator;

  /// Helper text shown in the message row while there is no error.
  final String? hint;
  final String? placeholder;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscurable;

  /// Fixed, non-editable prefix (replaces the leading icon).
  final String? prefixText;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool showValidCheck;
  final bool forceValidation;
  final int? maxLength;

  /// Extra widget between the field and the message row (e.g. a strength meter).
  final Widget? below;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  static const _boxHeight = 48.0;

  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  bool _touched = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocusChange);
      _focus.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.removeListener(_onFocusChange);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onFocusChange() {
    setState(() {
      if (!_focus.hasFocus && widget.controller.text.isNotEmpty) _touched = true;
    });
  }

  bool get _validating => _touched || widget.forceValidation;
  String? get _error => _validating ? widget.validator?.call(widget.controller.text) : null;
  bool get _valid =>
      _validating &&
      widget.controller.text.isNotEmpty &&
      widget.validator?.call(widget.controller.text) == null;

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null;
    final valid = _valid;
    final focused = _focus.hasFocus;
    final iconColor = hasError
        ? AppColors.error
        : valid
        ? AppColors.blue
        : AppColors.ink40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Focus ring behind the input box.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: _boxHeight,
              child: AnimatedContainer(
                duration: AppMotion.color,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: focused && !hasError
                      ? const [BoxShadow(color: Color(0x4048CAE4), spreadRadius: 4)]
                      : const [],
                ),
              ),
            ),
            TextField(
              key: widget.fieldKey,
              controller: widget.controller,
              focusNode: _focus,
              obscureText: widget.obscurable && _obscured,
              enableSuggestions: !widget.obscurable,
              autocorrect: false,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              inputFormatters: widget.inputFormatters,
              textCapitalization: widget.textCapitalization,
              maxLength: widget.maxLength,
              onSubmitted: widget.onSubmitted,
              style: AppTextStyles.input,
              cursorColor: AppColors.navy,
              decoration: InputDecoration(
                constraints: const BoxConstraints(minHeight: _boxHeight, maxHeight: _boxHeight),
                isDense: true,
                filled: true,
                fillColor: AppColors.surface,
                counterText: '',
                hintText: widget.placeholder,
                hintStyle: AppTextStyles.input.copyWith(color: AppColors.ink40),
                contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
                prefixIcon: widget.prefixText != null
                    ? _TextPrefix(widget.prefixText!)
                    : SizedBox(
                        width: 44,
                        child: AnimatedSwitcher(
                          duration: AppMotion.color,
                          child: Icon(
                            widget.icon,
                            key: ValueKey(iconColor),
                            size: 20,
                            color: iconColor,
                          ),
                        ),
                      ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 44),
                suffixIcon: _buildSuffix(valid),
                suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                // Error state is owned here (not by FormField) so the message
                // row can sit below [below] and never shift the layout.
                enabledBorder: _border(
                  hasError
                      ? AppColors.error
                      : valid
                      ? AppColors.sky
                      : AppColors.pale,
                ),
                focusedBorder: _border(hasError ? AppColors.error : AppColors.blue),
              ),
            ),
          ],
        ),
        if (widget.below != null) ...[const SizedBox(height: 8), widget.below!],
        const SizedBox(height: 8),
        _MessageRow(text: _error ?? (valid ? null : widget.hint), isError: hasError),
      ],
    );
  }

  Widget? _buildSuffix(bool valid) {
    if (widget.obscurable) {
      return IconButton(
        onPressed: () => setState(() => _obscured = !_obscured),
        tooltip: _obscured ? 'Show password' : 'Hide password',
        isSelected: !_obscured,
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: AppColors.ink64,
        ),
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          overlayColor: Colors.transparent,
        ),
      );
    }
    if (valid && widget.showValidCheck) return const _ValidCheck();
    return null;
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color, width: 2),
  );
}

class _TextPrefix extends StatelessWidget {
  const _TextPrefix(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.pale, width: 2)),
      ),
      // widthFactor: 1 keeps the prefix hugging its text instead of
      // expanding to the field's full width.
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
      ),
    );
  }
}

class _ValidCheck extends StatelessWidget {
  const _ValidCheck();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.labelSwap,
      curve: AppMotion.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
      ),
      child: const Icon(Icons.check, size: 20, color: AppColors.blue, semanticLabel: 'Valid'),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.text, required this.isError});
  final String? text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 16),
      child: Semantics(
        liveRegion: isError,
        child: AnimatedDefaultTextStyle(
          duration: AppMotion.color,
          style: AppTextStyles.meta.copyWith(
            color: isError ? AppColors.error : AppColors.ink64,
            fontFamily: DefaultTextStyle.of(context).style.fontFamily,
          ),
          child: Text(text ?? ''),
        ),
      ),
    );
  }
}
