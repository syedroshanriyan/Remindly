import 'package:intl/intl.dart';
import '../models/recurrence_rule.dart';

class ExtractedEntities {
  final String title;
  final String description;
  final DateTime? dueDate;
  final RecurrenceType recurrence;
  final bool hasExplicitDate;
  final bool hasExplicitTime;
  final bool isPastTime;
  final bool isAmbiguousTime;
  final String? matchedTimeExpression;
  final DateTime? suggestedAlternativeDate;
  final String? clarificationPrompt;

  const ExtractedEntities({
    required this.title,
    this.description = '',
    this.dueDate,
    this.recurrence = RecurrenceType.none,
    this.hasExplicitDate = false,
    this.hasExplicitTime = false,
    this.isPastTime = false,
    this.isAmbiguousTime = false,
    this.matchedTimeExpression,
    this.suggestedAlternativeDate,
    this.clarificationPrompt,
  });
}

class EntityExtractor {
  static final RegExp _commandPrefixRegex = RegExp(
    r"\b(please\s+)?(remind\s+me\s+(about\s+|to\s+|that\s+)?|set\s+a\s+reminder\s+(to\s+|for\s+)?|don'?t\s+let\s+me\s+forget\s+(to\s+|that\s+)?|remember\s+to\s+|notify\s+me\s+(to\s+|about\s+)?|alert\s+me\s+(to\s+|about\s+)?|schedule\s+(a\s+)?reminder\s+(to\s+|for\s+)?|i\s+need\s+to\s+|i\s+have\s+to\s+|must\s+|kindly\s+remind\s+me\s+(to\s+)?|put\s+a\s+reminder\s+(to\s+|for\s+)?|alarm\s+me\s+(to\s+)?|ping\s+me\s+(to\s+)?)",
    caseSensitive: false,
  );

  static String _normalizeInput(String input) {
    String text = input.trim();

    // 1. Normalize AM/PM variations with dots or spaces:
    // e.g. "p.m.", "p. m.", "p.m", "pm.", "p m", "P.M.", "P. M." -> "pm"
    // e.g. "a.m.", "a. m.", "a.m", "am.", "a m", "A.M.", "A. M." -> "am"
    text = text.replaceAllMapped(
      RegExp(r'\b([ap])\s*\.\s*m(\.|\b)', caseSensitive: false),
      (m) => '${m.group(1)!.toLowerCase()}m',
    );
    text = text.replaceAllMapped(
      RegExp(r'\b([ap]m)\.(?=\s|$|[,\.!?])', caseSensitive: false),
      (m) => m.group(1)!.toLowerCase(),
    );
    text = text.replaceAllMapped(
      RegExp(r'(\d+)\s+([ap])\s+m\b', caseSensitive: false),
      (m) => '${m.group(1)} ${m.group(2)!.toLowerCase()}m',
    );

    // 2. Colon spacing and single-digit minute padding:
    // e.g. "8 :5 pm" -> "8:05 pm", "8 : 5 pm" -> "8:05 pm", "8:5 pm" -> "8:05 pm"
    text = text.replaceAllMapped(
      RegExp(r'(\b\d{1,2})\s*:\s*(\d{1,2}\b)'),
      (m) {
        final h = m.group(1)!;
        var min = m.group(2)!;
        if (min.length == 1) min = '0$min';
        return '$h:$min';
      },
    );

    // 3. Dot notation for time with am/pm: "8.05 pm", "8.5 pm" -> "8:05 pm"
    text = text.replaceAllMapped(
      RegExp(r'(\b\d{1,2})\s*\.\s*(\d{1,2})\s*(am|pm)\b', caseSensitive: false),
      (m) {
        final h = m.group(1)!;
        var min = m.group(2)!;
        final ampm = m.group(3)!.toLowerCase();
        if (min.length == 1) min = '0$min';
        return '$h:$min $ampm';
      },
    );

    // 4. Space notation for time with am/pm: "8 05 pm", "8 5 pm" -> "8:05 pm"
    text = text.replaceAllMapped(
      RegExp(r'(\b\d{1,2})\s+(\d{1,2})\s*(am|pm)\b', caseSensitive: false),
      (m) {
        final h = m.group(1)!;
        var min = m.group(2)!;
        final ampm = m.group(3)!.toLowerCase();
        if (min.length == 1) min = '0$min';
        return '$h:$min $ampm';
      },
    );

    // 5. Spoken number words before am/pm or o'clock (excluding compound minutes like fifty five)
    final wordMap = {
      'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5',
      'six': '6', 'seven': '7', 'eight': '8', 'nine': '9', 'ten': '10',
      'eleven': '11', 'twelve': '12',
    };
    for (final e in wordMap.entries) {
      text = text.replaceAllMapped(
        RegExp('(?<!twenty\\s|thirty\\s|forty\\s|fifty\\s)\\b${e.key}\\s*(am|pm)\\b', caseSensitive: false),
        (m) => '${e.value} ${m.group(1)!.toLowerCase()}',
      );
      text = text.replaceAll(
        RegExp('\\b${e.key}\\s*o[\'\u2019]?clock\\b', caseSensitive: false),
        '${e.value}:00',
      );
    }

    return text;
  }

