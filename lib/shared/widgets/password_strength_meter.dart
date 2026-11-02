import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/password_strength.dart';

/// Four 4px segments + label. Hidden while the password is empty.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.controller});
  final TextEditingController controller;

  static const _colors = {
    PasswordStrength.weak: AppColors.error,
    PasswordStrength.fair: AppColors.sky,
    PasswordStrength.good: AppColors.blue,
    PasswordStrength.strong: AppColors.navy,
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final strength = PasswordStrength.of(value.text);
        if (strength == PasswordStrength.none) return const SizedBox.shrink();
        final color = _colors[strength]!;
        return Semantics(
          label: 'Password strength ${strength.label}',
          excludeSemantics: true,
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: AnimatedContainer(
                          duration: AppMotion.labelSwap,
                          height: 4,
                          color: i < strength.index ? color : AppColors.meterTrack,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(
                  strength.label,
                  style: AppTextStyles.meta.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
