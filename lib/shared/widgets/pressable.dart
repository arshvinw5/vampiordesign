import 'package:flutter/widgets.dart';

import '../../core/theme/app_motion.dart';

/// Hover / press tracking with a 0.97 press scale (DESIGN.md §4).
/// [builder] receives the current hover and press state for colouring.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.builder,
    this.semanticLabel,
    this.enabled = true,
  });

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool hovered, bool pressed) builder;
  final String? semanticLabel;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _active => widget.enabled && widget.onTap != null;

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return Semantics(
      button: true,
      enabled: _active,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: _active ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _active ? (_) => _setPressed(true) : null,
          onTapUp: _active ? (_) => _setPressed(false) : null,
          onTapCancel: () => _setPressed(false),
          onTap: _active ? widget.onTap : null,
          child: AnimatedScale(
            scale: _pressed && !reduced ? 0.97 : 1,
            duration: AppMotion.press,
            curve: AppMotion.easeOut,
            child: widget.builder(context, _hovered && _active, _pressed && _active),
          ),
        ),
      ),
    );
  }
}
