import React from 'react';
import { Search, Sparkles, Sun, Moon, Flame } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { useTheme } from '../../core/theme/ThemeContext';
import { ProductivityCalculator } from '../../core/utilities/productivityCalculator';
import { AppDateUtils } from '../../core/utilities/dateUtils';

interface NavbarProps {
  onOpenCommandPalette: () => void;
  onOpenDailySummary: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  onOpenCommandPalette,
  onOpenDailySummary,
}) => {
  const { tasks, occurrences } = useDayPulseData();
  const { isDark, toggleTheme } = useTheme();

  const streakData = ProductivityCalculator.calculateStreaks(tasks, occurrences);
  const todayFormatted = AppDateUtils.formatDisplayDate(new Date());

  return (
    <header className="sticky top-0 z-20 bg-surface-light/80 dark:bg-surface-dark/80 backdrop-blur-md border-b border-surface-light-border/60 dark:border-surface-dark-border/60 px-4 md:px-8 py-3 flex items-center justify-between">
      {/* Left Mobile Brand / Desktop Title */}
      <div className="flex items-center gap-3">
        <div className="md:hidden flex items-center gap-2">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-brand-500 to-indigo-500 flex items-center justify-center text-white">
            <svg viewBox="0 0 128 128" className="w-5 h-5 text-white" fill="none">
              <path
                d="M 28 66 L 46 66 L 56 42 L 72 88 L 84 56 L 94 66 L 102 66"
                stroke="currentColor"
                strokeWidth="12"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </div>
          <span className="font-bold text-slate-800 dark:text-white text-base">DayPulse</span>
        </div>

        <div className="hidden md:block">
          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Today</span>
          <p className="text-sm font-bold text-slate-700 dark:text-slate-200">{todayFormatted}</p>
        </div>
      </div>

      {/* Right Action Icons */}
      <div className="flex items-center gap-2 md:gap-3">
        {/* Streak on mobile */}
        {streakData.currentStreak > 0 && (
          <div className="md:hidden flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-500 text-xs font-bold">
            <Flame className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
            <span>{streakData.currentStreak}d</span>
          </div>
        )}

        {/* Global Search Trigger */}
        <button
          onClick={onOpenCommandPalette}
          className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-slate-100 dark:bg-surface-dark-subtle hover:bg-slate-200 dark:hover:bg-surface-dark-variant text-slate-500 dark:text-slate-300 text-xs font-medium transition-colors"
          title="Search or commands (Ctrl+K)"
        >
          <Search className="w-4 h-4" />
          <span className="hidden sm:inline">Search (Ctrl+K)</span>
        </button>

        {/* Daily Summary / Review Dialog */}
        <button
          onClick={onOpenDailySummary}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-purple-500/10 hover:bg-purple-500/20 text-purple-600 dark:text-purple-400 text-xs font-semibold transition-colors border border-purple-500/20"
          title="Evening Review & Daily Summary"
        >
          <Sparkles className="w-4 h-4" />
          <span className="hidden sm:inline">Review Day</span>
        </button>

        {/* Theme Toggle (Mobile) */}
        <button
          onClick={toggleTheme}
          className="md:hidden p-2 rounded-xl text-slate-500 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-variant"
          aria-label="Toggle theme"
        >
          {isDark ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4 text-indigo-500" />}
        </button>
      </div>
    </header>
  );
};
