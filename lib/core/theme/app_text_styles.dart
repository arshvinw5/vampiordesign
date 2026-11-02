import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Type scale from DESIGN.md §2. Family is applied globally by the theme.
abstract final class AppTextStyles {
  static const title = TextStyle(
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: AppColors.navy,
  );
  static const body = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.ink80,
  );
  static const input = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );
  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.navy,
  );
  static const secondary = TextStyle(fontSize: 14, color: AppColors.ink64);
  static const meta = TextStyle(fontSize: 12, height: 16 / 12, color: AppColors.ink64);
  static const counter = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 12 * 0.08,
    color: AppColors.blue,
  );
  static const brand = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 14 * 0.08,
    color: AppColors.navy,
  );
}
