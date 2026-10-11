import 'package:flutter/material.dart';

class DesignTokens {
  // Spacing Scale (4/8pt increment system)
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space18 = 18.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Semantic Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;
  static const double radiusExtraLarge = 28.0;
  static const double radiusFull = 999.0;

  static final BorderRadius borderRadiusSmall =
      BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium =
      BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge =
      BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusCard =
      BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusFull =
      BorderRadius.circular(radiusFull);

  // Elevation Shadows - Subtle, intentional, low-contrast
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> themeSoftShadow(bool isDark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> themeCardShadow(bool isDark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> floatingShadow(Color accentColor,
          [bool isDark = false]) =>
      [
        BoxShadow(
          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  // Motion Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);
}
