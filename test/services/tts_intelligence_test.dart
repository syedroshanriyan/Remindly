import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/services/tts_service.dart';

void main() {
  group('TTSService Intelligent Announcement Tests', () {
    test('Medication phrasings generate natural "take your [meds]" phrasing', () {
      expect(
        TTSService.formatAnnouncement('Medicine'),
        equals("It's time to take your Medicine."),
      );
      expect(
        TTSService.formatAnnouncement('take medicine'),
        equals("It's time to take your medicine."),
      );
      expect(
        TTSService.formatAnnouncement('take my vitamins'),
        equals("It's time to take your vitamins."),
      );
      expect(
        TTSService.formatAnnouncement('blood pressure pills'),
        equals("It's time to take your blood pressure pills."),
      );
      expect(
        TTSService.formatAnnouncement('Evening insulin dose'),
        equals("It's time to take your Evening insulin dose."),
      );
    });

    test('Hydration phrasings generate direct "drink water" phrasing', () {
      expect(
        TTSService.formatAnnouncement('water'),
        equals("It's time to drink water."),
      );
      expect(
        TTSService.formatAnnouncement('drink water'),
        equals("It's time to drink water."),
      );
      expect(
        TTSService.formatAnnouncement('hydrate'),
        equals("It's time to drink water."),
      );
      expect(
        TTSService.formatAnnouncement('drink green tea'),
        equals("It's time to drink green tea."),
      );
    });

    test('Meal phrasings generate natural "time for [meal]" phrasing', () {
      expect(
        TTSService.formatAnnouncement('lunch'),
        equals("It's time for lunch."),
      );
      expect(
        TTSService.formatAnnouncement('dinner'),
        equals("It's time for dinner."),
      );
      expect(
        TTSService.formatAnnouncement('breakfast'),
        equals("It's time for breakfast."),
      );
      expect(
        TTSService.formatAnnouncement('afternoon snack'),
        equals("It's time for afternoon snack."),
      );
    });

    test('Appointments and meetings generate "time for your [event]" phrasing', () {
      expect(
        TTSService.formatAnnouncement('Doctor appointment'),
        equals("It's time for your Doctor appointment."),
      );
      expect(
        TTSService.formatAnnouncement('Meeting with team'),
        equals("It's time for your Meeting with team."),
      );
      expect(
        TTSService.formatAnnouncement('Dentist consultation'),
        equals("It's time for your Dentist consultation."),
      );
      expect(
        TTSService.formatAnnouncement('Join project standup'),
        equals("It's time to Join project standup."),
      );
    });

    test('Fitness items generate active exercise phrasing', () {
      expect(
        TTSService.formatAnnouncement('gym'),
        equals("It's time to hit the gym."),
      );
      expect(
        TTSService.formatAnnouncement('workout'),
        equals("It's time for your workout."),
      );
      expect(
        TTSService.formatAnnouncement('yoga'),
        equals("It's time for yoga."),
      );
      expect(
        TTSService.formatAnnouncement('run 5 miles'),
        equals("It's time to run 5 miles."),
      );
    });

    test('Communication reminders generate natural verb phrases and normalize pronouns', () {
      expect(
        TTSService.formatAnnouncement('call mom'),
        equals("It's time to call mom."),
      );
      expect(
        TTSService.formatAnnouncement('call my mom'),
        equals("It's time to call your mom."),
      );
      expect(
        TTSService.formatAnnouncement('email the manager'),
        equals("It's time to email the manager."),
      );
    });

    test('Finances and bills generate "time to pay" phrasing', () {
      expect(
        TTSService.formatAnnouncement('Electricity bill'),
        equals("It's time to pay the Electricity bill."),
      );
      expect(
        TTSService.formatAnnouncement('Pay rent'),
        equals("It's time to Pay rent."),
      );
      expect(
        TTSService.formatAnnouncement('my apartment rent'),
        equals("It's time to pay your apartment rent."),
      );
    });

    test('Action verbs generate direct "It\'s time to [verb]" phrasing', () {
      expect(
        TTSService.formatAnnouncement('Buy groceries'),
        equals("It's time to Buy groceries."),
      );
      expect(
        TTSService.formatAnnouncement('Read chapter 4'),
        equals("It's time to Read chapter 4."),
      );
      expect(
        TTSService.formatAnnouncement('submit assignment'),
        equals("It's time to submit assignment."),
      );
    });

    test('Strips voice dictation prefixes cleanly', () {
      expect(
        TTSService.formatAnnouncement('Remind me to take medicine'),
        equals("It's time to take your medicine."),
      );
      expect(
        TTSService.formatAnnouncement('Reminder for doctor appointment'),
        equals("It's time for your doctor appointment."),
      );
      expect(
        TTSService.formatAnnouncement('Remember to drink water!'),
        equals("It's time to drink water."),
      );
      expect(
        TTSService.formatAnnouncement('It\'s time to call dad'),
        equals("It's time to call dad."),
      );
    });

    test('Appends concise notes smoothly', () {
      expect(
        TTSService.formatAnnouncement('Medicine', notes: 'Take 2 pills after food'),
        equals("It's time to take your Medicine. Take 2 pills after food."),
      );
      expect(
        TTSService.formatAnnouncement('Team standup', notes: 'Bring progress report'),
        equals("It's time for your Team standup. Bring progress report."),
      );
    });
  });
}
