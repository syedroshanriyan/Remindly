import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_feedback.dart';
import '../core/utils/id_generator.dart';
import '../models/diary_entry.dart';
import '../models/parsed_input.dart';
import '../models/reminder.dart';
import '../providers/diary_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/command_parser.dart';
import '../services/speech_service.dart';

class DiaryEditorScreen extends StatefulWidget {
  final DiaryEntry? entry;

  const DiaryEditorScreen({super.key, this.entry});

  @override
  State<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends State<DiaryEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<String> _tags;
  late List<String> _attachmentThumbnails;
  bool _isPinned = false;
  String _category = 'Notes';
  bool _isDictating = false;
  final SpeechService _speechService = SpeechService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController =
        TextEditingController(text: widget.entry?.content ?? '');
    _tags = List.from(widget.entry?.tags ?? []);
    _attachmentThumbnails = List.from(widget.entry?.attachments ?? []);
    _isPinned = widget.entry?.isPinned ?? false;
    _category = widget.entry?.category ?? 'Notes';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _speechService.cancelListening();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachmentThumbnails.add(result.files.single.path!);
        });
      }
    } catch (_) {}
  }

  String _dictationBaseText = '';

  void _toggleDictation() async {
    if (_isDictating) {
      await _speechService.stopListening();
      if (mounted) setState(() => _isDictating = false);
    } else {
      _dictationBaseText = _contentController.text.trim();
      setState(() => _isDictating = true);
      await _speechService.startListening(
        onResult: (transcript, isFinal) {
          final trimmed = transcript.trim();
          if (trimmed.isNotEmpty) {
            final newText = _dictationBaseText.isEmpty
                ? trimmed
                : '$_dictationBaseText $trimmed';
            _contentController.text = newText;
            _contentController.selection = TextSelection.collapsed(
              offset: newText.length,
            );
          }
          if (isFinal) {
            _dictationBaseText = _contentController.text.trim();
            if (mounted) setState(() => _isDictating = false);
          }
        },
        onDone: () {
          if (mounted) {
            _dictationBaseText = _contentController.text.trim();
            setState(() => _isDictating = false);
          }
        },
      );
    }
  }

  void _saveEntry() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      AppFeedback.showError(context, 'Please enter a title or content');
      return;
    }

    final combinedText = '$title $content'.trim();
    final parsed = CommandParser().parse(combinedText);

    // 1. Off-Topic Check (e.g. coding queries, general AI requests)
    if (parsed.intent == IntentType.offTopic) {
      _showOffTopicDialog(title, content);
      return;
    }

    // 2. Future Event Check: If diary has an event in the future, offer reminder creation
    if (parsed.intent == IntentType.futureEvent &&
        parsed.dueDate != null &&
        parsed.dueDate!.isAfter(DateTime.now())) {
      _showFutureEventDialog(title, content, parsed);
      return;
    }

    // Direct save
    _commitSaveDiary(title, content);
  }

  void _showOffTopicDialog(String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Non-Diary Content',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          "This doesn't appear to be a diary entry. Would you like to save it in your diary anyway?",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Discard & return
            },
            child:
                const Text('Discard', style: TextStyle(color: AppColors.error)),
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
              _commitSaveDiary(title, content);
            },
            child: const Text('Save as Diary'),
          ),
        ],
      ),
    );
  }

  void _showFutureEventDialog(
      String title, String content, ParsedInput parsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('d MMMM at h:mm a').format(parsed.dueDate!);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.event_available_rounded,
                color: AppColors.champagne(isDark)),
            const SizedBox(width: 8),
            const Text('Future Event Detected',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'I noticed this is a future event on $dateStr. Would you like to create a reminder?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _commitSaveDiary(title, content);
            },
            child: const Text('Not now'),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.alarm_add_rounded,
                size: 16,
                color: isDark ? AppColors.darkOnPrimary : Colors.white),
            label: Text('Create Reminder',
                style: TextStyle(
                    color: isDark ? AppColors.darkOnPrimary : Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(isDark),
              foregroundColor: isDark ? AppColors.darkOnPrimary : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // 1. Create reminder
              final reminder = Reminder(
                id: IdGenerator.newId(),
                title: parsed.title.isNotEmpty ? parsed.title : title,
                description: content,
                dueDate: parsed.dueDate!,
                recurrence: parsed.recurrence,
                sourceType: SourceType.text,
                sourceText: '$title $content',
                confidence: parsed.confidence,
                voiceEnabled: true,
              );
              context.read<ReminderProvider>().addReminder(reminder);

              // 2. Commit diary save
              _commitSaveDiary(title, content,
                  popResult: 'Reminder and diary saved');
            },
          ),
        ],
      ),
    );
  }

  void _commitSaveDiary(String title, String content, {String? popResult}) {
    final provider = context.read<DiaryProvider>();
    if (widget.entry != null) {
      final updated = widget.entry!.copyWith(
        title: title.isNotEmpty ? title : 'Untitled Note',
        content: content,
        tags: _tags,
        isPinned: _isPinned,
        category: _category,
        attachments: _attachmentThumbnails,
      );
      provider.updateEntry(updated);
    } else {
      final newEntry = DiaryEntry(
        id: IdGenerator.newId(),
        title: title.isNotEmpty ? title : 'New Note',
        content: content,
        tags: _tags,
        isPinned: _isPinned,
        category: _category,
        attachments: _attachmentThumbnails,
      );
      provider.addEntry(newEntry);
    }

    FocusScope.of(context).unfocus();
    Navigator.pop(context,
        popResult ?? (widget.entry != null ? 'Diary updated' : 'Diary saved'));
  }

  void _confirmDelete() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Note?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this diary entry? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.entry != null) {
                context.read<DiaryProvider>().deleteEntry(widget.entry!.id);
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

  void _showAddTagDialog() {
    final tagCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        title: const Text('Add Tag',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: tagCtrl,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'e.g. Project, Meeting, Study'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = tagCtrl.text.trim();
              if (val.isNotEmpty && !_tags.contains(val)) {
                setState(() => _tags.add(val));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ['Notes', 'Ideas', 'Work', 'Personal'];

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          widget.entry == null ? 'New Diary' : 'Edit Diary',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          if (widget.entry != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 24),
              tooltip: 'Delete Note',
              onPressed: _confirmDelete,
            ),
          IconButton(
            icon: Icon(
              _isPinned ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isPinned
                  ? AppColors.warning
                  : (isDark ? Colors.white70 : Colors.black54),
              size: 26,
            ),
            tooltip: 'Pin Note',
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          IconButton(
            icon: Icon(Icons.check_rounded,
                color: AppColors.primary(isDark), size: 26),
            tooltip: 'Save Note',
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Category Selector row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected =
                            _category.toLowerCase() == cat.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: AppColors.primary(isDark),
                            backgroundColor: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightSurfaceVariant,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _category = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Title input
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Title...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tags Row with Add Tag chip
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ..._tags.map((tag) => Chip(
                            label: Text(
                              '#$tag',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: AppColors.primary(isDark)
                                .withValues(alpha: 0.12),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _tags.remove(tag)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          )),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label:
                            const Text('Tag', style: TextStyle(fontSize: 12)),
                        onPressed: _showAddTagDialog,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Main Note Content
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 10,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    decoration: const InputDecoration(
                      hintText: 'Write your thoughts, ideas, plans...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Attachment thumbnails grid (real user attachments)
                  if (_attachmentThumbnails.isNotEmpty) ...[
                    Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _attachmentThumbnails.length,
                        itemBuilder: (ctx, idx) {
                          final path = _attachmentThumbnails[idx];
                          final isNetwork = path.startsWith('http');
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                  image: DecorationImage(
                                    image: isNetwork
                                        ? NetworkImage(path) as ImageProvider
                                        : FileImage(File(path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () => setState(() =>
                                      _attachmentThumbnails.removeAt(idx)),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black87,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Action Bar with perfectly equal gaps
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        tooltip: 'Take Photo',
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.image_outlined),
                        tooltip: 'Add Image',
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: _toggleDictation,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isDictating
                                ? AppColors.error
                                : AppColors.primary(isDark),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isDictating ? Icons.stop : Icons.mic,
                            color: _isDictating
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkOnPrimary
                                    : Colors.white),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.local_offer_outlined),
                        tooltip: 'Add Tag',
                        onPressed: _showAddTagDialog,
                      ),
                    ),
                  ),
                  if (widget.entry != null)
                    Expanded(
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.error),
                          tooltip: 'Delete Note',
                          onPressed: _confirmDelete,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.save_outlined),
                        tooltip: 'Save',
                        onPressed: _saveEntry,
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
}
