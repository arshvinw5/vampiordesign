import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text_styles.dart';
import 'pressable.dart';

/// 14/700 navy link with a 44px minimum tap height. Hover → blue.
class AppTextLink extends StatelessWidget {
  const AppTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.navy,
    this.hoverColor = AppColors.blue,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color hoverColor;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      semanticLabel: label,
      builder: (context, hovered, _) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.color,
            style: AppTextStyles.link.copyWith(
              color: hovered ? hoverColor : color,
              fontFamily: DefaultTextStyle.of(context).style.fontFamily,
            ),
            child: ExcludeSemantics(child: Text(label)),
          ),
        ),
      ),
    );
  }
}
