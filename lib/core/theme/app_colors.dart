import 'package:flutter/material.dart';

/// Centralized Midnight Botanical Semantic Color & Gradient System for Remindly.
/// Editorial personal diary application with warm ivory light mode, rich midnight dark mode,
/// deep botanical-green accents, and restrained champagne gradients.
class AppColors {
  // --- Exact Light Mode Palette (Midnight Botanical) ---
  static const Color lightBackground =
      Color(0xFFF6F3EB); // Main background #F6F3EB
  static const Color lightSurface =
      Color(0xFFFFFFFF); // Primary card surface #FFFFFF
  static const Color lightSurfaceSecondary =
      Color(0xFFEEECE3); // Secondary surface #EEECE3
  static const Color lightSurfaceVariant =
      Color(0xFFEEECE3); // Secondary surface
  static const Color lightElevatedSurface =
      Color(0xFFFFFFFF); // Elevated surface #FFFFFF

  static const Color lightTextPrimary =
      Color(0xFF262A23); // Primary text #262A23
  static const Color lightTextSecondary =
      Color(0xFF55594F); // Secondary text #55594F
  static const Color lightTextMuted = Color(0xFF686C61); // Muted text #686C61
  static const Color lightTextTertiary = Color(0xFF686C61); // Soft Caption

  static const Color lightPrimary =
      Color(0xFF344735); // Primary interactive green #344735
  static const Color lightBotanicalGreen =
      Color(0xFF52664A); // Secondary botanical green #52664A
  static const Color lightChampagne =
      Color(0xFF947644); // Champagne accent #947644
  static const Color lightChampagneSurface =
      Color(0xFFE5D4AF); // Light champagne surface #E5D4AF
  static const Color lightSoftSage = Color(0xFFB6C5A5); // Soft sage #B6C5A5
  static const Color lightBorder = Color(0xFFDED8C9); // Border #DED8C9
  static const Color lightDisabledSurface =
      Color(0xFFEAE7DE); // Disabled surface #EAE7DE

  static const Color lightOnPrimary = Colors.white;
  static const Color lightPrimaryContainer = Color(0xFFEEECE3);
  static const Color lightOnPrimaryContainer = Color(0xFF262A23);
  static const Color lightSecondary = Color(0xFF947644);
  static const Color lightSecondaryContainer = Color(0xFFE5D4AF);

  // --- Exact Dark Mode Palette (Midnight Botanical) ---
  static const Color darkBackground =
      Color(0xFF121713); // Main background #121713
  static const Color darkSurface =
      Color(0xFF1B201B); // Primary card surface #1B201B
  static const Color darkSurfaceSecondary =
      Color(0xFF20251F); // Secondary surface #20251F
  static const Color darkSurfaceVariant =
      Color(0xFF20251F); // Secondary surface
  static const Color darkElevatedSurface =
      Color(0xFF272D26); // Elevated surface #272D26

  static const Color darkTextPrimary =
      Color(0xFFF3EBDD); // Primary text #F3EBDD
  static const Color darkTextSecondary =
      Color(0xFFC7C9BB); // Secondary text #C7C9BB
  static const Color darkTextMuted = Color(0xFFA4A89B); // Muted text #A4A89B
  static const Color darkTextTertiary = Color(0xFFA4A89B); // Soft Metadata

  static const Color darkPrimary =
      Color(0xFFB9C8A9); // Primary interactive green #B9C8A9
  static const Color darkBotanicalGreen =
      Color(0xFFA9B59A); // Secondary botanical green #A9B59A
  static const Color darkChampagne =
      Color(0xFFD8C39A); // Champagne highlight #D8C39A
  static const Color darkSubtleChampagne =
      Color(0xFFC9B58D); // Subtle champagne #C9B58D
  static const Color darkBorder = Color(0xFF363D34); // Border #363D34
  static const Color darkDisabledSurface =
      Color(0xFF292D28); // Disabled surface #292D28

  static const Color darkOnPrimary = Color(0xFF121713);
  static const Color darkPrimaryContainer = Color(0xFF20251F);
  static const Color darkOnPrimaryContainer = Color(0xFFF3EBDD);
  static const Color darkSecondary = Color(0xFFD8C39A);
  static const Color darkSecondaryContainer = Color(0xFF272D26);

  // --- Status & Semantic Colors ---
  static const Color success = Color(0xFF4E9A51); // Forest Green
  static const Color warning = Color(0xFF947644); // Champagne Amber
  static const Color error = Color(0xFFC25450); // Soft Terracotta Rose
  static const Color info = Color(0xFF52664A); // Botanical Sage Accent