  static ExtractedEntities extract(String input, {DateTime? referenceNow}) {
    final text = _normalizeInput(input);
    final lower = text.toLowerCase();
    final now = referenceNow ?? DateTime.now();

    // 1. RECURRENCE EXTRACTION
    RecurrenceType recurrence = RecurrenceType.none;
    String? matchedRecurrenceExpr;

    if (lower.contains('every weekday') || lower.contains('on weekdays')) {
      recurrence = RecurrenceType.weekdays;
      matchedRecurrenceExpr = 'every weekday';
    } else if (lower.contains('every day') ||
        lower.contains('daily') ||
        lower.contains('every morning')) {
      recurrence = RecurrenceType.daily;
      matchedRecurrenceExpr = lower.contains('daily')
          ? 'daily'
          : (lower.contains('every morning') ? 'every morning' : 'every day');
    } else if (lower.contains('every week') ||
        lower.contains('weekly') ||
        lower.contains('every weekend')) {
      recurrence = RecurrenceType.weekly;
      matchedRecurrenceExpr = lower.contains('weekly')
          ? 'weekly'
          : (lower.contains('every weekend') ? 'every weekend' : 'every week');
    } else if (lower.contains('every month') || lower.contains('monthly')) {
      recurrence = RecurrenceType.monthly;
      matchedRecurrenceExpr =
          lower.contains('monthly') ? 'monthly' : 'every month';
    } else if (lower.contains('every year') || lower.contains('yearly')) {
      recurrence = RecurrenceType.yearly;
      matchedRecurrenceExpr =
          lower.contains('yearly') ? 'yearly' : 'every year';
    } else if (RegExp(
            r'\bevery\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
            caseSensitive: false)
        .hasMatch(lower)) {
      recurrence = RecurrenceType.weekly;
      final match = RegExp(
              r'\bevery\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
              caseSensitive: false)
          .firstMatch(lower);
      matchedRecurrenceExpr = match?.group(0);
    }

    // 2. RELATIVE DURATION ("in 10 minutes", "in 2 hours", "after 45 mins", "in 3 days")
    DateTime? extractedDateTime;
    bool hasDate = false;
    bool hasTime = false;
    bool isPast = false;
    bool isAmbiguous = false;
    String? matchedTimeExpr;
    DateTime? suggestedAlternative;
    String? clarificationPrompt;

    final relMatch = RegExp(
      r'\b(in|after)\s+(\d+)\s+(minute|min|minutes|mins|hour|hours|hr|hrs|day|days)\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (relMatch != null) {
      final amount = int.tryParse(relMatch.group(2) ?? '0') ?? 0;
      final unit = relMatch.group(3)?.toLowerCase() ?? '';
      matchedTimeExpr = relMatch.group(0);

      if (unit.startsWith('min')) {
        extractedDateTime = now.add(Duration(minutes: amount));
      } else if (unit.startsWith('h')) {
        extractedDateTime = now.add(Duration(hours: amount));
      } else if (unit.startsWith('day')) {
        extractedDateTime = now.add(Duration(days: amount));
      }
      hasDate = true;
      hasTime = true;
    }

    // 3. NAMED DAYS AND PERIODS
    if (extractedDateTime == null) {
      DateTime targetDate = now;
      int targetHour = -1;
      int targetMinute = 0;
      bool dateExplicitlySpecified = false;

      // Day matching
      if (RegExp(r'\bday\s+after\s+tomorrow\b', caseSensitive: false)
          .hasMatch(lower)) {
        targetDate = now.add(const Duration(days: 2));
        hasDate = true;
        dateExplicitlySpecified = true;
        matchedTimeExpr = 'day after tomorrow';
      } else if (RegExp(r'\btomorrow\b', caseSensitive: false)
          .hasMatch(lower)) {
        targetDate = now.add(const Duration(days: 1));
        hasDate = true;
        dateExplicitlySpecified = true;
        matchedTimeExpr = 'tomorrow';
      } else if (RegExp(r'\btoday\b', caseSensitive: false).hasMatch(lower)) {
        targetDate = now;
        hasDate = true;
        dateExplicitlySpecified = true;
        matchedTimeExpr = 'today';
      } else {
        // Weekdays: "next Monday", "on Friday", "Monday at 9", "every Monday"
        final weekdayMap = {
          'monday': DateTime.monday,
          'tuesday': DateTime.tuesday,
          'wednesday': DateTime.wednesday,
          'thursday': DateTime.thursday,
          'friday': DateTime.friday,
          'saturday': DateTime.saturday,
          'sunday': DateTime.sunday,
        };
        for (final entry in weekdayMap.entries) {
          final dayRegex = RegExp('\\b(next\\s+|on\\s+)?${entry.key}\\b',
              caseSensitive: false);
          if (dayRegex.hasMatch(lower)) {
            final targetWeekday = entry.value;
            int daysToAdd = (targetWeekday - now.weekday) % 7;
            if (daysToAdd <= 0) daysToAdd += 7;
            targetDate = now.add(Duration(days: daysToAdd));
            hasDate = true;
            dateExplicitlySpecified = true;
            matchedTimeExpr = entry.key;
            break;
          }
        }
      }

      // Contextual Period Detection (does not lock hasTime so explicit hours can be parsed)
      bool hasPeriodContext = false;
      String? periodType; // 'tonight', 'evening', 'afternoon', 'morning'
      int periodDefaultHour = -1;

      if (RegExp(r'\btonight\b', caseSensitive: false).hasMatch(lower)) {
        hasPeriodContext = true;
        periodType = 'tonight';
        periodDefaultHour = 20; // 8:00 PM
        hasDate = true;
        matchedTimeExpr =
            (matchedTimeExpr != null) ? '$matchedTimeExpr tonight' : 'tonight';
      } else if (RegExp(r'\b(this\s+|tomorrow\s+)?evening\b',
              caseSensitive: false)
          .hasMatch(lower)) {
        hasPeriodContext = true;
        periodType = 'evening';
        periodDefaultHour = 18; // 6:00 PM
        hasDate = true;
        matchedTimeExpr =
            (matchedTimeExpr != null) ? '$matchedTimeExpr evening' : 'evening';
      } else if (RegExp(r'\b(this\s+|tomorrow\s+|friday\s+)?afternoon\b',
              caseSensitive: false)
          .hasMatch(lower)) {
        hasPeriodContext = true;
        periodType = 'afternoon';
        periodDefaultHour = 14; // 2:00 PM
        hasDate = true;
        matchedTimeExpr = (matchedTimeExpr != null)
            ? '$matchedTimeExpr afternoon'
            : 'afternoon';
      } else if (RegExp(r'\b(this\s+|tomorrow\s+)?morning\b',
              caseSensitive: false)
          .hasMatch(lower)) {
        hasPeriodContext = true;
        periodType = 'morning';
        periodDefaultHour = 9; // 9:00 AM
        hasDate = true;
        matchedTimeExpr =
            (matchedTimeExpr != null) ? '$matchedTimeExpr morning' : 'morning';
      }

      // Check explicit clock time:
      // A: Relative expressions: "half past 7", "quarter past 7", "quarter to 8"
      if (!hasTime) {
        final relClockMatch = RegExp(
          r'\b(?:at\s+)?(half\s+past|quarter\s+past|quarter\s+to)\s+(\d{1,2})\s*(am|pm)?\b',
          caseSensitive: false,
        ).firstMatch(text);

        if (relClockMatch != null) {
          final relType = relClockMatch.group(1)!.toLowerCase();
          int h = int.parse(relClockMatch.group(2)!);
          final ampm = relClockMatch.group(3)?.toLowerCase();
          int m = 0;

          if (relType.contains('half')) {
            m = 30;
          } else if (relType.contains('quarter past')) {
            m = 15;
          } else if (relType.contains('quarter to')) {
            m = 45;
            h = (h == 1) ? 12 : h - 1;
          }

          if (ampm == 'pm' && h < 12) h += 12;
          if (ampm == 'am' && h == 12) h = 0;
          if (ampm == null) {
            if (periodType == 'tonight' || periodType == 'evening' || periodType == 'afternoon') {
              if (h < 12) h += 12;
            } else if (periodType == 'morning') {
              if (h == 12) h = 0;
            } else if (h <= 12) {
              h = (h >= 8 && h <= 11) ? h : h + 12;
            }
          }

          targetHour = h;
          targetMinute = m;
          hasTime = true;
          matchedTimeExpr = relClockMatch.group(0);
        }
      }

      // B: Spoken word minutes: "7 fifty five pm", "7 thirty pm", "at 7 forty five", "7 fifteen am"
      if (!hasTime) {
        final wordMinPattern = RegExp(
          r'\b(?:(at|around)\s+)?(\d{1,2})\s+(fifty\s+five|forty\s+five|thirty\s+five|twenty\s+five|fifteen|forty|fifty|thirty|twenty|ten|oh\s+five|o\s+five|five|o[\x27\u2019]clock|oclock|o\s+clock)\s*(am|pm)?\b',
          caseSensitive: false,
        ).firstMatch(text);

        if (wordMinPattern != null) {
          int h = int.parse(wordMinPattern.group(2)!);
          final wordStr = wordMinPattern.group(3)!;
          final ampm = wordMinPattern.group(4)?.toLowerCase();
          int m = _wordToMinute(wordStr);

          if (ampm == 'pm' && h < 12) h += 12;
          if (ampm == 'am' && h == 12) h = 0;
          if (ampm == null) {
            if (periodType == 'tonight' || periodType == 'evening' || periodType == 'afternoon') {
              if (h < 12) h += 12;
            } else if (periodType == 'morning') {
              if (h == 12) h = 0;
            } else if (h <= 12) {
              h = (h >= 8 && h <= 11) ? h : h + 12;
            }
          }

          if (h >= 0 && h <= 23 && m >= 0 && m <= 59) {
            targetHour = h;
            targetMinute = m;
            hasTime = true;
            matchedTimeExpr = wordMinPattern.group(0);
          }
        }
      }

      // C: Explicit Hours + Minutes:
      // Supports colon-separated ("8:5 pm", "8 :5 pm", "8:05 pm", "7:55 pm", "17:30"),
      // dot-separated ("7.55 pm", "8.05 pm", "at 7.55"), and space-separated ("7 55 pm", "8 5 pm", "8 05 pm")
      if (!hasTime) {
        final colonDotMatches = RegExp(
          r'\b(?:(at|around)\s+)?(\d{1,2})\s*([:\.])\s*(\d{1,2})\s*(am|pm)?\b',
          caseSensitive: false,
        ).allMatches(text);

        for (final match in colonDotMatches) {
          final prefix = match.group(1);
          final hourStr = match.group(2)!;
          final minStr = match.group(4)!;
          final ampm = match.group(5)?.toLowerCase();

          int h = int.parse(hourStr);
          int m = int.parse(minStr);

          if (m < 0 || m > 59) continue;

          if (ampm != null) {
            if (h < 1 || h > 12) continue;
            if (ampm == 'pm' && h < 12) h += 12;
            if (ampm == 'am' && h == 12) h = 0;
          } else {
            // Period context promotion
            if (periodType == 'tonight' || periodType == 'evening' || periodType == 'afternoon') {
              if (h < 12) h += 12;
            } else if (periodType == 'morning') {
              if (h == 12) h = 0;
            } else if (h >= 0 && h <= 23) {
              if (prefix != null && h >= 1 && h <= 12) {
                h = (h >= 8 && h <= 11) ? h : h + 12;
              } else if (h >= 1 && h <= 12) {
                isAmbiguous = true;
                final displayMin = m.toString().padLeft(2, '0');
                clarificationPrompt =
                    'Would you like $h:$displayMin AM or $h:$displayMin PM?';
                h = (h >= 8 && h <= 11) ? h : h + 12;
              }
            } else {
              continue;
            }
          }

          targetHour = h;
          targetMinute = m;
          hasTime = true;
          matchedTimeExpr = match.group(0)!.trim();
          break;
        }
      }

      // C2: Space-separated Hours and Minutes (e.g. "8 5 pm", "8 05 pm", "7 55 pm", "at 8 5")
      if (!hasTime) {
        final spaceMinMatches = RegExp(
          r'\b(?:(at|around)\s+)?(\d{1,2})\s+(\d{1,2})\s*(am|pm)?\b',
          caseSensitive: false,
        ).allMatches(text);

        for (final match in spaceMinMatches) {
          final prefix = match.group(1);
          final hourStr = match.group(2)!;
          final minStr = match.group(3)!;
          final ampm = match.group(4)?.toLowerCase();

          // If separator is space, require prefix or am/pm
          if (prefix == null && ampm == null) continue;

          int h = int.parse(hourStr);
          int m = int.parse(minStr);

          if (m < 0 || m > 59) continue;
          if (h < 1 || h > 12) continue;

          if (ampm != null) {
            if (ampm == 'pm' && h < 12) h += 12;
            if (ampm == 'am' && h == 12) h = 0;
          } else {
            if (periodType == 'tonight' || periodType == 'evening' || periodType == 'afternoon') {
              if (h < 12) h += 12;
            } else if (periodType == 'morning') {
              if (h == 12) h = 0;
            } else {
              h = (h >= 8 && h <= 11) ? h : h + 12;
            }
          }

          targetHour = h;
          targetMinute = m;
          hasTime = true;
          matchedTimeExpr = match.group(0)!.trim();
          break;
        }
      }

      // D: Standard Single Hour: "at 7 pm", "7 pm", "around 9 am", "at 7"
      if (!hasTime) {
        final singleHourMatches = RegExp(
          r'\b(?:(at|around)\s+)?(\d{1,2})\s*(am|pm)?\b',
          caseSensitive: false,
        ).allMatches(text);

        for (final match in singleHourMatches) {
          final prefix = match.group(1);
          final hourStr = match.group(2);
          final ampm = match.group(3)?.toLowerCase();

          if (hourStr == null) continue;
          final fullMatch = match.group(0)!.trim();

          // Must have am/pm or prefix (at/around)
          if (ampm == null && prefix == null) continue;

          int h = int.parse(hourStr);
          if (h < 1 || h > 12) continue;

          if (ampm == null) {
            if (periodType == 'tonight' || periodType == 'evening' || periodType == 'afternoon') {
              if (h < 12) h += 12;
              targetHour = h;
              targetMinute = 0;
              hasTime = true;
              matchedTimeExpr = fullMatch;
              break;
            } else if (periodType == 'morning') {
              if (h == 12) h = 0;
              targetHour = h;
              targetMinute = 0;
              hasTime = true;
              matchedTimeExpr = fullMatch;
              break;
            }

            // Ambiguous isolated number, e.g. "at 7"
            isAmbiguous = true;
            clarificationPrompt = 'Would you like $h AM or $h PM?';
            targetHour =
                (h >= 8 && h <= 11) ? h : h + 12; // provisional fallback
            matchedTimeExpr = fullMatch;
            hasTime = true;
            break;
          }

          if (ampm == 'pm' && h < 12) h += 12;
          if (ampm == 'am' && h == 12) h = 0;

          if (h >= 0 && h <= 23) {
            targetHour = h;
            targetMinute = 0;
            hasTime = true;
            matchedTimeExpr = fullMatch;
            break;
          }
        }
      }

      // If no explicit clock time matched, but period context exists (e.g. "remind me tonight")
      if (!hasTime && hasPeriodContext && periodDefaultHour != -1) {
        targetHour = periodDefaultHour;
        targetMinute = 0;
        hasTime = true;
      }

      // Date resolution & past time checks
      if (hasDate || hasTime) {
        final hour = targetHour != -1 ? targetHour : 9;
        final minute = targetMinute;

        DateTime candidate = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
          minute,
        );

        // Check past time validation
        if (candidate.isBefore(now)) {
          if (!dateExplicitlySpecified) {
            // User did not explicitly say "today" (e.g. "at 8:05 pm"), and it already passed today.
            // Automatically schedule for tomorrow at that time.
            candidate = candidate.add(const Duration(days: 1));
            extractedDateTime = candidate;
          } else {
            // User explicitly said "today at 8:05 pm", but it already passed today.
            isPast = true;
            suggestedAlternative = candidate.add(const Duration(days: 1));
            final formattedPast = DateFormat('h:mm a').format(candidate);
            final formattedAlt =
                DateFormat('h:mm a').format(suggestedAlternative);
            clarificationPrompt =
                '$formattedPast today has already passed. Would you like to set it for tomorrow at $formattedAlt?';
            extractedDateTime = candidate;
          }
        } else {
          extractedDateTime = candidate;
        }

        // If day was specified without any time (e.g. "Remind me tomorrow", "Remind me Monday")
        if (dateExplicitlySpecified && !hasTime) {
          isAmbiguous = true;
          final dayName = DateFormat('EEEE').format(targetDate);
          clarificationPrompt = '$dayName — what time should I use?';
        }
      }
    }

