import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_text_link.dart';
import 'brand_mark.dart';

/// On phones, the screen is full-bleed white. On tablets and desktops it
/// becomes a framed 400×≤800 card centred on the ice background, matching
/// the prototype.
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({super.key, required this.child});
  final Widget child;

  static const maxContentWidth = 400.0;
  static const _framedBreakpoint = 600.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final framed = c.maxWidth >= _framedBreakpoint && c.maxHeight >= 640;
        if (!framed) {
          return ColoredBox(
            color: AppColors.surface,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth * 1.5),
                  child: child,
                ),
              ),
            ),
          );
        }
        return ColoredBox(
          color: AppColors.ice,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth, maxHeight: 800),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.navy, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1F023E8A), blurRadius: 48, offset: Offset(0, 24)),
                      ],
                    ),
                    child: ClipRect(child: child),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 64px top bar: optional back button, brand mark and optional trailing action.
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, this.onBack, this.trailingLabel, this.onTrailing});

  final VoidCallback? onBack;
  final String? trailingLabel;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            if (onBack != null)
              Transform.translate(
                offset: const Offset(-12, 0),
                child: IconButton(
                  onPressed: onBack,
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back, color: AppColors.navy),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    overlayColor: Colors.transparent,
                  ),
                ),
              ),
            if (onBack != null) const Spacer(),
            const BrandMark(),
            if (onBack == null) const Spacer(),
            if (trailingLabel != null)
              AppTextLink(
                label: trailingLabel!,
                onPressed: onTrailing,
                color: AppColors.ink64,
                hoverColor: AppColors.navy,
              ),
          ],
        ),
      ),
    );
  }
}
