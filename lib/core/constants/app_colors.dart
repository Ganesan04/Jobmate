import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Jobmate design tokens.
/// Colours are taken directly from the product design spec.
abstract final class AppColors {
  // Neutrals
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF7FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Worker (teal)
  static const Color workerPrimary = Color(0xFF0F766E);
  static const Color workerSecondary = Color(0xFF14B8A6);
  static const Color workerSurface = Color(0xFFE6F5F3);
  static const Color workerSurfaceStrong = Color(0xFFCFEBE7);

  // Work giver (purple)
  static const Color giverPrimary = Color(0xFF7C3AED);
  static const Color giverSecondary = Color(0xFFA78BFA);
  static const Color giverSurface = Color(0xFFF1EBFE);
  static const Color giverSurfaceStrong = Color(0xFFE4D9FD);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFDDF7EE);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF3D7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFDE3E3);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSurface = Color(0xFFDDF0FC);
}

/// Soft elevation shadows used by cards and sheets.
abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 26, offset: Offset(0, 12)),
  ];

  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 10, offset: Offset(0, 2)),
  ];
}

/// Spacing helpers mirroring [AppSpacing] for widget code.
abstract final class Insets {
  const Insets._();

  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: AppSpacing.screen,
  );
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets listGap = EdgeInsets.only(bottom: AppSpacing.sm);
  static const EdgeInsets fieldGap = EdgeInsets.only(bottom: AppSpacing.md);
}