    // 4. TITLE & DESCRIPTION GENERATION
    String working = text;

    // Remove weekday names
    working = working.replaceAll(
      RegExp(
          r'\b(next|on|this)?\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
          caseSensitive: false),
      ' ',
    );

    // Remove recurrence expression
    if (matchedRecurrenceExpr != null && matchedRecurrenceExpr.isNotEmpty) {
      working = working.replaceAll(
          RegExp('\\b${RegExp.escape(matchedRecurrenceExpr)}\\b',
              caseSensitive: false),
          ' ');
    }

    // Remove matched time expression
    if (matchedTimeExpr != null && matchedTimeExpr.isNotEmpty) {
      working = working.replaceAll(
          RegExp('\\b${RegExp.escape(matchedTimeExpr)}\\b',
              caseSensitive: false),
          ' ');
    }

    // Remove explicit clock times like 9 am, 7 pm, 8 :5 pm, 8:5 pm, 7:55 pm, 7 55 pm
    working = working.replaceAll(
      RegExp(r'\b(?:at|around\s+)?\d{1,2}(?:\s*[:\.]\s*\d{1,2}|\s+\d{1,2})?\s*(?:am|pm)\b',
          caseSensitive: false),
      ' ',
    );
    working = working.replaceAll(
      RegExp(r'\b(?:at|around)\s+\d{1,2}(?:\s*[:\.]\s*\d{1,2}|\s+\d{1,2})?\b',
          caseSensitive: false),
      ' ',
    );
    working = working.replaceAll(
      RegExp(r'\b\d{1,2}\s*[:\.]\s*\d{1,2}\b', caseSensitive: false),
      ' ',
    );

