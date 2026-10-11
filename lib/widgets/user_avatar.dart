import 'dart:io';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final String? imagePath;
  final String initial;
  final VoidCallback? onTap;
  final bool showCameraBadge;
  final IconData badgeIcon;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    this.radius = 28,
    this.imagePath,
    required this.initial,
    this.onTap,
    this.showCameraBadge = false,
    this.badgeIcon = Icons.camera_alt_rounded,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primary(isDark);
    final size = radius * 2;
    final hasValidImage = imagePath != null &&
        imagePath!.trim().isNotEmpty &&
        File(imagePath!.trim()).existsSync();

    Widget avatarContent;

    if (hasValidImage) {
      avatarContent = ClipOval(
        child: Image.file(
          File(imagePath!.trim()),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _buildFallback(size, primaryColor, isDark),
        ),
      );
    } else {
      avatarContent = _buildFallback(size, primaryColor, isDark);
    }

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ??
              (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: avatarContent,
    );

    if (!showCameraBadge && onTap == null) {
      return avatar;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (showCameraBadge)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  badgeIcon,
                  size: (radius * 0.45).clamp(12.0, 20.0),
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback(double size, Color primaryColor, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.signature(isDark),
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: TextStyle(
            fontSize: radius * 0.75,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF262A23),
          ),
        ),
      ),
    );
  }
}
