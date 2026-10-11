import 'dart:math';
import 'package:flutter/material.dart';

/// InheritedWidget that provides the ambient layout context of the main
/// navigation bar and the center-docked floating microphone button.
///
/// Any screen inside the [MainNavigationScreen] tabs can look up this scope
/// to accurately position temporary notifications, snackbars, and toasts
/// safely ABOVE the microphone and bottom navigation bar without hardcoding.
class BottomNavScope extends InheritedWidget {
  final bool hasBottomNav;
  final double bottomBarHeight;
  final double fabClearance;

  const BottomNavScope({
    super.key,
    this.hasBottomNav = true,
    this.bottomBarHeight = 62.0,
    this.fabClearance =
        36.0, // 32px (half of 64px FAB) + 4px snug clearance above microphone
    required super.child,
  });

  static BottomNavScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BottomNavScope>();
  }

  static bool hasBottomNavOf(BuildContext context) {
    return maybeOf(context)?.hasBottomNav ?? false;
  }

  /// Calculates the exact safe bottom margin (in logical pixels) for floating
  /// notifications and feedback cards so they rest snugly right above the
  /// microphone button without awkward empty gaps or overlap.
  static double bottomClearance(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safeBottom = mediaQuery.padding.bottom;
    final keyboardBottom = mediaQuery.viewInsets.bottom;

    // If keyboard is open, float safely above keyboard
    if (keyboardBottom > 0) {
      return keyboardBottom + 12.0;
    }

    final scope = maybeOf(context);
    if (scope != null && scope.hasBottomNav) {
      // Safe bottom inset + bottom navigation bar (62) + snug FAB clearance (36)
      // Equals: safeBottom + 62 + 36 = safeBottom + 98.0
      return safeBottom + scope.bottomBarHeight + scope.fabClearance;
    }

    // Standard floating margin for screens without bottom navigation bar
    return max(safeBottom, 12.0) + 12.0;
  }

  @override
  bool updateShouldNotify(BottomNavScope oldWidget) {
    return hasBottomNav != oldWidget.hasBottomNav ||
        bottomBarHeight != oldWidget.bottomBarHeight ||
        fabClearance != oldWidget.fabClearance;
  }
}
