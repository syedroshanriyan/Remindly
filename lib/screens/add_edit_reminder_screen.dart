import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_feedback.dart';
import '../core/utils/id_generator.dart';
import '../models/recurrence_rule.dart';
import '../models/reminder.dart';
import '../providers/reminder_provider.dart';
import '../services/tts_service.dart';

class AddEditReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const AddEditReminderScreen({super.key, this.reminder});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  RecurrenceType recurrence = RecurrenceType.none;
  String category = 'Study';
  String remindBefore = '15 minutes before';
  bool voiceEnabled = true;
  bool notificationEnabled = true;

  static const List<String> remindBeforeOptions = [
    'At time of event',
    '5 minutes before',
    '10 minutes before',
    '15 minutes before',
    '30 minutes before',
    '1 hour before',
    '1 day before',
  ];

  static int minutesFromOption(String option) {
    switch (option) {
      case 'At time of event':
        return 0;
      case '5 minutes before':
        return 5;
      case '10 minutes before':
        return 10;
      case '15 minutes before':
        return 15;
      case '30 minutes before':
        return 30;
      case '1 hour before':
        return 60;
      case '1 day before':
        return 1440;
      default:
        return 15;
    }
  }

  static String optionFromMinutes(int minutes) {
    switch (minutes) {
      case 0:
        return 'At time of event';
      case 5:
        return '5 minutes before';
      case 10:
        return '10 minutes before';
      case 15:
        return '15 minutes before';
      case 30:
        return '30 minutes before';
      case 60:
        return '1 hour before';
      case 1440:
        return '1 day before';
      default:
        return '15 minutes before';
    }
  }

  bool get isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final rem = widget.reminder;
    titleController = TextEditingController(text: rem?.title ?? '');
    descriptionController = TextEditingController(text: rem?.description ?? '');

    if (rem != null) {
      selectedDate = rem.dueDate;
      selectedTime =
          TimeOfDay(hour: rem.dueDate.hour, minute: rem.dueDate.minute);
      recurrence = rem.recurrence;
      voiceEnabled = rem.voiceEnabled;
      notificationEnabled = rem.notificationEnabled;
      category = rem.category;
      remindBefore = optionFromMinutes(rem.remindBeforeMinutes);
    } else {
      selectedDate = DateTime.now();
      selectedTime =
          TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
      remindBefore = '15 minutes before';
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  void _testVoiceAlert() {
    final title = titleController.text.trim();
    final testText = title.isNotEmpty ? title : 'Medicine';
    final notes = descriptionController.text.trim();
    final spokenText = TTSService.formatAnnouncement(testText,
        notes: notes.isNotEmpty ? notes : null);
    TTSService()
        .announceReminder(testText, notes: notes.isNotEmpty ? notes : null);
    AppFeedback.showAnnouncement(context, 'Speaking: "$spokenText"');
  }

  void saveReminder({bool allowPast = false}) {
    final title = titleController.text.trim();
    if (title.isEmpty || selectedDate == null || selectedTime == null) {
      AppFeedback.showError(context, 'Please provide a title, date, and time.');
      return;
    }

    final dueDate = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (!allowPast &&
        recurrence == RecurrenceType.none &&
        dueDate.isBefore(DateTime.now())) {
      _showPastTimeDialog(dueDate);
      return;
    }

    final provider = context.read<ReminderProvider>();
    final priorMinutes = minutesFromOption(remindBefore);

    if (isEditing) {
      provider.updateReminder(
        widget.reminder!.copyWith(
          title: title,
          description: descriptionController.text.trim(),
          dueDate: dueDate,
          recurrence: recurrence,
          voiceEnabled: voiceEnabled,
          notificationEnabled: notificationEnabled,
          category: category,
          remindBeforeMinutes: priorMinutes,
        ),
      );
    } else {
      provider.addReminder(
        Reminder(
          id: IdGenerator.newId(),
          title: title,
          description: descriptionController.text.trim(),
          dueDate: dueDate,
          recurrence: recurrence,
          voiceEnabled: voiceEnabled,
          notificationEnabled: notificationEnabled,
          category: category,
          sourceType: SourceType.manual,
          remindBeforeMinutes: priorMinutes,
        ),
      );
    }

    FocusScope.of(context).unfocus();
    Navigator.pop(context, isEditing ? 'Reminder updated' : 'Reminder created');
  }

  void _showPastTimeDialog(DateTime dueDate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('MMM d, h:mm a').format(dueDate);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.history_toggle_off_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Time Already Passed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'The scheduled time ($timeStr) is in the past. Would you like to schedule this for tomorrow instead?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              saveReminder(allowPast: true);
            },
            child: const Text('Save Anyway'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              pickTime();
            },
            child: const Text('Change Time'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(isDark),
              foregroundColor: isDark ? AppColors.darkOnPrimary : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                selectedDate = (selectedDate ?? DateTime.now())
                    .add(const Duration(days: 1));
              });
              saveReminder();
            },
            child: const Text('Set for Tomorrow'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Reminder?',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
            'Are you sure you want to delete this reminder? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.reminder != null) {
                context
                    .read<ReminderProvider>()
                    .deleteReminder(widget.reminder!.id);
                FocusScope.of(context).unfocus();
                Navigator.pop(context, 'Deleted');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateLabel = selectedDate != null
        ? DateFormat('MMMM dd, yyyy').format(selectedDate!)
        : 'Select Date';
    final timeLabel =
        selectedTime != null ? selectedTime!.format(context) : 'Select Time';

    final categories = ['Study', 'Work', 'Health', 'Personal'];

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Reminder' : 'Add Reminder',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 24),
              tooltip: 'Delete Reminder',
              onPressed: _confirmDelete,
            ),
          IconButton(
            icon: Icon(Icons.check_rounded,
                color: AppColors.primary(isDark), size: 28),
            tooltip: 'Save',
            onPressed: saveReminder,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Title
            const Text(
              'Title',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 6),
            _buildContainer(
              isDark,
              child: TextField(
                controller: titleController,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'e.g. Submit college assignment',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 6),
            _buildContainer(
              isDark,
              child: TextField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText:
                      'Complete and upload the final ML project report before deadline...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date Picker Row
            const Text(
              'Date',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: pickDate,
              borderRadius: BorderRadius.circular(14),
              child: _buildContainer(
                isDark,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateLabel,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    Icon(Icons.calendar_today_rounded,
                        size: 20, color: AppColors.primary(isDark)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Time Picker Row
            const Text(
              'Time',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: pickTime,
              borderRadius: BorderRadius.circular(14),
              child: _buildContainer(
                isDark,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(timeLabel,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    Icon(Icons.access_time_rounded,
                        size: 20, color: AppColors.champagne(isDark)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Repeat Dropdown
            const Text(
              'Repeat',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 6),
            _buildContainer(
              isDark,
              child: DropdownButton<RecurrenceType>(
                value: recurrence,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor:
                    isDark ? AppColors.darkSurfaceVariant : Colors.white,
                items: const [
                  DropdownMenuItem(
                      value: RecurrenceType.none,
                      child: Text('Does not repeat')),
                  DropdownMenuItem(
                      value: RecurrenceType.daily, child: Text('Daily')),
                  DropdownMenuItem(
                      value: RecurrenceType.weekly, child: Text('Weekly')),
                  DropdownMenuItem(
                      value: RecurrenceType.monthly, child: Text('Monthly')),
                  DropdownMenuItem(
                      value: RecurrenceType.weekdays,
                      child: Text('Weekdays (Mon-Fri)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => recurrence = val);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Remind Before Dropdown
            const Text(
              'Remind',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 6),
            _buildContainer(
              isDark,
              child: DropdownButton<String>(
                value: remindBeforeOptions.contains(remindBefore)
                    ? remindBefore
                    : '15 minutes before',
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor:
                    isDark ? AppColors.darkSurfaceVariant : Colors.white,
                items: remindBeforeOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => remindBefore = val);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Category Chips Selector
            const Text(
              'Category',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: categories.map((cat) {
                final isSelected = category.toLowerCase() == cat.toLowerCase();
                final catColor = AppColors.getCategoryColor(cat);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: catColor,
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => category = cat);
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Voice Reminder Alert Toggle Switch (Miro requirement!)
            _buildContainer(
              isDark,
              child: Row(
                children: [
                  Icon(Icons.record_voice_over_rounded,
                      color: AppColors.primary(isDark)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Voice reminder alert',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14.5)),
                        Text('Speaks reminder aloud when due',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary(isDark))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: voiceEnabled,
                    activeThumbColor: AppColors.primary(isDark),
                    onChanged: (val) => setState(() => voiceEnabled = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Test Voice Alert Button (Instant Verification!)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.champagne(isDark),
                side: BorderSide(color: AppColors.champagne(isDark)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _testVoiceAlert,
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Test Voice Alert (Speak Aloud)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContainer(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: child,
    );
  }
}
