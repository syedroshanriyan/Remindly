import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_feedback.dart';
import '../core/utils/id_generator.dart';
import '../models/diary_entry.dart';
import '../models/parsed_input.dart';
import '../models/reminder.dart';
import '../providers/diary_provider.dart';
import '../providers/input_provider.dart';
import '../providers/reminder_provider.dart';
import '../widgets/command_preview.dart';
import 'add_edit_reminder_screen.dart';
import 'diary_editor_screen.dart';

class VoiceScreen extends StatefulWidget {
  final VoiceMode initialMode;

  const VoiceScreen({super.key, this.initialMode = VoiceMode.general});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _transcriptEditController =
      TextEditingController();
  bool _isEditingTranscript = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InputProvider>().setVoiceMode(widget.initialMode);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transcriptEditController.dispose();
    super.dispose();
  }

  void _toggleListening(InputProvider inputProvider) {
    if (inputProvider.isListening) {
      inputProvider.stopVoiceListening(
        reminderProvider: context.read<ReminderProvider>(),
        diaryProvider: context.read<DiaryProvider>(),
        autoSaveOnFinish: false,
      );
    } else {
      setState(() => _isEditingTranscript = false);
      inputProvider.startVoiceListening(
        reminderProvider: context.read<ReminderProvider>(),
        diaryProvider: context.read<DiaryProvider>(),
        autoSaveOnFinish: false,
      );
    }
  }

  void _editAndReparse(InputProvider provider) {
    setState(() {
      _isEditingTranscript = true;
      _transcriptEditController.text = provider.currentInput;
    });
  }

  void _submitEditedTranscript(InputProvider provider) {
    final text = _transcriptEditController.text.trim();
    if (text.isNotEmpty) {
      provider.updateTranscript(text);
      provider.processTextInput(text);
    }
    setState(() => _isEditingTranscript = false);
  }

  @override
  Widget build(BuildContext context) {
    final inputProvider = context.watch<InputProvider>();
    final reminderProvider = context.read<ReminderProvider>();
    final diaryProvider = context.read<DiaryProvider>();
    final isListening = inputProvider.isListening;
    final parsed = inputProvider.parsedInput;
    final activeMode = inputProvider.activeMode;
    final voiceState = inputProvider.voiceState;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          activeMode.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Clear / Reset',
            onPressed: () {
              setState(() => _isEditingTranscript = false);
              inputProvider.clear();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Mode Selector Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildModeChip(inputProvider, VoiceMode.general,
                                'AI Assistant', Icons.auto_awesome_rounded),
                            _buildModeChip(inputProvider, VoiceMode.diary,
                                'Voice Diary', Icons.auto_stories_rounded),
                            _buildModeChip(inputProvider, VoiceMode.reminder,
                                'Voice Reminder', Icons.alarm_rounded),
                            _buildModeChip(inputProvider, VoiceMode.task,
                                'Voice Task', Icons.task_alt_rounded),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Central Animated Voice Ripple UI
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Wave 1
                            if (isListening)
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: 200 + (30 * _pulseController.value),
                                    height: 200 + (30 * _pulseController.value),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.champagne(isDark)
                                          .withValues(
                                        alpha: 0.15 *
                                            (1.0 - _pulseController.value),
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Outer Wave 2
                            if (isListening)
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: 150 + (20 * _pulseController.value),
                                    height: 150 + (20 * _pulseController.value),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          AppColors.primary(isDark).withValues(
                                        alpha: 0.20 *
                                            (1.0 - _pulseController.value),
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Central Mic Button
                            GestureDetector(
                              onTap: () => _toggleListening(inputProvider),
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isListening
                                      ? null
                                      : AppGradients.signature(isDark),
                                  color: isListening ? AppColors.error : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isListening
                                              ? AppColors.error
                                              : AppColors.champagne(isDark))
                                          .withValues(
                                              alpha: isDark ? 0.35 : 0.25),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isListening
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  size: 44,
                                  color: isListening
                                      ? Colors.white
                                      : const Color(0xFF262A23),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // State and Progress Feedback Label
                      Text(
                        inputProvider.processingMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isListening
                              ? AppColors.error
                              : (voiceState == VoiceProcessingState.processing
                                  ? AppColors.primary(isDark)
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          activeMode.promptText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Success Saved Feedback Banner
                      if (inputProvider.lastSavedTitle.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    AppColors.success.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      inputProvider.lastSavedType ==
                                              IntentType.reminder
                                          ? 'Saved to Reminders!'
                                          : 'Saved to Diary!',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      inputProvider.lastSavedTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_isEditingTranscript) ...[
                        // Inline Transcript Editing Box
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: AppColors.primary(isDark)),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _transcriptEditController,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Edit speech transcript...',
                                  border: InputBorder.none,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => setState(
                                        () => _isEditingTranscript = false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _submitEditedTranscript(inputProvider),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors.primary(isDark),
                                      foregroundColor: isDark
                                          ? AppColors.darkOnPrimary
                                          : Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                    ),
                                    child: const Text('Update & Parse',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else if (inputProvider.currentInput.isNotEmpty) ...[
                        // Recognized transcript card (always visible when input is present)
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightSurfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.format_quote_rounded,
                                  size: 18, color: AppColors.primary(isDark)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  inputProvider.currentInput,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                tooltip: 'Edit transcript',
                                onPressed: () => _editAndReparse(inputProvider),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Parsed Command Preview
                      if (parsed != null &&
                          inputProvider.lastSavedTitle.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: CommandPreviewCard(
                            input: parsed,
                            onSelectAlternativeDate: (newDate) {
                              inputProvider.saveConfirmedInput(
                                input: parsed,
                                reminderProvider: reminderProvider,
                                diaryProvider: diaryProvider,
                                overrideDueDate: newDate,
                              );
                              AppFeedback.showSuccess(
                                  context, 'Reminder created');
                            },
                            onSaveReminder: () {
                              inputProvider.saveConfirmedInput(
                                input: parsed,
                                reminderProvider: reminderProvider,
                                diaryProvider: diaryProvider,
                              );
                              AppFeedback.showSuccess(
                                  context, 'Reminder created');
                            },
                            onSaveDiary: () {
                              final diaryInput = ParsedInput(
                                intent: IntentType.diary,
                                originalText: parsed.originalText,
                                confidence: parsed.confidence,
                                title: parsed.title,
                                description: parsed.originalText,
                                tags: parsed.tags,
                                sourceType: parsed.sourceType,
                              );
                              inputProvider.saveConfirmedInput(
                                input: diaryInput,
                                reminderProvider: reminderProvider,
                                diaryProvider: diaryProvider,
                              );
                              AppFeedback.showSuccess(context, 'Diary saved');
                            },
                            onEdit: () async {
                              final isDiary =
                                  parsed.intent == IntentType.diary ||
                                      inputProvider.activeMode ==
                                          VoiceMode.diary;
                              if (isDiary) {
                                final entry = DiaryEntry(
                                  id: IdGenerator.newId(),
                                  title: parsed.title.isNotEmpty
                                      ? parsed.title
                                      : 'Voice Note',
                                  content: parsed.description.isNotEmpty
                                      ? parsed.description
                                      : parsed.originalText,
                                  tags: parsed.tags.isNotEmpty
                                      ? parsed.tags
                                      : ['Voice'],
                                  sourceType: parsed.sourceType,
                                  confidence: parsed.confidence,
                                );
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DiaryEditorScreen(entry: entry),
                                  ),
                                );
                                if (result != null) {
                                  inputProvider.clear();
                                  if (context.mounted) {
                                    AppFeedback.showSuccess(
                                        context, result.toString());
                                  }
                                }
                              } else {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddEditReminderScreen(
                                      reminder: Reminder(
                                        id: IdGenerator.newId(),
                                        title: parsed.title,
                                        description: parsed.description,
                                        dueDate: parsed.dueDate ??
                                            DateTime.now().add(
                                                const Duration(hours: 1)),
                                        recurrence: parsed.recurrence,
                                        sourceType: parsed.sourceType,
                                        confidence: parsed.confidence,
                                      ),
                                    ),
                                  ),
                                );
                                if (result != null && mounted) {
                                  inputProvider.clear();
                                }
                              }
                            },
                            onDismiss: () {
                              inputProvider.clear();
                              AppFeedback.showInfo(context, 'Input discarded');
                            },
                          ),
                        ),

                      // Error display if any
                      if (inputProvider.speechError.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 18, color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    inputProvider.speechError,
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeChip(
    InputProvider provider,
    VoiceMode mode,
    String label,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = provider.activeMode == mode;
    final primaryColor = AppColors.primary(isDark);
    final onPrimary = isDark ? AppColors.darkOnPrimary : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? onPrimary : primaryColor,
        ),
        label: Text(label),
        selected: isSelected,
        selectedColor: primaryColor,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? onPrimary : AppColors.textSecondary(isDark),
        ),
        onSelected: (selected) {
          if (selected) provider.setVoiceMode(mode);
        },
      ),
    );
  }
}
