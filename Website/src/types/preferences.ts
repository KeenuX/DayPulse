export type ThemeMode = 'light' | 'dark' | 'system';

export interface UserPreferences {
  themeMode: ThemeMode;
  soundEnabled: boolean;
  notificationsEnabled: boolean;
  streakThreshold: number; // default 70
  hasCompletedOnboarding: boolean;
  userName?: string;
  avatarUrl?: string;
}
