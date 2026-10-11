# Remindly — AI Smart Personal Diary + Intelligent Reminder

> *"Never miss what matters."*

Remindly is a production-grade, privacy-first, 100% offline mobile application that blends intelligent scheduled reminders with a reflective personal journal. Built on Flutter and Dart, Remindly runs all machine learning intent classification, entity extraction, speech recognition, and text-to-speech completely on-device with zero external cloud dependencies.

---

## 🌟 Key Features

- 🔒 **Zero-Cloud & 100% Private**: No servers, no tracking, no third-party telemetry, and no account needed.
- 🧠 **On-Device Hybrid Intelligence**: Uses a compact local ML classifier + deterministic temporal rules to distinguish reminders from journal entries.
- 📖 **Smart Personal Diary**: Private journaling with automatic tag detection (`#work`, `#gratitude`, etc.), chronological sorting, and full-text search.
- ⏰ **Interactive Alarms**: Local scheduled notifications with actions for **Done**, **Snooze 10m**, **Snooze 15m**, and **Mute**.
- 🗣️ **Offline Voice & TTS**: Speak naturally to schedule tasks or dictate diary reflections; reminders announce themselves using on-device text-to-speech.
- 💾 **Local Data Backup**: Export and import your entire database as portable, schema-validated JSON files.
- 🎨 **Premium Material 3 Design**: Carefully curated light and dark palettes, elevation shadows, and dashboard hero cards.

---

## 📐 Architecture & Structure

Remindly follows a pragmatic, layered feature architecture:

```
lib/
├── main.dart                       # App entrypoint & local service initialization
├── app/
│   └── routes.dart                 # Centralized route definitions
├── core/
│   ├── constants/                  # Channel IDs, box names, thresholds
│   ├── errors/                     # App exceptions & error types
│   ├── theme/                      # AppColors, DesignTokens, AppTheme
│   └── utils/                      # DateTimeUtils, IdGenerator (FNV-1a 31-bit IDs)
├── models/
│   ├── diary_entry.dart            # Diary domain entity
│   ├── notification_action.dart    # Done, Snooze, Mute actions
│   ├── parsed_input.dart           # CommandParser result
│   ├── recurrence_rule.dart        # Recurrence calculations
│   └── reminder.dart               # Reminder domain entity
├── providers/
│   ├── diary_provider.dart         # Journal state management
│   ├── input_provider.dart         # Voice/text capture orchestration
│   ├── reminder_provider.dart      # Reminder state management
│   ├── settings_provider.dart      # Voice announcement & sound preferences
│   └── theme_provider.dart         # System / Light / Dark theme state
├── services/
│   ├── backup_service.dart         # JSON export & validated import
│   ├── command_parser.dart         # Unified intent + entity pipeline
│   ├── entity_extractor.dart       # Deterministic dates, times, durations
│   ├── hive_service.dart           # Local Hive box manager
│   ├── intent_classifier.dart      # On-device ML inference engine
│   ├── notification_service.dart   # Scheduled alarms & action receivers
│   ├── privacy_service.dart        # Privacy guarantees & data wiping
│   ├── reminder_scheduler.dart     # Central scheduling & snooze controller
│   ├── speech_service.dart         # On-device speech recognition (STT)
│   └── tts_service.dart            # On-device text-to-speech (TTS)
├── screens/
│   ├── about_screen.dart           # App info & open source licenses
│   ├── add_edit_reminder_screen.dart # Reminder editor with recurrence
│   ├── archive_screen.dart         # Archived reminders & diary entries
│   ├── diary_screen.dart           # Journal overview & tag filter
│   ├── home_screen.dart            # Hero dashboard, progress, & quick input
│   ├── main_navigation_screen.dart # Bottom navigation controller
│   ├── onboarding_screen.dart      # First-launch privacy walkthrough
│   ├── privacy_screen.dart         # Zero-cloud transparency
│   ├── search_screen.dart          # Unified search across reminders & diary
│   ├── settings_screen.dart        # Preferences, audio, & data management
│   ├── splash_screen.dart          # Custom animated bell splash
│   └── voice_screen.dart           # Dedicated voice capture screen
└── widgets/
    ├── animated_bell.dart          # Custom splash bell animation
    ├── command_preview.dart        # Confirmation card for parsed input
    ├── diary_card.dart             # Journal entry card
    ├── empty_state.dart            # Contextual empty state illustrations
    ├── reminder_card.dart          # Interactive reminder card with actions
    ├── segmented_tabs.dart         # Smooth status tab selector
    └── voice_input_button.dart     # Pulsing microphone capture button
```

---

## 🧪 Testing & Quality Assurance

Run the automated test suite:
```powershell
flutter test
```
All **28 tests** (unit tests & widget tests) pass with 0 failures.

Run static analysis:
```powershell
flutter analyze
```
Verification passes with **No issues found** (zero errors, zero warnings, zero lints).

---

## 🤖 Local Machine Learning Pipeline

The ML pipeline is located in `ml/`:
- `ml/dataset/`: 3,312 balanced labeled examples (`reminder.csv`, `diary.csv`, `ambiguous.csv`).
- `ml/scripts/generate_dataset.py`: Dataset synthesizer.
- `ml/scripts/train_classifier.py`: Trains TF-IDF + Calibrated Logistic Regression model.
- `assets/ml/intent_weights.json`: Exported model weights (159 KB) used by Dart for sub-millisecond, zero-dependency inference.

To retrain and evaluate:
```powershell
python ml\scripts\generate_dataset.py
python ml\scripts\train_classifier.py
```

---

## 🚀 Building for Release

### Android App Bundle (Google Play)
```powershell
flutter build appbundle --release
```

### Android APK
```powershell
flutter build apk --release
```
