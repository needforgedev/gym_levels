import 'package:flutter/material.dart';
import 'tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppPalette.voidBg,
      colorScheme: base.colorScheme.copyWith(
        surface: AppPalette.carbon,
        primary: AppPalette.teal,
        secondary: AppPalette.purple,
        error: AppPalette.danger,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppPalette.textPrimary,
        displayColor: AppPalette.textPrimary,
      ),
      splashFactory: InkRipple.splashFactory,
      splashColor: AppPalette.teal.withValues(alpha: 0.08),
      highlightColor: AppPalette.teal.withValues(alpha: 0.04),
    );
  }
}
