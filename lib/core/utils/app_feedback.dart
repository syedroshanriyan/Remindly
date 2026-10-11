import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../widgets/bottom_nav_scope.dart';

/// Unified feedback and notification system for Remindly.
///
/// Ensures all temporary feedback messages, snackbars, and toasts:
/// 1. Float comfortably ABOVE the persistent central microphone button.
/// 2. Respect device safe areas, bottom navigation, and software keyboards.
/// 3. Provide concise, premium visual feedback without covering interactive controls.
/// 4. Dismiss cleanly and automatically.
class AppFeedback {
  /// Displays a concise green success toast/banner.
  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration ?? const Duration(milliseconds: 2400),
    );
  }

  /// Displays an error toast/banner with rose crimson styling.
  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration ?? const Duration(milliseconds: 3200),
    );
  }

  /// Displays a neutral/informative toast/banner.
  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.primary(isDark),
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration ?? const Duration(milliseconds: 2400),
    );
  }

  /// Displays an announcement toast/banner specifically for voice and audio actions.
  static void showAnnouncement(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    show(
      context,
      message: message,
      icon: Icons.volume_up_rounded,
      iconColor: AppColors.champagne(isDark),
      duration: duration ?? const Duration(milliseconds: 2500),
    );
  }

  /// Core display implementation with automatic safe clearance above bottom controls.
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomMargin = BottomNavScope.bottomClearance(context);
    final accentColor = iconColor ?? AppColors.primary(isDark);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        margin: EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: bottomMargin,
        ),
        padding: EdgeInsets.zero,
        duration: duration ?? const Duration(milliseconds: 2400),
        dismissDirection: DismissDirection.horizontal,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? accentColor.withValues(alpha: 0.35)
                  : accentColor.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.32),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(icon, size: 16, color: accentColor),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.champagne(isDark),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
