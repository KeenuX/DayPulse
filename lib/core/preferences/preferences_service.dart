import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _streakThresholdKey = 'streak_threshold_percentage';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _defaultReminderOffsetKey = 'default_reminder_offset_minutes';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Theme Mode: 'system', 'light', 'dark'
  String get themeMode => _prefs.getString(_themeModeKey) ?? 'system';
  Future<void> setThemeMode(String mode) async => await _prefs.setString(_themeModeKey, mode);

  // Streak Threshold (default: 70%)
  int get streakThreshold => _prefs.getInt(_streakThresholdKey) ?? 70;
  Future<void> setStreakThreshold(int threshold) async => await _prefs.setInt(_streakThresholdKey, threshold);

  // Notifications enabled
  bool get notificationsEnabled => _prefs.getBool(_notificationsEnabledKey) ?? true;
  Future<void> setNotificationsEnabled(bool enabled) async => await _prefs.setBool(_notificationsEnabledKey, enabled);

  // Default reminder offset (in minutes, default: 10m before)
  int get defaultReminderOffsetMinutes => _prefs.getInt(_defaultReminderOffsetKey) ?? 10;
  Future<void> setDefaultReminderOffsetMinutes(int minutes) async => await _prefs.setInt(_defaultReminderOffsetKey, minutes);

  // Onboarding status
  bool get hasCompletedOnboarding => _prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  Future<void> setCompletedOnboarding(bool completed) async => await _prefs.setBool(_hasCompletedOnboardingKey, completed);
}