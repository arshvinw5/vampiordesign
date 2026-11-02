import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text_styles.dart';
import 'pressable.dart';

/// Outlined navy button (56 tall, 2px border, 5% navy fill).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      semanticLabel: label,
      builder: (context, hovered, pressed) => AnimatedContainer(
        duration: AppMotion.color,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: hovered ? AppColors.ice : const Color(0x0D023E8A),
          border: Border.all(color: AppColors.navy, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ExcludeSemantics(
          child: Text(label, style: AppTextStyles.button.copyWith(color: AppColors.navy)),
        ),
      ),
    );
  }
}
