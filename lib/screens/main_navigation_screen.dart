import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/design_tokens.dart';
import '../widgets/bottom_nav_scope.dart';
import 'diary_screen.dart';
import 'home_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';
import 'voice_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DiaryScreen(),
    RemindersScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomNavScope(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          height: 60,
          width: 60,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.signature(isDark),
            boxShadow: DesignTokens.floatingShadow(
                AppColors.champagne(isDark), isDark),
          ),
          child: FloatingActionButton(
            heroTag: 'main_voice_fab',
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF262A23),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VoiceScreen()),
              );
            },
            child: const Icon(Icons.mic_rounded, size: 28),
          ),
        ),
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              padding: EdgeInsets.zero,
              color: AppColors.glassSurface(isDark),
              elevation: 0,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.glassBorder(isDark),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: _buildNavItem(0, Icons.home_outlined,
                            Icons.home_rounded, 'Home', isDark),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildNavItem(1, Icons.auto_stories_outlined,
                            Icons.auto_stories_rounded, 'Diary', isDark),
                      ),
                    ),
                    const SizedBox(
                        width:
                            60), // Symmetrical gap for central 60px microphone FAB
                    Expanded(
                      child: Center(
                        child: _buildNavItem(2, Icons.alarm_outlined,
                            Icons.alarm_rounded, 'Reminders', isDark),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildNavItem(3, Icons.settings_outlined,
                            Icons.settings_rounded, 'Settings', isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon,
      String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeColor = AppColors.primary(isDark);
    final inactiveColor = AppColors.textSecondary(isDark);
    final color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 23),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
