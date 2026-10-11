import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class BellOutlinePainter extends CustomPainter {
  final double progress;

  BellOutlinePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = AppGradients.premiumGoldSage.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width * 0.28, height * 0.42);

    path.quadraticBezierTo(
      width * 0.28,
      height * 0.18,
      width * 0.50,
      height * 0.14,
    );

    path.quadraticBezierTo(
      width * 0.72,
      height * 0.18,
      width * 0.72,
      height * 0.42,
    );

    path.lineTo(width * 0.82, height * 0.76);

    path.quadraticBezierTo(
      width * 0.50,
      height * 0.84,
      width * 0.18,
      height * 0.76,
    );

    path.close();

    path.moveTo(width * 0.44, height * 0.84);
    path.quadraticBezierTo(
      width * 0.50,
      height * 0.94,
      width * 0.56,
      height * 0.84,
    );

    path.moveTo(width * 0.44, height * 0.12);
    path.quadraticBezierTo(
      width * 0.50,
      height * 0.02,
      width * 0.56,
      height * 0.12,
    );

    for (final metric in path.computeMetrics()) {
      final extractPath = metric.extractPath(
        0,
        metric.length * progress,
      );

      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BellOutlinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
