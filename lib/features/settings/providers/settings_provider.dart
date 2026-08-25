import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/core/preferences/preferences_service.dart';
import 'package:daypulse/core/theme/theme_provider.dart';
import 'package:daypulse/features/settings/models/user_settings.dart';

final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return UserSettingsNotifier(prefs);
});

class UserSettingsNotifier extends StateNotifier<UserSettings> {
  final PreferencesService _prefs;

  UserSettingsNotifier(this._prefs)
      : super(UserSettings(
          themeMode: _prefs.themeMode,
          streakThreshold: _prefs.streakThreshold,
          notificationsEnabled: _prefs.notificationsEnabled,
          defaultReminderOffsetMinutes: _prefs.defaultReminderOffsetMinutes,
          hasCompletedOnboarding: _prefs.hasCompletedOnboarding,
        ));

  Future<void> setThemeMode(String mode) async {
    await _prefs.setThemeMode(mode);
    state = UserSettings(
      themeMode: mode,
      streakThreshold: state.streakThreshold,
      notificationsEnabled: state.notificationsEnabled,
      defaultReminderOffsetMinutes: state.defaultReminderOffsetMinutes,
      hasCompletedOnboarding: state.hasCompletedOnboarding,
    );
  }

  Future<void> setStreakThreshold(int threshold) async {
    await _prefs.setStreakThreshold(threshold);
    state = UserSettings(
      themeMode: state.themeMode,
      streakThreshold: threshold,
      notificationsEnabled: state.notificationsEnabled,
      defaultReminderOffsetMinutes: state.defaultReminderOffsetMinutes,
      hasCompletedOnboarding: state.hasCompletedOnboarding,
    );
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setNotificationsEnabled(enabled);
    state = UserSettings(
      themeMode: state.themeMode,
      streakThreshold: state.streakThreshold,
      notificationsEnabled: enabled,
      defaultReminderOffsetMinutes: state.defaultReminderOffsetMinutes,
      hasCompletedOnboarding: state.hasCompletedOnboarding,
    );
  }

  Future<void> setDefaultReminderOffset(int minutes) async {
    await _prefs.setDefaultReminderOffsetMinutes(minutes);
    state = UserSettings(
      themeMode: state.themeMode,
      streakThreshold: state.streakThreshold,
      notificationsEnabled: state.notificationsEnabled,
      defaultReminderOffsetMinutes: minutes,
      hasCompletedOnboarding: state.hasCompletedOnboarding,
    );
  }

  Future<void> setCompletedOnboarding(bool completed) async {
    await _prefs.setCompletedOnboarding(completed);
    state = UserSettings(
      themeMode: state.themeMode,
      streakThreshold: state.streakThreshold,
      notificationsEnabled: state.notificationsEnabled,
      defaultReminderOffsetMinutes: state.defaultReminderOffsetMinutes,
      hasCompletedOnboarding: completed,
    );
  }
}