  // Categories (Harmonious Organic Palette)
  static const Color categoryWork = Color(0xFF947644); // Champagne Gold
  static const Color categoryHealth = Color(0xFF344735); // Deep Botanical Green
  static const Color categoryStudy =
      Color(0xFF52664A); // Secondary Botanical Green
  static const Color categoryPersonal = Color(0xFFC27D60); // Warm Clay
  static const Color categoryTask = Color(0xFF686C61); // Muted Botanical
  static const Color purple =
      Color(0xFF947644); // Obsolete purple alias mapped to Champagne

  // --- Dynamic Theme Selectors ---
  static Color background(bool isDark) =>
      isDark ? darkBackground : lightBackground;
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color surfaceSecondary(bool isDark) =>
      isDark ? darkSurfaceSecondary : lightSurfaceSecondary;
  static Color surfaceVariant(bool isDark) =>
      isDark ? darkSurfaceVariant : lightSurfaceVariant;
  static Color elevatedSurface(bool isDark) =>
      isDark ? darkElevatedSurface : lightElevatedSurface;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color textPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color textMuted(bool isDark) =>
      isDark ? darkTextMuted : lightTextMuted;
  static Color textTertiary(bool isDark) =>
      isDark ? darkTextTertiary : lightTextTertiary;
  static Color primary(bool isDark) => isDark ? darkPrimary : lightPrimary;
  static Color botanical(bool isDark) =>
      isDark ? darkBotanicalGreen : lightBotanicalGreen;
  static Color champagne(bool isDark) =>
      isDark ? darkChampagne : lightChampagne;
  static Color disabled(bool isDark) =>
      isDark ? darkDisabledSurface : lightDisabledSurface;

  // Water-Glass Semantic Tokens (Organic Frosted Tint)
  static Color glassSurface(bool isDark) =>
      isDark ? const Color(0xE61B201B) : const Color(0xF2F6F3EB);
  static Color glassBorder(bool isDark) =>
      isDark ? const Color(0x33363D34) : const Color(0x80DED8C9);

  // States
  static Color voiceRecording(bool isDark) => error;
  static Color reminderCompleted(bool isDark) => success;

  static Color secondaryContainerColor(bool isDark) =>
      isDark ? darkSecondaryContainer : lightSecondaryContainer;

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return categoryWork;
      case 'health':
        return categoryHealth;
      case 'study':
        return categoryStudy;
      case 'personal':
        return categoryPersonal;
      case 'task':
        return categoryTask;
      default:
        return categoryWork;
    }
  }
}

/// Unified Midnight Botanical Gradient Tokens
class AppGradients {
  /// Light mode restrained champagne-to-sage gradient: #E5D4AF -> #B6C5A5
  static const LinearGradient lightSignature = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE5D4AF),
      Color(0xFFB6C5A5),
    ],
  );

  /// Dark mode signature 3-stop gradient: #E2D1AA -> #C9C49D -> #879B7D
  static const LinearGradient darkSignature = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE2D1AA),
      Color(0xFFC9C49D),
      Color(0xFF879B7D),
    ],
  );

  /// Dynamic signature gradient
  static LinearGradient signature(bool isDark) =>
      isDark ? darkSignature : lightSignature;

  /// Default alias
  static const LinearGradient premiumGoldSage = lightSignature;

  /// Primary Action Gradient
  /// Light Mode: #344735 -> #52664A (Deep botanical green)
  /// Dark Mode: #B9C8A9 -> #A9B59A (Muted interactive green)
  static LinearGradient primaryAction(bool isDark) {
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFB9C8A9),
          Color(0xFFA9B59A),
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF344735),
        Color(0xFF52664A),
      ],
    );
  }

  /// Subtle card tonal wash gradient
  static LinearGradient subtleCard(bool isDark) {
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1B201B),
          Color(0xFF272D26),
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFEEECE3),
      ],
    );
  }

  /// Radial illumination gradient for splash / bell illumination
  static RadialGradient splashRadial(bool isDark) {
    return RadialGradient(
      colors: [
        (isDark ? const Color(0xFFE2D1AA) : const Color(0xFFE5D4AF))
            .withValues(alpha: isDark ? 0.35 : 0.25),
        (isDark ? const Color(0xFF879B7D) : const Color(0xFFB6C5A5))
            .withValues(alpha: isDark ? 0.15 : 0.10),
        Colors.transparent,
      ],
      stops: const [0.0, 0.55, 1.0],
    );
  }
}
