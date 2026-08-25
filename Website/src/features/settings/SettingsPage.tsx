import React, { useState, useRef } from 'react';
import {
  Sun,
  Moon,
  Laptop,
  Volume2,
  VolumeX,
  Bell,
  Download,
  Upload,
  Trash2,
} from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { useTheme } from '../../core/theme/ThemeContext';
import { notificationService } from '../../core/notifications/notificationService';
import { soundEffects } from '../../core/sound/soundEffects';
import { ThemeMode } from '../../types/preferences';

export const SettingsPage: React.FC = () => {
  const { preferences, updatePreferences, exportBackupJson, importBackupJson, resetAllData } = useDayPulseData();
  const { themeMode, setThemeMode } = useTheme();

  const fileInputRef = useRef<HTMLInputElement>(null);
  const [importStatus, setImportStatus] = useState<{ success?: boolean; message?: string } | null>(null);
  const [showResetConfirm, setShowResetConfirm] = useState(false);

  const handleExport = async () => {
    const jsonString = await exportBackupJson();
    const blob = new Blob([jsonString], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `daypulse_backup_${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async event => {
      const content = event.target?.result as string;
      const res = await importBackupJson(content);
      setImportStatus(res);
      setTimeout(() => setImportStatus(null), 5000);
    };
    reader.readAsText(file);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const handleRequestNotifications = async () => {
    const perm = await notificationService.requestPermission();
    if (perm === 'granted') {
      await updatePreferences({ notificationsEnabled: true });
      notificationService.showNotification('DayPulse Alerts Enabled! 🚀', {
        body: 'You will receive timely task reminders directly in your browser.',
      });
    } else {
      await updatePreferences({ notificationsEnabled: false });
    }
  };

  return (
    <div className="max-w-3xl mx-auto space-y-6 pb-24 md:pb-12 animate-fade-in">
      {/* Header */}
      <div>
        <h2 className="text-2xl font-black text-slate-900 dark:text-white tracking-tight">Settings</h2>
        <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
          Customize theme, audio feedback, backups, and streak thresholds
        </p>
      </div>

      {/* 1. Theme & Appearance */}
      <div className="p-6 rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border shadow-sm space-y-4">
        <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">Appearance</h3>

        <div className="grid grid-cols-3 gap-3">
          {[
            { id: 'light', label: 'Light', icon: Sun },
            { id: 'dark', label: 'Dark', icon: Moon },
            { id: 'system', label: 'System', icon: Laptop },
          ].map(t => {
            const Icon = t.icon;
            const isSelected = themeMode === t.id;
            return (
              <button
                key={t.id}
                onClick={() => setThemeMode(t.id as ThemeMode)}
                className={`p-4 rounded-2xl flex flex-col items-center gap-2 border transition-all ${
                  isSelected
                    ? 'bg-brand-500/10 border-brand-500 text-brand-600 dark:text-brand-400 font-bold shadow-sm'
                    : 'bg-slate-50 dark:bg-surface-dark-subtle border-slate-200/80 dark:border-surface-dark-border text-slate-600 dark:text-slate-300'
                }`}
              >
                <Icon className="w-5 h-5" />
                <span className="text-xs">{t.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* 2. Audio & Notifications */}
      <div className="p-6 rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border shadow-sm space-y-4">
        <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">Audio & Notifications</h3>

        <div className="space-y-3">
          {/* Sound Effects Toggle */}
          <div className="flex items-center justify-between p-3 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-100 dark:border-surface-dark-border">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-brand-500/10 text-brand-500 flex items-center justify-center">
                {preferences.soundEnabled ? <Volume2 className="w-5 h-5" /> : <VolumeX className="w-5 h-5 text-slate-400" />}
              </div>
              <div>
                <span className="text-xs font-bold text-slate-800 dark:text-white">Completion Audio Chimes</span>
                <p className="text-[11px] text-slate-400">Play pleasant sound effects on task completion</p>
              </div>
            </div>

            <button
              onClick={() => {
                const next = !preferences.soundEnabled;
                updatePreferences({ soundEnabled: next });
                if (next) soundEffects.playTaskComplete();
              }}
              className={`w-12 h-6 rounded-full transition-colors relative ${
                preferences.soundEnabled ? 'bg-brand-500' : 'bg-slate-300 dark:bg-surface-dark-variant'
              }`}
            >
              <div
                className={`w-4 h-4 rounded-full bg-white transition-transform absolute top-1 ${
                  preferences.soundEnabled ? 'left-7' : 'left-1'
                }`}
              />
            </button>
          </div>

          {/* Web Notifications */}
          <div className="flex items-center justify-between p-3 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-100 dark:border-surface-dark-border">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-emerald-500/10 text-emerald-500 flex items-center justify-center">
                <Bell className="w-5 h-5" />
              </div>
              <div>
                <span className="text-xs font-bold text-slate-800 dark:text-white">Browser Notifications</span>
                <p className="text-[11px] text-slate-400">Receive reminder alerts for scheduled tasks</p>
              </div>
            </div>

            <button
              onClick={handleRequestNotifications}
              className="px-3 py-1.5 rounded-xl bg-slate-200 dark:bg-surface-dark-variant hover:bg-slate-300 dark:hover:bg-slate-700 text-xs font-bold text-slate-800 dark:text-slate-200 transition-colors"
            >
              {notificationService.getPermission() === 'granted' ? 'Enabled' : 'Request Permission'}
            </button>
          </div>
        </div>
      </div>

      {/* 3. Data Sovereignty & Backups */}
      <div className="p-6 rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border shadow-sm space-y-4">
        <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">Data Management</h3>

        {importStatus && (
          <div
            className={`p-3 rounded-xl text-xs font-semibold ${
              importStatus.success
                ? 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20'
                : 'bg-rose-500/10 text-rose-500 border border-rose-500/20'
            }`}
          >
            {importStatus.message}
          </div>
        )}

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {/* Export JSON */}
          <button
            onClick={handleExport}
            className="flex items-center justify-center gap-2 p-3.5 rounded-2xl bg-slate-100 dark:bg-surface-dark-subtle hover:bg-slate-200 dark:hover:bg-surface-dark-variant border border-slate-200/60 dark:border-surface-dark-border text-xs font-bold text-slate-800 dark:text-slate-200 transition-colors"
          >
            <Download className="w-4 h-4 text-brand-500" />
            <span>Export JSON Backup</span>
          </button>

          {/* Import JSON */}
          <label className="flex items-center justify-center gap-2 p-3.5 rounded-2xl bg-slate-100 dark:bg-surface-dark-subtle hover:bg-slate-200 dark:hover:bg-surface-dark-variant border border-slate-200/60 dark:border-surface-dark-border text-xs font-bold text-slate-800 dark:text-slate-200 cursor-pointer transition-colors">
            <Upload className="w-4 h-4 text-emerald-500" />
            <span>Restore From Backup</span>
            <input
              ref={fileInputRef}
              type="file"
              accept=".json"
              onChange={handleFileChange}
              className="hidden"
            />
          </label>
        </div>

        {/* Clear Database */}
        <div className="pt-2">
          {!showResetConfirm ? (
            <button
              onClick={() => setShowResetConfirm(true)}
              className="flex items-center gap-2 text-xs font-semibold text-rose-500 hover:underline"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Clear All Data and Reset</span>
            </button>
          ) : (
            <div className="p-3.5 rounded-2xl bg-rose-500/10 border border-rose-500/25 space-y-2">
              <span className="text-xs font-bold text-rose-600 dark:text-rose-400">
                Are you sure? This will delete all tasks and custom categories permanently.
              </span>
              <div className="flex gap-2">
                <button
                  onClick={async () => {
                    await resetAllData();
                    setShowResetConfirm(false);
                  }}
                  className="px-3 py-1 rounded-lg bg-rose-500 text-white text-xs font-bold"
                >
                  Yes, Reset Everything
                </button>
                <button
                  onClick={() => setShowResetConfirm(false)}
                  className="px-3 py-1 rounded-lg bg-slate-200 dark:bg-surface-dark-variant text-xs font-semibold"
                >
                  Cancel
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* 4. About & GitHub */}
      <div className="p-6 rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="space-y-1">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded-lg bg-gradient-to-tr from-brand-500 to-indigo-500 flex items-center justify-center text-white text-xs font-bold">
              DP
            </div>
            <span className="text-sm font-bold text-slate-800 dark:text-white">DayPulse Web</span>
            <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-brand-500/10 text-brand-500">v1.0.0</span>
          </div>
          <p className="text-xs text-slate-400">
            Open-source daily planner, 53-week contribution matrix, and focus analytics.
          </p>
        </div>

        <a
          href="https://github.com/KeenuX/DayPulse"
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-2 px-4 py-2 rounded-xl bg-slate-100 dark:bg-surface-dark-subtle hover:bg-slate-200 dark:hover:bg-surface-dark-variant text-slate-800 dark:text-slate-200 text-xs font-bold transition-colors self-start sm:self-auto"
        >
          <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
            <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
          </svg>
          <span>View on GitHub</span>
        </a>
      </div>
    </div>
  );
};
