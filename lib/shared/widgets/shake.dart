import 'package:flutter/widgets.dart';

import '../../core/theme/app_motion.dart';

/// Horizontal "no" shake (-6 / 5 / -3 px, 280ms) for invalid submits.
/// Trigger it through a `GlobalKey<ShakeState>`.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.child});
  final Widget child;

  @override
  State<Shake> createState() => ShakeState();
}

class ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppMotion.shake);

  late final Animation<double> _dx = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -6, end: 5), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 5, end: -3), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: AppMotion.easeInOut));

  void shake() {
    if (AppMotion.reduced(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dx,
      child: widget.child,
      builder: (context, child) => Transform.translate(offset: Offset(_dx.value, 0), child: child),
    );
  }
}
