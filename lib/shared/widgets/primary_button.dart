import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text_styles.dart';
import 'pressable.dart';

/// Navy call-to-action with a flush-left label and trailing arrow.
///
/// While [loading], the idle label exits upward and the busy label + spinner
/// rise into the same slot, so the button never resizes. Repeated taps
/// are ignored.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loadingLabel,
    this.loading = false,
    this.height = 56,
    this.minWidth,
    this.elevated = true,
  });

  final String label;
  final String? loadingLabel;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final double? minWidth;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return Pressable(
      onTap: loading ? null : onPressed,
      enabled: !loading,
      semanticLabel: loading ? (loadingLabel ?? label) : label,
      builder: (context, hovered, pressed) => AnimatedContainer(
        duration: AppMotion.color,
        height: height,
        constraints: BoxConstraints(minWidth: minWidth ?? 0),
        padding: const EdgeInsets.only(left: 24, right: 16),
        decoration: BoxDecoration(
          color: pressed
              ? AppColors.navyPressed
              : hovered
                  ? AppColors.blue
                  : AppColors.navy,
          borderRadius: BorderRadius.circular(8),
          boxShadow: elevated
              ? const [BoxShadow(color: Color(0x33023E8A), blurRadius: 24, offset: Offset(0, 8))]
              : null,
        ),
        child: ExcludeSemantics(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              _SwapLayer(
                visible: !loading,
                exitDy: -6,
                reduced: reduced,
                child: _Row(text: label, trailing: const Icon(Icons.arrow_forward, size: 20)),
              ),
              _SwapLayer(
                visible: loading,
                exitDy: 6,
                reduced: reduced,
                // Pause the spinner's ticker while hidden so idle screens settle.
                child: TickerMode(
                  enabled: loading,
                  child: _Row(text: loadingLabel ?? label, trailing: const _Spinner()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.text, required this.trailing});
  final String text;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: const IconThemeData(color: Colors.white),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }
}

/// Opacity + 6px slide + 2px blur, 200ms ease-out.
class _SwapLayer extends StatelessWidget {
  const _SwapLayer({
    required this.visible,
    required this.exitDy,
    required this.reduced,
    required this.child,
  });

  final bool visible;
  final double exitDy;
  final bool reduced;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: visible ? 1 : 0),
      duration: AppMotion.labelSwap,
      curve: AppMotion.easeOut,
      child: child,
      builder: (context, t, child) {
        final hidden = 1 - t;
        Widget out = Opacity(opacity: t, child: child);
        if (!reduced) {
          out = Transform.translate(offset: Offset(0, exitDy * hidden), child: out);
          if (hidden > 0.01) {
            out = ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: hidden, sigmaY: hidden),
              child: out,
            );
          }
        }
        return IgnorePointer(ignoring: !visible, child: out);
      },
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white,
        backgroundColor: Color(0x59FFFFFF),
      ),
    );
  }
}
