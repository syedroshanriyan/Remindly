import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:remindly/providers/settings_provider.dart';
import 'package:remindly/screens/splash_screen.dart';
import 'package:remindly/widgets/animated_bell.dart';

void main() {
  group('SplashScreen and Bell Animation Tests', () {
    testWidgets('SplashScreen renders animated bell, title, and tagline', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Verify AnimatedBell is present
      expect(find.byType(AnimatedBell), findsOneWidget);

      // Verify brand title and tagline
      expect(find.text('Remindly'), findsOneWidget);
      expect(find.text('Never miss what matters'), findsOneWidget);

      // Advance animation partially (through pulse, outline, bell appearance)
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(AnimatedBell), findsOneWidget);

      // Advance animation through bell ringing and text entrance
      await tester.pump(const Duration(milliseconds: 2000));
      expect(find.text('Remindly'), findsOneWidget);

      // Advance to completion and transition
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping on SplashScreen skips to navigation transition', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);

      // Tap to skip
      await tester.tap(find.byType(SplashScreen));
      await tester.pumpAndSettle();

      // Navigation has occurred, SplashScreen is replaced
      expect(find.byType(SplashScreen), findsNothing);
    });
  });
}
