import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/responsive_frame.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/slide_art.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pager = PageController();

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    final reduced = AppMotion.reduced(context);
    if (reduced) {
      _pager.jumpToPage(index);
    } else {
      _pager.animateToPage(index, duration: AppMotion.pager, curve: AppMotion.easeDrawer);
    }
  }

  Future<void> _finish() async {
    await context.read<OnboardingController>().complete();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();
    const slides = OnboardingController.slides;

    return Scaffold(
      backgroundColor: AppColors.ice,
      body: ResponsiveFrame(
        child: Column(
          children: [
            AppTopBar(trailingLabel: 'Skip', onTrailing: _finish),
            Expanded(
              child: Semantics(
                label: 'Step ${controller.index + 1} of ${slides.length}',
                child: PageView.builder(
                  key: const Key('onboarding.pager'),
                  controller: _pager,
                  itemCount: slides.length,
                  onPageChanged: controller.setIndex,
                  itemBuilder: (context, i) => _SlideView(slide: slides[i], number: i + 1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _OnboardingControls(
                index: controller.index,
                count: slides.length,
                isFirst: controller.isFirst,
                isLast: controller.isLast,
                onDot: _goTo,
                onBack: () => _goTo(controller.index - 1),
                onNext: controller.isLast ? _finish : () => _goTo(controller.index + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress dots + Back + Next/Get started.
///
/// If everything fits (measured with the real label style and the user's
/// text scale): one row, dots left, buttons right. Otherwise (320px phones,
/// large accessibility text), dots sit above and Next fills the row, so
/// "Get started" is never squeezed or clipped.
class _OnboardingControls extends StatelessWidget {
  const _OnboardingControls({
    required this.index,
    required this.count,
    required this.isFirst,
    required this.isLast,
    required this.onDot,
    required this.onBack,
    required this.onNext,
  });

  final int index;
  final int count;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<int> onDot;
  final VoidCallback onBack;
  final VoidCallback onNext;

  static const _dotsWidth = 96.0; // 3 × 32px tap targets
  static const _backWidth = 48.0 + 8;
  static const _buttonChrome = 24.0 + 16 + 16 + 20; // padding, gap, arrow
  static const _buttonMinWidth = 152.0;

  /// Width the one-row layout needs, measured with the longest label.
  double _rowWidthNeeded(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'Get started',
        style: DefaultTextStyle.of(context).style.merge(AppTextStyles.button),
      ),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final button = (painter.width + _buttonChrome).clamp(_buttonMinWidth, double.infinity);
    painter.dispose();
    return _dotsWidth + _backWidth + button;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < _rowWidthNeeded(context);
        final dots = Transform.translate(
          offset: const Offset(-4, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < count; i++)
                _ProgressSegment(
                  active: i == index,
                  label: 'Go to step ${i + 1}',
                  onTap: () => onDot(i),
                ),
            ],
          ),
        );
        final next = PrimaryButton(
          key: const Key('onboarding.next'),
          label: isLast ? 'Get started' : 'Next',
          height: 48,
          minWidth: 152,
          elevated: false,
          expand: compact,
          onPressed: onNext,
        );
        final back = [
          if (!isFirst) ...[_BackSquare(onTap: onBack), const SizedBox(width: 8)],
        ];

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              dots,
              const SizedBox(height: 8),
              Row(
                children: [
                  ...back,
                  Expanded(child: next),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Align(alignment: Alignment.centerLeft, child: dots),
            ),
            ...back,
            next,
          ],
        );
      },
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.number});
  final OnboardingSlide slide;
  final int number;

  @override
  Widget build(BuildContext context) {
    final text = Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('0$number / 03', style: AppTextStyles.counter),
          const SizedBox(height: 8),
          Text(slide.title, style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text(slide.body, style: AppTextStyles.body),
        ],
      ),
    );
    // Art fills whatever height the text leaves (min 96). If the text alone
    // doesn't fit (small or landscape phones, large font scale), the slide scrolls.
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 96),
                    child: SlideArt(cells: slide.cells),
                  ),
                ),
                text,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({required this.active, required this.label, required this.onTap});
  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        builder: (context, hovered, pressed) => Container(
          width: 32,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: AppMotion.labelSwap,
            height: 4,
            color: active ? AppColors.navy : AppColors.pale,
          ),
        ),
      ),
    );
  }
}

class _BackSquare extends StatelessWidget {
  const _BackSquare({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Previous',
      builder: (context, hovered, pressed) => AnimatedContainer(
        duration: AppMotion.color,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0x0D023E8A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hovered ? AppColors.navy : AppColors.pale, width: 2),
        ),
        child: const Icon(Icons.arrow_back, size: 20, color: AppColors.navy),
      ),
    );
  }
}
