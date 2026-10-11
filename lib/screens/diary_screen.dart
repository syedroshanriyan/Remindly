import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_feedback.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import 'archive_screen.dart';
import 'diary_editor_screen.dart';
import 'search_screen.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final diaryProvider = context.watch<DiaryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = ['All', 'Notes', 'Ideas', 'Work', 'Personal'];
    final pinned = diaryProvider.pinnedEntries;
    final unpinned = diaryProvider.unpinnedEntries;

    // Split unpinned into Today and Earlier
    final now = DateTime.now();
    final today = unpinned
        .where((e) =>
            e.createdAt.year == now.year &&
            e.createdAt.month == now.month &&
            e.createdAt.day == now.day)
        .toList();
    final earlier = unpinned.where((e) => !today.contains(e)).toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Diary',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search Notes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archive',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArchiveScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Note',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiaryEditorScreen()),
              );
              if (result != null && context.mounted) {
                AppFeedback.showSuccess(context, result as String);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter Chips matching Miro
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: categories.map((cat) {
                  final isSelected =
                      diaryProvider.selectedCategory.toLowerCase() ==
                          cat.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.primary(isDark),
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                      onSelected: (val) {
                        if (val) diaryProvider.setSelectedCategory(cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 6),

            // Entries List
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  // Pinned Section (if any)
                  if (pinned.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.push_pin_rounded,
                              size: 16, color: AppColors.warning),
                          SizedBox(width: 6),
                          Text(
                            'Pinned',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkTextSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...pinned.map((e) =>
                        _buildDiaryCard(context, e, isDark, diaryProvider)),
                  ],

                  // Today Section
                  if (today.isNotEmpty) ...[
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...today.map((e) =>
                        _buildDiaryCard(context, e, isDark, diaryProvider)),
                  ],

                  // Earlier / Yesterday Section
                  if (earlier.isNotEmpty) ...[
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Text(
                        'Earlier',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...earlier.map((e) =>
                        _buildDiaryCard(context, e, isDark, diaryProvider)),
                  ],

                  if (pinned.isEmpty && today.isEmpty && earlier.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 48),
                      margin: const EdgeInsets.only(top: 24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primary(isDark)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.auto_stories_rounded,
                                size: 30, color: AppColors.primary(isDark)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Diary Entries Yet',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Write down your thoughts, daily memories, or reflections.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary(isDark),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DiaryEditorScreen()),
                              );
                              if (result != null && context.mounted) {
                                AppFeedback.showSuccess(
                                    context, result as String);
                              }
                            },
                            icon: const Icon(Icons.edit_note_rounded, size: 18),
                            label: const Text('Write First Entry'),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryCard(
    BuildContext context,
    DiaryEntry entry,
    bool isDark,
    DiaryProvider provider,
  ) {
    final timeStr =
        DateFormat('MMM dd, yyyy • hh:mm a').format(entry.createdAt);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_forever_rounded,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.delete_outline_rounded, color: AppColors.error),
                SizedBox(width: 8),
                Text('Delete Note?',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text('Are you sure you want to delete "${entry.title}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        provider.deleteEntry(entry.id);
        AppFeedback.show(
          context,
          message: 'Deleted "${entry.title}"',
          actionLabel: 'Undo',
          onAction: () => provider.addEntry(entry),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: entry.isPinned
                  ? AppColors.champagne(isDark).withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary(isDark).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_stories_rounded,
                  color: AppColors.primary(isDark), size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (entry.isPinned)
                  const Icon(Icons.star_rounded,
                      color: AppColors.warning, size: 18),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
                if (entry.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.content,
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
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: entry.tags
                        .take(3)
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary(isDark)
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#$t',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.primary(isDark),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
              onSelected: (val) async {
                if (val == 'pin') {
                  provider.togglePin(entry.id);
                } else if (val == 'archive') {
                  if (entry.isArchived) {
                    provider.restoreEntry(entry.id);
                    AppFeedback.showSuccess(context, 'Restored');
                  } else {
                    provider.archiveEntry(entry.id);
                    AppFeedback.showSuccess(context, 'Moved to archive');
                  }
                } else if (val == 'edit') {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DiaryEditorScreen(entry: entry)),
                  );
                  if (result != null && context.mounted) {
                    AppFeedback.showSuccess(context, result as String);
                  }
                } else if (val == 'delete') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete Note?',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      content: Text(
                          'Are you sure you want to delete "${entry.title}"?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            provider.deleteEntry(entry.id);
                            AppFeedback.showSuccess(context, 'Deleted');
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (ctx) => [
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
                  value: 'pin',
                  child: Row(
                    children: [
                      Icon(
                          entry.isPinned
                              ? Icons.star_outline_rounded
                              : Icons.star_rounded,
                          size: 18,
                          color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text(entry.isPinned ? 'Unpin' : 'Pin to Top'),
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
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiaryEditorScreen(entry: entry),
                ),
              );
              if (result != null && context.mounted) {
                AppFeedback.showSuccess(context, result as String);
              }
            },
          ),
        ),
      ),
    );
  }
}
