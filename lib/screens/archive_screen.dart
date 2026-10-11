import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/app_feedback.dart';
import '../providers/diary_provider.dart';
import '../providers/reminder_provider.dart';
import '../widgets/diary_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/reminder_card.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminderProvider = context.watch<ReminderProvider>();
    final diaryProvider = context.watch<DiaryProvider>();
    final archivedReminders = reminderProvider.archivedReminders;
    final archivedDiaries = diaryProvider.archivedEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Reminders (${archivedReminders.length})'),
            Tab(text: 'Diary (${archivedDiaries.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Archived Reminders Tab
          archivedReminders.isEmpty
              ? const EmptyState(
                  icon: Icons.archive_outlined,
                  message: 'No archived reminders',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: archivedReminders.length,
                  itemBuilder: (context, index) {
                    final reminder = archivedReminders[index];
                    return ReminderCard(
                      reminder: reminder,
                      onRestore: () {
                        reminderProvider.restoreReminder(reminder.id);
                        AppFeedback.showSuccess(context, 'Restored');
                      },
                      onDelete: () {
                        reminderProvider.deleteReminder(reminder.id);
                        AppFeedback.showSuccess(context, 'Deleted');
                      },
                    );
                  },
                ),

          // Archived Diaries Tab
          archivedDiaries.isEmpty
              ? const EmptyState(
                  icon: Icons.auto_stories_outlined,
                  message: 'No archived diary entries',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: archivedDiaries.length,
                  itemBuilder: (context, index) {
                    final entry = archivedDiaries[index];
                    return DiaryCard(
                      entry: entry,
                      onArchive: () {
                        diaryProvider.restoreEntry(entry.id);
                        AppFeedback.showSuccess(context, 'Restored');
                      },
                      onDelete: () {
                        diaryProvider.deleteEntry(entry.id);
                        AppFeedback.showSuccess(context, 'Deleted');
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
