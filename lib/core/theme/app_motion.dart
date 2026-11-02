import 'package:flutter/widgets.dart';

/// Motion tokens from DESIGN.md §4.
abstract final class AppMotion {
  static const easeOut = Cubic(0.23, 1, 0.32, 1);
  static const easeInOut = Cubic(0.77, 0, 0.175, 1);
  static const easeDrawer = Cubic(0.32, 0.72, 0, 1);

  static const press = Duration(milliseconds: 160);
  static const color = Duration(milliseconds: 150);
  static const labelSwap = Duration(milliseconds: 200);
  static const screen = Duration(milliseconds: 260);
  static const shake = Duration(milliseconds: 280);
  static const pager = Duration(milliseconds: 300);

  /// True when the platform asks for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
