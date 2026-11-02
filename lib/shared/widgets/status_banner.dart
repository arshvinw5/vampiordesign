import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text_styles.dart';

enum StatusTone { success, error }

/// Inline notice for API outcomes (e.g. "Reset link sent", "Incorrect password").
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.tone = StatusTone.success,
    this.footer,
  });

  final String message;
  final StatusTone tone;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final isError = tone == StatusTone.error;
    final accent = isError ? AppColors.error : AppColors.blue;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: AppMotion.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, AppMotion.reduced(context) ? 0 : 8 * (1 - t)),
          child: child,
        ),
      ),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isError ? const Color(0x0FC62828) : const Color(0x0F0096C7),
            border: Border.all(color: isError ? const Color(0x59C62828) : AppColors.pale, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(isError ? Icons.error_outline : Icons.check, size: 20, color: accent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.ink80),
                    ),
                    if (footer != null) ...[const SizedBox(height: 8), footer!],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating snackbars for transient success / error feedback.
abstract final class AppSnackbar {
  static void show(BuildContext context, String message, {StatusTone tone = StatusTone.success}) {
    final isError = tone == StatusTone.error;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? AppColors.error : AppColors.navy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Row(
            children: [
              Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: AppTextStyles.secondary.copyWith(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
  }
}
