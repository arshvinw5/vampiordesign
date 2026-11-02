import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';

/// 72px navy square with a check: pops in (0.8 → 1.06 → 1, 420ms) while
/// a sky ring pulses outward twice.
class SuccessBadge extends StatefulWidget {
  const SuccessBadge({super.key});

  @override
  State<SuccessBadge> createState() => _SuccessBadgeState();
}

class _SuccessBadgeState extends State<SuccessBadge> with TickerProviderStateMixin {
  late final _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  late final Animation<double> _popScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.06), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 40),
  ]).animate(CurvedAnimation(parent: _pop, curve: AppMotion.easeOut));

  @override
  void initState() {
    super.initState();
    _pop.forward();
    Future<void>.delayed(const Duration(milliseconds: 250), () async {
      for (var i = 0; i < 2 && mounted; i++) {
        await _ring.forward(from: 0).orCancel.catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _pop.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return SizedBox.square(
      dimension: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!reduced)
            AnimatedBuilder(
              animation: _ring,
              builder: (context, _) {
                final t = AppMotion.easeOut.transform(_ring.value);
                return Positioned.fill(
                  child: Opacity(
                    opacity: _ring.isAnimating ? 0.5 * (1 - t) : 0,
                    child: Transform.scale(
                      scale: 0.9 + 0.7 * t,
                      child: const ColoredBox(color: AppColors.sky),
                    ),
                  ),
                );
              },
            ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pop,
              builder: (context, child) => Opacity(
                opacity: _pop.value.clamp(0.0, 1.0),
                child: Transform.scale(scale: reduced ? 1 : _popScale.value, child: child),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  boxShadow: [
                    BoxShadow(color: Color(0x4D023E8A), blurRadius: 32, offset: Offset(0, 12)),
                  ],
                ),
                child: Icon(Icons.check, size: 36, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
