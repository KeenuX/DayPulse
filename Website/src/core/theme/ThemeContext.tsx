import React, { createContext, useContext, useEffect, useState } from 'react';
import { ThemeMode } from '../../types/preferences';
import { db } from '../db/database';

interface ThemeContextType {
  themeMode: ThemeMode;
  isDark: boolean;
  setThemeMode: (mode: ThemeMode) => Promise<void>;
  toggleTheme: () => Promise<void>;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [themeMode, setThemeModeState] = useState<ThemeMode>('dark');
  const [isDark, setIsDark] = useState<boolean>(true);

  useEffect(() => {
    // Load from DB or default
    db.preferences.get('user_preferences').then(pref => {
      if (pref?.themeMode) {
        setThemeModeState(pref.themeMode);
      }
    });
  }, []);

  useEffect(() => {
    const updateEffectiveTheme = () => {
      let dark = true;
      if (themeMode === 'system') {
        dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      } else {
        dark = themeMode === 'dark';
      }
      setIsDark(dark);

      if (dark) {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
    };

    updateEffectiveTheme();

    if (themeMode === 'system') {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
      const listener = () => updateEffectiveTheme();
      mediaQuery.addEventListener('change', listener);
      return () => mediaQuery.removeEventListener('change', listener);
    }
  }, [themeMode]);

  const setThemeMode = async (mode: ThemeMode) => {
    setThemeModeState(mode);
    const existing = await db.preferences.get('user_preferences');
    if (existing) {
      await db.preferences.update('user_preferences', { themeMode: mode });
    } else {
      await db.preferences.put({
        id: 'user_preferences',
        themeMode: mode,
        soundEnabled: true,
        notificationsEnabled: false,
        streakThreshold: 70,
        hasCompletedOnboarding: true,
      });
    }
  };

  const toggleTheme = async () => {
    const nextMode: ThemeMode = isDark ? 'light' : 'dark';
    await setThemeMode(nextMode);
  };

  return (
    <ThemeContext.Provider value={{ themeMode, isDark, setThemeMode, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = (): ThemeContextType => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
};
