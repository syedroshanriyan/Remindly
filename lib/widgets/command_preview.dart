import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/design_tokens.dart';
import '../models/parsed_input.dart';
import '../models/recurrence_rule.dart';

class CommandPreviewCard extends StatelessWidget {
  final ParsedInput input;
  final VoidCallback onSaveReminder;
  final VoidCallback onSaveDiary;
  final VoidCallback onEdit;
  final VoidCallback onDismiss;
  final Function(DateTime)? onSelectAlternativeDate;

  const CommandPreviewCard({
    super.key,
    required this.input,
    required this.onSaveReminder,
    required this.onSaveDiary,
    required this.onEdit,
    required this.onDismiss,
    this.onSelectAlternativeDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReminder = input.intent == IntentType.reminder;
    final isDiary = input.intent == IntentType.diary;
    final isFutureEvent = input.intent == IntentType.futureEvent;
    final isOffTopic = input.intent == IntentType.offTopic;

    Color badgeColor;
    IconData badgeIcon;
    String badgeLabel;

    if (isReminder) {
      badgeColor = AppColors.primary(isDark);
      badgeIcon = Icons.alarm_rounded;
      badgeLabel = 'Reminder';
    } else if (isDiary) {
      badgeColor = AppColors.champagne(isDark);
      badgeIcon = Icons.auto_stories_rounded;
      badgeLabel = 'Diary Note';
    } else if (isFutureEvent) {
      badgeColor = AppColors.champagne(isDark);
      badgeIcon = Icons.event_available_rounded;
      badgeLabel = 'Future Event';
    } else if (isOffTopic) {
      badgeColor = AppColors.warning;
      badgeIcon = Icons.help_outline_rounded;
      badgeLabel = 'Notice';
    } else {
      badgeColor = AppColors.warning;
      badgeIcon = Icons.help_outline_rounded;
      badgeLabel = 'Review Needed';
    }

    // Natural language preview headline
    String headline;
    if (input.isPastTime && input.clarificationPrompt != null) {
      headline = input.clarificationPrompt!;
    } else if (input.isAmbiguousTime && input.clarificationPrompt != null) {
      headline = input.clarificationPrompt!;
    } else if (isFutureEvent && input.dueDate != null) {
      final dateStr = DateFormat('d MMMM at h:mm a').format(input.dueDate!);
      headline =
          'I noticed this is a future event on $dateStr. Would you like to create a reminder?';
    } else if (isOffTopic) {
      headline =
          "This doesn't appear to be a diary entry. Would you like to save it in your diary anyway?";
    } else if (isReminder && input.dueDate != null) {
      final dateStr = DateFormat('EEEE at h:mm a').format(input.dueDate!);
      headline = 'I think this is a reminder for $dateStr. Create it?';
    } else if (isReminder) {
      headline = 'I think this is a reminder. Create it?';
    } else {
      headline = 'Ready to save this entry:';
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: DesignTokens.themeCardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar with Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 15, color: badgeColor),
                    const SizedBox(width: 6),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Conversational natural language prompt
          Text(
            headline,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),

          const SizedBox(height: 8),

          // Extracted Title
          Text(
            input.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),

          // Extracted Description if present
          if (input.description.isNotEmpty &&
              input.description != input.title) ...[
            const SizedBox(height: 4),
            Text(
              input.description,
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

          // Date / Time / Recurrence info chips
          if (input.dueDate != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary(isDark).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.primary(isDark)),
                      const SizedBox(width: 5),
                      Text(
                        DateFormat('EEE, MMM d • h:mm a')
                            .format(input.dueDate!),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
                if (input.recurrence != RecurrenceType.none)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          AppColors.champagne(isDark).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.repeat_rounded,
                            size: 14, color: AppColors.champagne(isDark)),
                        const SizedBox(width: 5),
                        Text(
                          input.recurrence.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.champagne(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],

          // Past Time Disambiguation Shortcut: "Move to tomorrow at [Time]"
          if (input.isPastTime && input.suggestedAlternativeDate != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                if (onSelectAlternativeDate != null) {
                  onSelectAlternativeDate!(input.suggestedAlternativeDate!);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary(isDark).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary(isDark).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.update_rounded,
                        size: 16, color: AppColors.primary(isDark)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Set for tomorrow at ${DateFormat('h:mm a').format(input.suggestedAlternativeDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary(isDark),
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: AppColors.primary(isDark)),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              if (isOffTopic) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSaveDiary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(isDark),
                      foregroundColor:
                          isDark ? AppColors.darkOnPrimary : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Save as Diary',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Discard', style: TextStyle(fontSize: 13)),
                ),
              ] else if (isFutureEvent) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSaveReminder,
                    icon: Icon(Icons.alarm_add_rounded,
                        size: 16,
                        color: isDark ? AppColors.darkOnPrimary : Colors.white),
                    label: Text('Create Reminder',
                        style: TextStyle(
                            color:
                                isDark ? AppColors.darkOnPrimary : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(isDark),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onSaveDiary,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  child: const Text('Save Diary Only',
                      style: TextStyle(fontSize: 13)),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isReminder ? onSaveReminder : onSaveDiary,
                    icon: Icon(
                      isReminder
                          ? Icons.alarm_add_rounded
                          : Icons.note_add_rounded,
                      size: 16,
                      color: isDark ? AppColors.darkOnPrimary : Colors.white,
                    ),
                    label: Text(
                      isReminder ? 'Save Reminder' : 'Save Diary',
                      style: TextStyle(
                          color:
                              isDark ? AppColors.darkOnPrimary : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReminder
                          ? AppColors.primary(isDark)
                          : AppColors.champagne(isDark),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Discard',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit details',
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: isReminder ? onSaveDiary : onSaveReminder,
              child: Text(
                isReminder
                    ? 'Save as Diary entry instead'
                    : 'Set as Reminder instead',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
