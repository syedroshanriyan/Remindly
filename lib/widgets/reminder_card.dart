import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/design_tokens.dart';
import '../core/utils/date_time_utils.dart';
import '../models/recurrence_rule.dart';
import '../models/reminder.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSnooze;
  final VoidCallback? onToggleMute;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onComplete,
    this.onEdit,
    this.onDelete,
    this.onSnooze,
    this.onToggleMute,
    this.onArchive,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPast =
        DateTimeUtils.isPast(reminder.dueDate) && !reminder.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical: DesignTokens.space8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: DesignTokens.borderRadiusCard,
        border: Border.all(
          color: isPast
              ? AppColors.error.withValues(alpha: 0.35)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1,
        ),
        boxShadow: DesignTokens.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: DesignTokens.borderRadiusCard,
        child: InkWell(
          borderRadius: DesignTokens.borderRadiusCard,
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Completion checkbox
                    GestureDetector(
                      key: const Key('reminder_complete_btn'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onComplete,
                      child: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(
                            top: 2, right: DesignTokens.space12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: reminder.isCompleted
                              ? AppColors.success
                              : Colors.transparent,
                          border: Border.all(
                            color: reminder.isCompleted
                                ? AppColors.success
                                : (isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary),
                            width: 2,
                          ),
                        ),
                        child: reminder.isCompleted
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: reminder.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: reminder.isCompleted
                                  ? (isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary)
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                            ),
                          ),
                          if (reminder.description.isNotEmpty) ...[
                            const SizedBox(height: DesignTokens.space4),
                            Text(
                              reminder.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Quick Action Menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'restore':
                            onRestore?.call();
                            break;
                          case 'archive':
                            onArchive?.call();
                            break;
                          case 'snooze':
                            onSnooze?.call();
                            break;
                          case 'mute':
                            onToggleMute?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (reminder.isArchived) ...[
                          if (onRestore != null)
                            const PopupMenuItem(
                              value: 'restore',
                              child: Row(
                                children: [
                                  Icon(Icons.unarchive_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Restore'),
                                ],
                              ),
                            ),
                        ] else ...[
                          if (onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          if (!reminder.isCompleted) ...[
                            if (onSnooze != null)
                              const PopupMenuItem(
                                value: 'snooze',
                                child: Row(
                                  children: [
                                    Icon(Icons.snooze,
                                        size: 18, color: AppColors.warning),
                                    SizedBox(width: 8),
                                    Text('Snooze 10m'),
                                  ],
                                ),
                              ),
                            if (onToggleMute != null)
                              PopupMenuItem(
                                value: 'mute',
                                child: Row(
                                  children: [
                                    Icon(
                                      reminder.muted
                                          ? Icons.volume_up
                                          : Icons.volume_off,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(reminder.muted
                                        ? 'Unmute voice'
                                        : 'Mute voice'),
                                  ],
                                ),
                              ),
                          ],
                          if (onArchive != null)
                            const PopupMenuItem(
                              value: 'archive',
                              child: Row(
                                children: [
                                  Icon(Icons.archive_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Archive'),
                                ],
                              ),
                            ),
                        ],
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.error),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space12),
                // Footer: Date/time badge, Recurrence tag, Mute status
                Wrap(
                  spacing: DesignTokens.space8,
                  runSpacing: DesignTokens.space4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPast
                            ? AppColors.error.withValues(alpha: 0.12)
                            : (isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightPrimaryContainer),
                        borderRadius: DesignTokens.borderRadiusSmall,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: isPast
                                ? AppColors.error
                                : AppColors.primary(isDark),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            DateTimeUtils.formatDateTime(reminder.dueDate),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isPast
                                  ? AppColors.error
                                  : AppColors.primary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (reminder.recurrence != RecurrenceType.none)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainerColor(isDark),
                          borderRadius: DesignTokens.borderRadiusSmall,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.repeat,
                                size: 14, color: AppColors.lightSecondary),
                            const SizedBox(width: 5),
                            Text(
                              reminder.recurrence.displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.lightSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (reminder.muted)
                      const Icon(Icons.volume_off,
                          size: 15, color: AppColors.warning),
                    if (reminder.snoozeCount > 0)
                      Text(
                        'Snoozed (${reminder.snoozeCount}x)',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.warning, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
