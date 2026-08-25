class UserSettings {
  final String themeMode; // 'system', 'light', 'dark'
  final int streakThreshold; // e.g. 70
  final bool notificationsEnabled;
  final int defaultReminderOffsetMinutes;
  final bool hasCompletedOnboarding;

  const UserSettings({
    required this.themeMode,
    required this.streakThreshold,
    required this.notificationsEnabled,
    required this.defaultReminderOffsetMinutes,
    required this.hasCompletedOnboarding,
  });
}