import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/design_tokens.dart';
import '../core/utils/date_time_utils.dart';
import '../models/diary_entry.dart';

class DiaryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const DiaryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onEdit,
    this.onArchive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical: DesignTokens.space8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: DesignTokens.borderRadiusCard,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: DesignTokens.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: DesignTokens.borderRadiusCard,
        child: InkWell(
          borderRadius: DesignTokens.borderRadiusCard,
          onTap: onTap ?? onEdit,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book_outlined,
                            size: 16, color: AppColors.champagne(isDark)),
                        const SizedBox(width: 6),
                        Text(
                          DateTimeUtils.formatDate(entry.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.champagne(isDark),
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      onSelected: (val) {
                        if (val == 'edit') onEdit?.call();
                        if (val == 'archive') onArchive?.call();
                        if (val == 'delete') onDelete?.call();
                      },
                      itemBuilder: (context) => [
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
                        PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              const Icon(Icons.archive_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(entry.isArchived ? 'Restore' : 'Archive'),
                            ],
                          ),
                        ),
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
                const SizedBox(height: DesignTokens.space8),
                Text(
                  entry.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  entry.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space12),
                  Wrap(
                    spacing: DesignTokens.space8,
                    runSpacing: DesignTokens.space4,
                    children: entry.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainerColor(isDark),
                          borderRadius: DesignTokens.borderRadiusSmall,
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.champagne(isDark),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
