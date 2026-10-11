import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class VoiceInputButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  final double size;

  const VoiceInputButton({
    super.key,
    required this.isListening,
    required this.onTap,
    this.size = 64.0,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isListening) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isListening)
              Transform.scale(
                scale: _rippleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error
                        .withValues(alpha: (1.0 - _controller.value) * 0.3),
                  ),
                ),
              ),
            Transform.scale(
              scale: widget.isListening ? _scaleAnimation.value : 1.0,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.isListening
                      ? null
                      : AppGradients.signature(isDark),
                  color: widget.isListening ? AppColors.error : null,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isListening
                              ? AppColors.error
                              : AppColors.champagne(isDark))
                          .withValues(alpha: isDark ? 0.35 : 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onTap,
                    child: Icon(
                      widget.isListening ? Icons.mic : Icons.mic_none,
                      color: widget.isListening
                          ? Colors.white
                          : const Color(0xFF262A23),
                      size: widget.size * 0.48,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
