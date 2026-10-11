import 'dart:math';
import 'package:flutter/material.dart';
import 'bell_outline_painter.dart';
import '../core/theme/app_colors.dart';

class AnimatedBell extends StatelessWidget {
  final Animation<double> outlineProgress;
  final Animation<double> bellOpacity;
  final Animation<double> ringAnimation;
  final Animation<double> checkScale;
  final Animation<double> sparkleOpacity;

  const AnimatedBell({
    super.key,
    required this.outlineProgress,
    required this.bellOpacity,
    required this.ringAnimation,
    required this.checkScale,
    required this.sparkleOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// STEP 2: Bell outline draws
          AnimatedBuilder(
            animation: outlineProgress,
            builder: (context, child) {
              return Opacity(
                opacity: bellOpacity.value < 0.05 ? 1 : 0,
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: CustomPaint(
                    painter: BellOutlinePainter(
                      progress: outlineProgress.value,
                    ),
                  ),
                ),
              );
            },
          ),

          /// STEP 3 onwards: Actual Remindly icon with ringing rotation
          AnimatedBuilder(
            animation: Listenable.merge([
              bellOpacity,
              ringAnimation,
            ]),
            builder: (context, child) {
              return Opacity(
                opacity: bellOpacity.value,
                child: Transform.rotate(
                  angle: sin(ringAnimation.value * 4 * pi) * 0.18,
                  child: Transform.scale(
                    scale: bellOpacity.value,
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: Image.asset(
                        'assets/icons/remindly_icon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.notifications_active_rounded,
                          size: 90,
                          color: AppColors.lightChampagne,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
