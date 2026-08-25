import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:daypulse/core/notifications/notification_provider.dart';
import 'package:daypulse/core/routing/app_routes.dart';
import 'package:daypulse/core/theme/theme_provider.dart';
import 'package:daypulse/features/settings/providers/settings_provider.dart';
import 'package:daypulse/features/settings/presentation/widgets/data_export_import_card.dart';
import 'package:daypulse/features/settings/presentation/widgets/streak_config_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final userSettings = ref.watch(userSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Appearance Section
          _SectionHeader(title: 'Appearance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme Mode'),
                  subtitle: Text(
                    currentThemeMode == ThemeMode.system
                        ? 'System Default'
                        : (currentThemeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'),
                  ),
                  trailing: DropdownButton<ThemeMode>(
                    value: currentThemeMode,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                        ref.read(userSettingsProvider.notifier).setThemeMode(
                              mode == ThemeMode.system
                                  ? 'system'
                                  : (mode == ThemeMode.dark ? 'dark' : 'light'),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Categories Management
          _SectionHeader(title: 'Organization'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Manage Categories'),
              subtitle: const Text('Create, edit, reorder, and customize colors & icons'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                context.push(AppRoutes.categories);
              },
            ),
          ),
          const SizedBox(height: 20),

          // 3. Notifications Section
          _SectionHeader(title: 'Notifications & Reminders'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Enable Reminders'),
                  subtitle: const Text('Receive scheduled task alerts on your device'),
                  value: userSettings.notificationsEnabled,
                  onChanged: (val) async {
                    if (val) {
                      final granted = await ref.read(notificationServiceProvider).requestPermissions();
                      if (!granted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enable notification permissions in system settings.')),
                        );
                      }
                    }
                    await ref.read(userSettingsProvider.notifier).setNotificationsEnabled(val);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.alarm_on_rounded),
                  title: const Text('Default Reminder Time'),
                  subtitle: Text('${userSettings.defaultReminderOffsetMinutes} minutes before task'),
                  trailing: DropdownButton<int>(
                    value: userSettings.defaultReminderOffsetMinutes,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('At task time')),
                      DropdownMenuItem(value: 5, child: Text('5 min before')),
                      DropdownMenuItem(value: 10, child: Text('10 min before')),
                      DropdownMenuItem(value: 15, child: Text('15 min before')),
                      DropdownMenuItem(value: 30, child: Text('30 min before')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(userSettingsProvider.notifier).setDefaultReminderOffset(val);
                      }
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications_paused_outlined),
                  title: const Text('Test Notification'),
                  subtitle: const Text('Send an instant test alert to this device'),
                  onTap: () async {
                    final notif = ref.read(notificationServiceProvider);
                    await notif.requestPermissions();
                    await notif.showInstantNotification(
                          title: 'DayPulse Notification Test 🔔',
                          body: 'Notifications & alarms are working perfectly!',
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test notification sent! Check your notification tray.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Productivity Settings
          _SectionHeader(title: 'Productivity Goals'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_fire_department_outlined, color: Colors.orange),
              title: const Text('Streak Goal Threshold'),
              subtitle: Text('${userSettings.streakThreshold}% tasks completed required to count day'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => StreakConfigDialog.show(context, userSettings.streakThreshold),
            ),
          ),
          const SizedBox(height: 20),

          // 5. Data Backup & Restore
          _SectionHeader(title: 'Data & Privacy'),
          const DataExportImportCard(),
          const SizedBox(height: 20),

          // 6. About App
          _SectionHeader(title: 'About DayPulse'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Version'),
                  trailing: Text('1.0.0+1', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.security_rounded),
                  title: Text('Offline-First Architecture'),
                  subtitle: Text('All data is encrypted and stored locally in your SQLite database.'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.tour_outlined),
                  title: const Text('Replay Onboarding'),
                  subtitle: const Text('View the welcome tour and tips'),
                  onTap: () => context.push(AppRoutes.onboarding),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Branding & Version Card
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'DayPulse',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Version 1.0.0 • 100% Free & Local',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}