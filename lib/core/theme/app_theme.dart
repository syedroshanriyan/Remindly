import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        primaryContainer: AppColors.lightPrimaryContainer,
        onPrimaryContainer: AppColors.lightOnPrimaryContainer,
        secondary: AppColors.lightChampagne,
        surface: AppColors.lightSurface,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        outline: AppColors.lightBorder,
        error: AppColors.error,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: AppColors.lightTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.5,
          color: AppColors.lightTextPrimary,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.5,
          color: AppColors.lightTextSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          color: AppColors.lightTextMuted,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusCard,
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space8,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space12,
        ),
        border: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 14.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space20,
            vertical: DesignTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMedium,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          side: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space20,
            vertical: DesignTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMedium,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.lightPrimaryContainer,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 13,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.normal,
            color: states.contains(WidgetState.selected)
                ? AppColors.lightPrimary
                : AppColors.lightTextSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.lightPrimary
                : AppColors.lightTextSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.lightSurface,
        contentTextStyle: const TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
        ),
        elevation: 6,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimaryContainer: AppColors.darkOnPrimaryContainer,
        secondary: AppColors.darkChampagne,
        surface: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        outline: AppColors.darkBorder,
        error: AppColors.error,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.5,
          color: AppColors.darkTextPrimary,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.5,
          color: AppColors.darkTextSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          color: AppColors.darkTextMuted,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusCard,
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space8,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space12,
        ),
        border: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space20,
            vertical: DesignTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMedium,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space20,
            vertical: DesignTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMedium,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.darkPrimaryContainer,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 13,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.normal,
            color: states.contains(WidgetState.selected)
                ? AppColors.darkPrimary
                : AppColors.darkTextSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.darkPrimary
                : AppColors.darkTextSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.2),
        ),
        elevation: 6,
      ),
    );
  }
}
