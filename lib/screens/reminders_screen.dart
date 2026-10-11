import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_feedback.dart';
import '../models/reminder.dart';
import '../providers/reminder_provider.dart';
import 'add_edit_reminder_screen.dart';
import 'archive_screen.dart';
import 'search_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Today tab is always opened by default (index 1)
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminderProvider = context.watch<ReminderProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
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
            tooltip: 'Add Reminder',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddEditReminderScreen()),
              );
              if (result != null && context.mounted) {
                AppFeedback.showSuccess(context, result as String);
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppColors.primary(isDark),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: isDark ? AppColors.darkOnPrimary : Colors.white,
              unselectedLabelColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Completed'),
                Tab(text: 'Today'),
                Tab(text: 'Upcoming'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Index 0: Completed (swiping right from Today reveals Completed)
          _buildReminderList(
              reminderProvider.completedReminders, isDark, reminderProvider,
              emptyMessage: 'No completed reminders yet'),
          // Index 1: Today (default opened tab)
          _buildReminderList(
              reminderProvider.todayReminders, isDark, reminderProvider,
              emptyMessage: 'No reminders due today'),
          // Index 2: Upcoming (swiping left from Today reveals Upcoming)
          _buildReminderList(
              reminderProvider.upcomingReminders, isDark, reminderProvider,
              emptyMessage: 'No upcoming reminders'),
        ],
      ),
    );
  }

  Widget _buildReminderList(
    List<Reminder> list,
    bool isDark,
    ReminderProvider provider, {
    required String emptyMessage,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.alarm_on_rounded,
                    size: 32, color: AppColors.warning),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Schedule tasks, alarms, and deadlines with custom voice alerts.',
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
                  foregroundColor:
                      isDark ? AppColors.darkOnPrimary : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddEditReminderScreen()),
                  );
                  if (result != null && mounted) {
                    AppFeedback.showSuccess(context, result as String);
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Reminder'),
              ),
            ],
          ),
        ),
      );
    }

    // Split into Upcoming (due within 24h) and Later
    final now = DateTime.now();
    final upcoming =
        list.where((r) => r.dueDate.difference(now).inHours <= 24).toList();
    final later =
        list.where((r) => r.dueDate.difference(now).inHours > 24).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (upcoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'Upcoming',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary(isDark),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...upcoming.map((r) => _buildReminderCard(r, isDark, provider)),
        ],
        if (later.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Text(
              'Later',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary(isDark),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...later.map((r) => _buildReminderCard(r, isDark, provider)),
        ],
        if (upcoming.isEmpty && later.isEmpty)
          ...list.map((r) => _buildReminderCard(r, isDark, provider)),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildReminderCard(
      Reminder reminder, bool isDark, ReminderProvider provider) {
    final catColor = AppColors.getCategoryColor(reminder.category);
    final dateStr =
        DateFormat('MMM dd, yyyy • hh:mm a').format(reminder.dueDate);

    return Dismissible(
      key: Key(reminder.id),
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
                Text('Delete Reminder?',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content:
                Text('Are you sure you want to delete "${reminder.title}"?'),
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
        provider.deleteReminder(reminder.id);
        AppFeedback.show(
          context,
          message: 'Deleted "${reminder.title}"',
          actionLabel: 'Undo',
          onAction: () => provider.addReminder(reminder),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: reminder.isCompleted
                  ? Colors.transparent
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            leading: GestureDetector(
              onTap: () {
                final wasCompleted = reminder.isCompleted;
                provider.toggleReminder(reminder.id);
                AppFeedback.showSuccess(
                  context,
                  wasCompleted ? 'Marked incomplete' : 'Completed',
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: reminder.isCompleted
                      ? AppColors.success
                      : catColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: reminder.isCompleted ? AppColors.success : catColor,
                    width: 2,
                  ),
                ),
                child: reminder.isCompleted
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
            title: Text(
              reminder.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                decoration:
                    reminder.isCompleted ? TextDecoration.lineThrough : null,
                color: reminder.isCompleted
                    ? (isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary)
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        dateStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (reminder.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reminder.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    reminder.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: catColor,
                    ),
                  ),
                ),
                // Mute / Unmute Upcoming Announcement Toggle
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    reminder.muted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    size: 19,
                    color: reminder.muted
                        ? AppColors.warning
                        : AppColors.champagne(isDark),
                  ),
                  tooltip: reminder.muted
                      ? 'Announcement Muted (Tap to unmute)'
                      : 'Mute Voice Announcement',
                  onPressed: () {
                    provider.toggleMute(reminder.id);
                    AppFeedback.showInfo(
                      context,
                      !reminder.muted
                          ? 'Voice announcement active'
                          : 'Voice announcement silenced',
                    );
                  },
                ),
                // Overflow popup menu with Archive, Delete, Edit
                PopupMenuButton<String>(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 19,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
                  onSelected: (val) async {
                    if (val == 'archive') {
                      provider.archiveReminder(reminder.id);
                      AppFeedback.showSuccess(context, 'Moved to archive');
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
                              Text('Delete Reminder?',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          content: Text(
                              'Are you sure you want to delete "${reminder.title}"?'),
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
                                provider.deleteReminder(reminder.id);
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
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Archive'),
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
                          Text('Delete',
                              style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditReminderScreen(reminder: reminder),
                ),
              );
              if (result != null && mounted) {
                AppFeedback.showSuccess(context, result as String);
              }
            },
          ),
        ),
      ),
    );
  }
}
