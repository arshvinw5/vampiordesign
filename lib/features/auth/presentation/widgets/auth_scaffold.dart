import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_link.dart';
import '../../../../shared/widgets/responsive_frame.dart';

/// Layout shared by every form screen: a fixed top bar, a scrollable title
/// block and fields, and a CTA bar pinned in the thumb zone. While
/// [loading], the content dims to 55% and ignores taps.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.cta,
    this.footer,
    this.onBack,
    this.loading = false,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final Widget cta;
  final Widget? footer;
  final VoidCallback? onBack;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ice,
      body: ResponsiveFrame(
        child: Column(
          children: [
            AppTopBar(onBack: onBack),
            Expanded(
              child: AnimatedOpacity(
                opacity: loading ? 0.55 : 1,
                duration: AppMotion.labelSwap,
                curve: AppMotion.easeOut,
                child: IgnorePointer(
                  ignoring: loading,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TitleBlock(title: title, subtitle: subtitle),
                        const SizedBox(height: 24),
                        body,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  cta,
                  if (footer != null) ...[const SizedBox(height: 8), footer!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.pale, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: AppTextStyles.title)),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

/// "No account? Create one" style footer.
class FooterPrompt extends StatelessWidget {
  const FooterPrompt({super.key, required this.text, required this.linkLabel, required this.onTap});

  final String text;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(text, style: AppTextStyles.secondary),
        AppTextLink(label: linkLabel, onPressed: onTap),
      ],
    );
  }
}
