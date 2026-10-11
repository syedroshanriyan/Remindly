import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/diary_entry.dart';
import '../models/reminder.dart';
import '../providers/diary_provider.dart';
import '../providers/reminder_provider.dart';
import 'add_edit_reminder_screen.dart';
import 'diary_editor_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Diary', 'Reminders', 'Tasks'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminderProvider = context.watch<ReminderProvider>();
    final diaryProvider = context.watch<DiaryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = _query.trim().toLowerCase();

    // Extract dynamic tags from actual user entries (zero dummy data)
    final dynamicTags = <String>{};
    for (final e in diaryProvider.entries) {
      for (final t in e.tags) {
        if (t.trim().isNotEmpty) dynamicTags.add(t.trim().toLowerCase());
      }
    }
    for (final r in reminderProvider.reminders) {
      if (r.category.trim().isNotEmpty) {
        dynamicTags.add(r.category.trim().toLowerCase());
      }
    }
    final recentTags = dynamicTags.take(6).toList();

    final reminders = reminderProvider.activeReminders.where((r) {
      if (q.isEmpty) return true;
      return r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q);
    }).toList();

    final diaries = diaryProvider.searchEntries(q);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title:
            const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: AppColors.primary(isDark)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Search notes, reminders, tags...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (val) => setState(() => _query = val),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Filter Chips (All, Diary, Reminders, Tasks)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _selectedFilter == f;
                  final onPrimary =
                      isDark ? AppColors.darkOnPrimary : Colors.white;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      selectedColor: AppColors.primary(isDark),
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? onPrimary
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = f);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Recent Searches / Quick Tags (Only shown when real tags exist)
            if (recentTags.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const Text(
                      'Tags: ',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkTextSecondary),
                    ),
                    ...recentTags.map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text('#$tag',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            backgroundColor: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onPressed: () {
                              _searchController.text = tag;
                              setState(() => _query = tag);
                            },
                          ),
                        )),
                  ],
                ),
              ),

            const Divider(height: 16),

            // Search Results List
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  if (_selectedFilter == 'All' ||
                      _selectedFilter == 'Reminders' ||
                      _selectedFilter == 'Tasks') ...[
                    if (reminders.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Reminders (${reminders.length})',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.champagne(isDark)),
                        ),
                      ),
                      ...reminders.map((r) => _buildReminderResult(r, isDark)),
                    ],
                  ],
                  if (_selectedFilter == 'All' ||
                      _selectedFilter == 'Diary') ...[
                    if (diaries.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Diary Entries (${diaries.length})',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary(isDark)),
                        ),
                      ),
                      ...diaries.map((d) => _buildDiaryResult(d, isDark)),
                    ],
                  ],
                  if (reminders.isEmpty && diaries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No results found.\nTry searching with different terms.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: AppColors.textSecondary(isDark)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderResult(Reminder r, bool isDark) {
    final timeStr = DateFormat('MMM dd, yyyy • hh:mm a').format(r.dueDate);
    final catColor = AppColors.getCategoryColor(r.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: ListTile(
        leading: Icon(Icons.alarm_rounded, color: catColor),
        title: Text(r.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5)),
        subtitle: Text(timeStr,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary(isDark))),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8)),
          child: Text(r.category,
              style: TextStyle(
                  fontSize: 12, color: catColor, fontWeight: FontWeight.bold)),
        ),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddEditReminderScreen(reminder: r)));
        },
      ),
    );
  }

  Widget _buildDiaryResult(DiaryEntry d, bool isDark) {
    final dateStr = DateFormat('MMM dd, yyyy').format(d.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: ListTile(
        leading:
            Icon(Icons.auto_stories_rounded, color: AppColors.primary(isDark)),
        title: Text(d.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5)),
        subtitle: Text(
          d.content.isNotEmpty ? d.content : dateStr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark)),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 12, color: AppColors.textSecondary(isDark)),
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => DiaryEditorScreen(entry: d)));
        },
      ),
    );
  }
}
