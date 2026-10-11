import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_feedback.dart';
import '../providers/app_lock_provider.dart';

class AppLockSetupDialog extends StatefulWidget {
  const AppLockSetupDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AppLockSetupDialog(),
    );
  }

  @override
  State<AppLockSetupDialog> createState() => _AppLockSetupDialogState();
}

class _AppLockSetupDialogState extends State<AppLockSetupDialog> {
  int _selectedOption = 0; // 0: Device Lock, 1: Custom Password
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppLockProvider>();
    _selectedOption = provider.isCustomPasswordLock ? 1 : 0;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final provider = context.read<AppLockProvider>();

    if (_selectedOption == 0) {
      // Option 1: Device App Lock
      final canCheck = await provider.canCheckBiometrics();
      if (!mounted) return;

      if (!canCheck) {
        setState(() {
          _error = 'Device lock is not supported or no lock is set on this device.';
        });
        return;
      }

      final success = await provider.authenticateWithDevice();
      if (!mounted) return;

      if (success) {
        provider.enableDeviceLock();
        Navigator.pop(context);
        AppFeedback.showSuccess(context, 'Device app lock enabled');
      } else {
        setState(() {
          _error = 'Device authentication was not completed.';
        });
      }
    } else {
      // Option 2: Custom Numeric PIN (4 or 6 digits only)
      final pin = _passwordController.text.trim();
      final confirm = _confirmController.text.trim();

      if (pin.isEmpty) {
        setState(() => _error = 'Please enter a numeric PIN code.');
        return;
      }
      if (!RegExp(r'^\d+$').hasMatch(pin)) {
        setState(() => _error = 'PIN code must contain numbers only.');
        return;
      }
      if (pin.length != 4 && pin.length != 6) {
        setState(() => _error = 'PIN code must be exactly 4 or 6 digits.');
        return;
      }
      if (pin != confirm) {
        setState(() => _error = 'PIN codes do not match. Please re-enter.');
        return;
      }

      provider.enableCustomPasswordLock(pin);
      Navigator.pop(context);
      AppFeedback.showSuccess(context, 'App PIN lock enabled (${pin.length} digits)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary(isDark).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.security_rounded, color: AppColors.primary(isDark), size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Set App Lock',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose how you would like to secure Remindly on this device:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Option 1: Device App Lock
            InkWell(
              onTap: () => setState(() {
                _selectedOption = 0;
                _error = null;
              }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedOption == 0
                        ? AppColors.primary(isDark)
                        : AppColors.border(isDark),
                    width: _selectedOption == 0 ? 1.8 : 1,
                  ),
                  color: _selectedOption == 0
                      ? AppColors.primary(isDark).withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedOption == 0
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _selectedOption == 0
                          ? AppColors.primary(isDark)
                          : AppColors.textSecondary(isDark),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device App Lock',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Use your device fingerprint, face, or screen passcode',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Option 2: Custom Separate Password
            InkWell(
              onTap: () => setState(() {
                _selectedOption = 1;
                _error = null;
              }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedOption == 1
                        ? AppColors.primary(isDark)
                        : AppColors.border(isDark),
                    width: _selectedOption == 1 ? 1.8 : 1,
                  ),
                  color: _selectedOption == 1
                      ? AppColors.primary(isDark).withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedOption == 1
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _selectedOption == 1
                          ? AppColors.primary(isDark)
                          : AppColors.textSecondary(isDark),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Separate App PIN Lock',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create a 4-digit or 6-digit numeric PIN unique to this app',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // PIN Input Fields when Option 2 is selected
            if (_selectedOption == 1) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: 'New App PIN (4 or 6 digits)',
                  hintText: 'e.g. 1234 or 123456',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmController,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: 'Confirm App PIN (4 or 6 digits)',
                  hintText: 'Re-enter numeric PIN',
                  counterText: '',
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary(isDark),
            foregroundColor: isDark ? AppColors.darkOnPrimary : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _handleSave,
          child: const Text('Enable Lock'),
        ),
      ],
    );
  }
}
