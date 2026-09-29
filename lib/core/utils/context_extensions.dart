import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Convenience accessors so widgets never hard-code colours.
extension ThemeContext on BuildContext {
  Color get primary => Theme.of(this).colorScheme.primary;
  Color get secondary => Theme.of(this).colorScheme.secondary;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get onPrimary => Theme.of(this).colorScheme.onPrimary;
  TextTheme get texts => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Very light wash of the active role colour, used for chips and banners.
  Color get primaryTint =>
      Color.lerp(primary, Colors.white, 0.9) ?? AppColors.workerSurface;

  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get error => AppColors.error;
  Color get info => AppColors.info;

  /// Clamps content width so the layout still looks right on wide screens.
  double get contentMaxWidth => 560;
}

/// Design-spec text roles mapped onto the Material 3 [TextTheme] slots, so
/// widgets read `texts.caption` / `texts.body` / `texts.title` consistently.
extension AppTextThemeX on TextTheme {
  /// 12.5px secondary text (spec: "caption").
  TextStyle? get caption => labelMedium;

  /// 11.5px tracked uppercase label (spec: "overline").
  TextStyle? get overline => labelSmall;

  /// 15px primary body text.
  TextStyle? get body => bodyLarge;

  /// 14px secondary body text (spec: "body secondary").
  TextStyle? get bodySecondary => bodyMedium;

  /// 28px screen title (spec: "display").
  TextStyle? get display => displaySmall;

  /// 22px section title (spec: "headline").
  TextStyle? get headline => headlineSmall;

  /// 18px card and list title (spec: "title").
  TextStyle? get title => titleLarge;

  /// 16px emphasised row title (spec: "subtitle").
  TextStyle? get subtitle => titleMedium;

  /// 14px field and button label (spec: "label").
  TextStyle? get label => labelLarge;
}
