import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/design_tokens.dart';
import '../providers/app_lock_provider.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isDeviceAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lockProvider = context.read<AppLockProvider>();
      if (lockProvider.isDeviceLock) {
        _triggerDeviceAuth();
      }
    });
  }

  Future<void> _triggerDeviceAuth() async {
    if (_isDeviceAuthenticating) return;
    setState(() {
      _isDeviceAuthenticating = true;
      _errorMessage = null;
    });

    final lockProvider = context.read<AppLockProvider>();
    final success = await lockProvider.authenticateWithDevice();

    if (mounted) {
      setState(() {
        _isDeviceAuthenticating = false;
        if (!success) {
          _errorMessage = 'Authentication failed. Please try again.';
        }
      });
    }
  }

  void _onDigitPressed(String digit) {
    final lockProvider = context.read<AppLockProvider>();
    final expectedLength = lockProvider.configuredPinLength;
    if (_enteredPin.length >= expectedLength) return;

    final newPin = _enteredPin + digit;
    setState(() {
      _enteredPin = newPin;
      _errorMessage = null;
    });

    if (newPin.length == expectedLength) {
      final ok = lockProvider.verifyPassword(newPin);
      if (!ok) {
        setState(() {
          _errorMessage = 'Incorrect PIN code. Please try again.';
          _enteredPin = '';
        });
      }
    }
  }

  void _onSubmitPassword() {
    if (_enteredPin.isEmpty) return;
    final lockProvider = context.read<AppLockProvider>();
    final ok = lockProvider.verifyPassword(_enteredPin);
    if (!ok) {
      setState(() {
        _errorMessage = 'Incorrect PIN code. Please try again.';
        _enteredPin = '';
      });
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockProvider = context.watch<AppLockProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background(isDark),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon / Lock Icon with champagne glow
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.signature(isDark),
                      boxShadow: DesignTokens.floatingShadow(
                        AppColors.champagne(isDark),
                        isDark,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 38,
                      color: Color(0xFF262A23),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Remindly Protected',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDark),
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    lockProvider.isDeviceLock
                        ? 'Unlock using your device biometric or screen lock'
                        : 'Enter your ${lockProvider.configuredPinLength}-digit PIN code to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Device Lock UI
                  if (lockProvider.isDeviceLock) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary(isDark),
                        foregroundColor: isDark ? AppColors.darkOnPrimary : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.fingerprint_rounded, size: 26),
                      label: const Text(
                        'Unlock with Device Lock',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _triggerDeviceAuth,
                    ),

                    if (lockProvider.hasCustomPassword) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // Switch temporarily to custom password entry
                        },
                        child: Text(
                          'Use App PIN Instead',
                          style: TextStyle(
                            color: AppColors.primary(isDark),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Custom Numeric PIN Display (4 or 6 dots)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(lockProvider.configuredPinLength, (index) {
                        final filled = index < _enteredPin.length;
                        return Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? AppColors.primary(isDark)
                                : (isDark ? Colors.white12 : Colors.black12),
                            border: Border.all(
                              color: filled
                                  ? AppColors.primary(isDark)
                                  : AppColors.border(isDark),
                              width: 1.5,
                            ),
                          ),
                        );
                      }),
                    ),

                    if (_enteredPin.length == lockProvider.configuredPinLength) ...[
                      const SizedBox(height: 14),
                      TextButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Unlock', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary(isDark),
                        ),
                        onPressed: _onSubmitPassword,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Numeric Keypad
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Column(
                        children: [
                          _buildKeypadRow(['1', '2', '3'], isDark),
                          const SizedBox(height: 12),
                          _buildKeypadRow(['4', '5', '6'], isDark),
                          const SizedBox(height: 12),
                          _buildKeypadRow(['7', '8', '9'], isDark),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildKeypadButton(
                                icon: Icons.clear_all_rounded,
                                isDark: isDark,
                                onTap: () => setState(() => _enteredPin = ''),
                              ),
                              _buildKeypadDigit('0', isDark),
                              _buildKeypadButton(
                                icon: Icons.backspace_outlined,
                                isDark: isDark,
                                onTap: _onBackspacePressed,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKeypadDigit(d, isDark)).toList(),
    );
  }

  Widget _buildKeypadDigit(String digit, bool isDark) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border.all(color: AppColors.border(isDark)),
          boxShadow: DesignTokens.themeSoftShadow(isDark),
        ),
        child: Text(
          digit,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 22,
          color: AppColors.textSecondary(isDark),
        ),
      ),
    );
  }
}
