import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  /// Archivo 400/700 is bundled in `assets/fonts` (see pubspec), so text
  /// renders the same offline and real bold is used, not a synthesized one.
  static const fontFamily = 'Archivo';

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: Colors.white,
        secondary: AppColors.blue,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.error,
      ),
      splashFactory: NoSplash.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.navy,
        selectionColor: Color(0x4048CAE4),
        selectionHandleColor: AppColors.navy,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.navy : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.ink40, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
