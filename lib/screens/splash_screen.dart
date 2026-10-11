import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';
import '../widgets/animated_bell.dart';
import 'main_navigation_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late Animation<double> outlineProgress;
  late Animation<double> bellOpacity;
  late Animation<double> ringAnimation;
  late Animation<double> checkScale;
  late Animation<double> sparkleOpacity;
  late Animation<double> textOpacity;
  late Animation<Offset> textSlide;
  late Animation<double> pulseScale;
  late Animation<double> pulseOpacity;

  @override
  void initState() {
    super.initState();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    pulseScale = Tween<double>(
      begin: 0.0,
      end: 3.0,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.00, 0.15, curve: Curves.easeOut),
      ),
    );

    pulseOpacity = Tween<double>(
      begin: 0.40,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.00, 0.15),
      ),
    );

    outlineProgress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.10, 0.30, curve: Curves.easeInOut),
      ),
    );

    bellOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.25, 0.40),
      ),
    );

    ringAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.40, 0.65, curve: Curves.easeInOut),
      ),
    );

    checkScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.60, 0.75, curve: Curves.elasticOut),
      ),
    );

    sparkleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.70, 0.82),
      ),
    );

    textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.72, 0.90),
      ),
    );

    textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.72, 0.90, curve: Curves.easeOut),
      ),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    try {
      await _masterController.forward().orCancel;
    } on TickerCanceled {
      return;
    }

    if (!mounted) return;

    _navigateToNext();
  }

  void _navigateToNext() {
    if (!mounted) return;

    final settings = context.read<SettingsProvider>();
    final hasProfile =
        settings.hasCompletedProfile && settings.hasSeenOnboarding;

    final targetScreen =
        hasProfile ? const MainNavigationScreen() : const OnboardingScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_masterController.isAnimating) {
            _masterController.stop();
            _navigateToNext();
          }
        },
        child: AnimatedBuilder(
          animation: _masterController,
          builder: (context, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial expanding pulse with Champagne Gold + Soft Sage gradient
                      Opacity(
                        opacity: pulseOpacity.value,
                        child: Transform.scale(
                          scale: pulseScale.value,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppGradients.signature(isDark),
                            ),
                          ),
                        ),
                      ),

                      // Bell animation: Outline drawing -> Icon reveal -> Ringing rotation
                      AnimatedBell(
                        outlineProgress: outlineProgress,
                        bellOpacity: bellOpacity,
                        ringAnimation: ringAnimation,
                        checkScale: checkScale,
                        sparkleOpacity: sparkleOpacity,
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // Brand name and tagline transitions
                  FadeTransition(
                    opacity: textOpacity,
                    child: SlideTransition(
                      position: textSlide,
                      child: Column(
                        children: [
                          Text(
                            'Remindly',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(isDark),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Never miss what matters',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
