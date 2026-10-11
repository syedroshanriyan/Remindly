import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_feedback.dart';
import '../providers/settings_provider.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late String _gender;
  String? _selectedImagePath;

  final List<String> _genders = [
    'Prefer not to say',
    'Male',
    'Female',
    'Non-Binary',
  ];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _nameController = TextEditingController(text: settings.rawUserName);
    _emailController = TextEditingController(text: settings.userEmail);
    _phoneController = TextEditingController(text: settings.userPhone);
    _dobController = TextEditingController(text: settings.userDob);
    _gender = settings.userGender;
    _selectedImagePath = settings.profileImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        setState(() {
          _selectedImagePath = result.files.single.path!;
        });
        if (mounted) {
          context
              .read<SettingsProvider>()
              .setProfileImage(result.files.single.path!);
          AppFeedback.showSuccess(context, 'Profile photo updated');
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not select image');
      }
    }
  }

  void _removeProfileImage() {
    setState(() {
      _selectedImagePath = '';
    });
    context.read<SettingsProvider>().removeProfileImage();
    AppFeedback.showInfo(context, 'Profile photo removed');
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 20));
    try {
      if (_dobController.text.isNotEmpty) {
        initial = DateFormat('yyyy-MM-dd').parse(_dobController.text);
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppFeedback.showError(context, 'Please enter your name');
      return;
    }

    final settings = context.read<SettingsProvider>();
    settings.saveProfile(
      name: name,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _gender,
      profileImagePath: _selectedImagePath,
    );

    FocusScope.of(context).unfocus();
    AppFeedback.showSuccess(context, 'Profile saved');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  UserAvatar(
                    radius: 54,
                    imagePath: _selectedImagePath ?? settings.profileImagePath,
                    initial: settings.userInitial,
                    showCameraBadge: true,
                    onTap: _pickProfileImage,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        icon:
                            const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Change Photo'),
                        onPressed: _pickProfileImage,
                      ),
                      if ((_selectedImagePath != null &&
                              _selectedImagePath!.isNotEmpty) ||
                          settings.profileImagePath.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.error),
                          label: const Text('Remove',
                              style: TextStyle(color: AppColors.error)),
                          onPressed: _removeProfileImage,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form Fields Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Information',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Name
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth
                  TextField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: _selectDateOfBirth,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: Icon(Icons.cake_outlined),
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Gender
                  const Text(
                    'Gender',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.darkTextSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _genders.map((g) {
                      final selected = _gender == g;
                      return ChoiceChip(
                        label: Text(g),
                        selected: selected,
                        selectedColor:
                            AppColors.primary(isDark).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selected ? AppColors.primary(isDark) : null,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        onSelected: (_) => setState(() => _gender = g),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Privacy Guarantee Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded,
                      color: AppColors.success, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('100% Private & Offline',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          'Your photo and personal details remain securely on this device only.',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Save Button
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(isDark),
                foregroundColor:
                    isDark ? AppColors.darkOnPrimary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Profile Changes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
