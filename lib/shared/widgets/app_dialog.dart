import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text_styles.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Shows the app's standard confirmation dialog and resolves to `true` only
/// if the user taps [confirmLabel]. Cancel, tapping outside, and the system
/// back gesture all resolve to `false`.
///
/// ```dart
/// final ok = await showConfirmDialog(
///   context,
///   title: 'Log out?',
///   message: 'You will need to sign in again to continue.',
///   confirmLabel: 'Log out',
///   destructive: true,
/// );
/// if (ok) …
/// ```
///
/// Reuse it for any action that needs a second look (delete, discard
/// changes, cancel order…).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: cancelLabel,
    barrierColor: const Color(0x8C0B1D33), // ink @ 55%
    transitionDuration: AppMotion.screen,
    pageBuilder: (context, _, _) => AppConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      icon: icon,
    ),
    // Fade + slight scale-up (0.96 → 1), 260ms ease-out; fade only with reduced motion.
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.easeOut);
      return FadeTransition(
        opacity: curved,
        child: AppMotion.reduced(context)
            ? child
            : ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(curved), child: child),
      );
    },
  );
  return result ?? false;
}

/// The dialog body, matching DESIGN.md: white card, 2px navy frame, 24px
/// padding, title 28/700 navy, body 16 ink-80, full-width stacked actions
/// (primary on top, in the thumb zone).
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.destructive = false,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.error : AppColors.navy;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.navy, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33023E8A), blurRadius: 48, offset: Offset(0, 24)),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (icon != null) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 48,
                            height: 48,
                            color: accent.withValues(alpha: 0.08),
                            child: Icon(icon, color: accent, size: 24),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Semantics(
                        header: true,
                        child: Text(title, style: AppTextStyles.title.copyWith(fontSize: 24)),
                      ),
                      const SizedBox(height: 8),
                      Text(message, style: AppTextStyles.body),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        key: const Key('dialog.confirm'),
                        label: confirmLabel,
                        destructive: destructive,
                        elevated: false,
                        icon: icon ?? Icons.arrow_forward,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                      const SizedBox(height: 8),
                      SecondaryButton(
                        key: const Key('dialog.cancel'),
                        label: cancelLabel,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
