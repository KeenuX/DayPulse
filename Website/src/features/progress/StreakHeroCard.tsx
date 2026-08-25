import React from 'react';
import { Flame, Trophy, CheckCircle, Calendar, Sparkles } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { ProductivityCalculator } from '../../core/utilities/productivityCalculator';

export const StreakHeroCard: React.FC = () => {
  const { tasks, occurrences } = useDayPulseData();
  const streakData = ProductivityCalculator.calculateStreaks(tasks, occurrences);

  return (
    <div className="rounded-3xl bg-gradient-to-tr from-amber-500/10 via-brand-500/10 to-indigo-500/10 border border-amber-500/20 p-5 sm:p-6 shadow-sm">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2 text-amber-500 font-bold text-xs uppercase tracking-wider">
          <Flame className="w-4 h-4 fill-amber-500" />
          <span>Consistency & Streaks</span>
        </div>

        {streakData.isTodaySuccessful && (
          <span className="px-2.5 py-0.5 rounded-full bg-emerald-500/15 text-emerald-500 font-bold text-xs">
            Goal Met Today 🎉
          </span>
        )}
      </div>

      <div className="grid grid-cols-3 gap-3 sm:gap-4 mt-4">
        {/* Current Streak */}
        <div className="p-4 rounded-2xl bg-white/70 dark:bg-surface-dark/70 backdrop-blur-md border border-slate-200/60 dark:border-surface-dark-border">
          <div className="flex items-center gap-1.5 text-xs text-slate-500 dark:text-slate-400 font-medium">
            <Flame className="w-3.5 h-3.5 text-amber-500 fill-amber-500" />
            <span>Current Streak</span>
          </div>
          <div className="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-1">
            {streakData.currentStreak} <span className="text-xs font-semibold text-slate-400">days</span>
          </div>
        </div>

        {/* Longest Streak */}
        <div className="p-4 rounded-2xl bg-white/70 dark:bg-surface-dark/70 backdrop-blur-md border border-slate-200/60 dark:border-surface-dark-border">
          <div className="flex items-center gap-1.5 text-xs text-slate-500 dark:text-slate-400 font-medium">
            <Trophy className="w-3.5 h-3.5 text-indigo-500" />
            <span>Best Streak</span>
          </div>
          <div className="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-1">
            {streakData.longestStreak} <span className="text-xs font-semibold text-slate-400">days</span>
          </div>
        </div>

        {/* Total Productive Days */}
        <div className="p-4 rounded-2xl bg-white/70 dark:bg-surface-dark/70 backdrop-blur-md border border-slate-200/60 dark:border-surface-dark-border">
          <div className="flex items-center gap-1.5 text-xs text-slate-500 dark:text-slate-400 font-medium">
            <CheckCircle className="w-3.5 h-3.5 text-emerald-500" />
            <span>Success Days</span>
          </div>
          <div className="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-1">
            {streakData.totalSuccessfulDays} <span className="text-xs font-semibold text-slate-400">days</span>
          </div>
        </div>
      </div>
    </div>
  );
};
