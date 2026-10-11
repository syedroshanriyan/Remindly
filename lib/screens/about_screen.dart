import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/design_tokens.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Remindly'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.space24),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: DesignTokens.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icons/remindly_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space16),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: DesignTokens.space8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightPrimary.withValues(alpha: 0.1),
                    borderRadius: DesignTokens.borderRadiusSmall,
                  ),
                  child: Text(
                    'Version ${AppConstants.appVersion}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space32),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Smart Personal Diary + Intelligent Reminder',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Remindly is engineered with a strict offline-first design philosophy. It pairs high-reliability scheduled alarms and notifications with an intelligent, private journal that helps you reflect on your day and keep your schedule on track.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.source_outlined),
              title: const Text('Open Source Licenses'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: AppConstants.appVersion,
                  applicationIcon: SizedBox(
                    width: 48,
                    height: 48,
                    child: Image.asset('assets/icons/remindly_icon.png'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
