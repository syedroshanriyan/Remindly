import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/design_tokens.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.calendar_today_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary(isDark)
                    .withValues(alpha: isDark ? 0.12 : 0.08),
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.primary(isDark),
              ),
            ),
            const SizedBox(height: DesignTokens.space16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DesignTokens.space8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.space24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