    // Remove command prefixes anywhere in text
    working = working.replaceAll(_commandPrefixRegex, ' ');

    // Clean stray prepositions and time tokens
    working = working
        .replaceAll(
            RegExp(
                r'\b(at|on|tomorrow|today|tonight|morning|evening|afternoon|next week|day after tomorrow)\b',
                caseSensitive: false),
            ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Clean trailing punctuation
    if (working.endsWith('.')) {
      working = working.substring(0, working.length - 1).trim();
    }

    // Intelligently separate Title and Description if context exists
    String finalTitle = working;
    String finalDescription = '';

    if (working.toLowerCase().startsWith('to ')) {
      working = working.substring(3).trim();
    }
    if (working.toLowerCase().startsWith('about ')) {
      working = working.substring(6).trim();
    }

    if (working.isEmpty) {
      finalTitle = 'Reminder';
    } else {
      // Doctor appointment check
      if (RegExp(r'\b(doctor|physician|clinic)\b', caseSensitive: false)
          .hasMatch(working)) {
        finalTitle = 'Doctor appointment';
        finalDescription = text.trim();
      } else {
        // Look for contextual expansions: "submit the project report to Professor Ahmed before the deadline"
        final toRegex = RegExp(
            r'^(submit\s+(?:the\s+)?project\s+report)\s+(to\s+.+)$',
            caseSensitive: false);

        if (toRegex.hasMatch(working)) {
          finalTitle = 'Submit project report';
          finalDescription = working;
        } else {
          // Concise title: first 6-8 words or up to 45 chars
          final words = working.split(' ');
          if (words.length > 7) {
            finalTitle = words.take(5).join(' ');
            finalDescription = working;
          } else {
            finalTitle = working;
          }
        }
      }
    }

    // Capitalize title
    if (finalTitle.isNotEmpty) {
      finalTitle = finalTitle[0].toUpperCase() + finalTitle.substring(1);
    }
    if (finalDescription.isNotEmpty &&
        finalDescription.toLowerCase() == finalTitle.toLowerCase()) {
      finalDescription = ''; // Do not duplicate title
    }

    return ExtractedEntities(
      title: finalTitle,
      description: finalDescription,
      dueDate: extractedDateTime,
      recurrence: recurrence,
      hasExplicitDate: hasDate,
      hasExplicitTime: hasTime,
      isPastTime: isPast,
      isAmbiguousTime: isAmbiguous,
      matchedTimeExpression: matchedTimeExpr,
      suggestedAlternativeDate: suggestedAlternative,
      clarificationPrompt: clarificationPrompt,
    );
  }

  static int _wordToMinute(String word) {
    final clean = word.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    switch (clean) {
      case "o'clock":
      case "o’clock":
      case 'oclock':
      case 'o clock':
        return 0;
      case 'oh five':
      case 'o five':
      case 'five':
        return 5;
      case 'ten':
        return 10;
      case 'fifteen':
        return 15;
      case 'twenty':
        return 20;
      case 'twenty five':
        return 25;
      case 'thirty':
        return 30;
      case 'thirty five':
        return 35;
      case 'forty':
        return 40;
      case 'forty five':
        return 45;
      case 'fifty':
        return 50;
      case 'fifty five':
        return 55;
      default:
        return 0;
    }
  }
}
