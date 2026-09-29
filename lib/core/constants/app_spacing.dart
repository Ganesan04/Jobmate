/// Core spacing scale (8px system) used across the app.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 40;

  /// Horizontal screen padding.
  static const double screen = 20;

  /// Gap under a section header.
  static const double sectionGap = 12;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 380);
}

abstract final class AppSizes {
  /// Minimum tappable height for interactive elements.
  static const double touchTarget = 48;
  static const double buttonHeight = 52;
  static const double avatarSm = 36;
  static const double avatarMd = 48;
  static const double avatarLg = 88;
  static const double maxContentWidth = 560;
  static const double bottomNavHeight = 68;
  static const double topBarHeight = 56;
}
