import React from 'react';
import { Flame, Sparkles, CheckCircle2, ListTodo, Clock } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { ProductivityCalculator } from '../../core/utilities/productivityCalculator';
import { formatDurationMinutes } from '../../core/utilities/durationFormatter';

interface TodayHeaderCardProps {
  onOpenDailySummary: () => void;
}

export const TodayHeaderCard: React.FC<TodayHeaderCardProps> = ({
  onOpenDailySummary,
}) => {
  const { tasks, occurrences } = useDayPulseData();

  const now = new Date();
  const todayStr = AppDateUtils.toIsoDate(now);
  const todayFormatted = AppDateUtils.formatDisplayDate(now);

  // Get all top-level tasks scheduled for today
  const todayTasks = tasks.filter(t => t.date === todayStr && !t.parentId);
  const totalTasks = todayTasks.length;
  const completedTasks = todayTasks.filter(t => t.completed).length;
  const percentage = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

  const streakData = ProductivityCalculator.calculateStreaks(tasks, occurrences);
  const totalFocusMinutes = todayTasks
    .filter(t => t.completed && t.durationMinutes)
    .reduce((acc, t) => acc + (t.durationMinutes || 0), 0);

  // SVG Circular progress constants
  const radius = 32;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (percentage / 100) * circumference;

  return (
    <div className="relative overflow-hidden rounded-3xl bg-gradient-to-tr from-brand-600 via-brand-500 to-indigo-600 text-white p-6 shadow-xl shadow-brand-500/20">
      {/* Background soft glow circles */}
      <div className="absolute -top-12 -right-12 w-48 h-48 rounded-full bg-white/10 blur-2xl pointer-events-none" />
      <div className="absolute -bottom-12 -left-12 w-48 h-48 rounded-full bg-indigo-900/20 blur-2xl pointer-events-none" />

      {/* Top row: Date & Streak + Review */}
      <div className="relative z-10 flex items-start justify-between">
        <div>
          <span className="text-xs font-semibold text-white/80 uppercase tracking-wider">{todayFormatted}</span>
          <h2 className="text-2xl font-black tracking-tight mt-0.5">Today's Pulse</h2>
        </div>

        <div className="flex items-center gap-2">
          {/* Streak Pill */}
          {streakData.currentStreak > 0 && (
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-2xl bg-white/20 backdrop-blur-md border border-white/25 text-white text-xs font-bold shadow-sm">
              <Flame className="w-4 h-4 text-amber-300 fill-amber-300 animate-pulse" />
              <span>{streakData.currentStreak}d Streak</span>
            </div>
          )}

          {/* Daily Review Button */}
          <button
            onClick={onOpenDailySummary}
            className="p-2 rounded-2xl bg-white/15 hover:bg-white/25 backdrop-blur-md border border-white/20 text-white transition-colors"
            title="Daily Summary / Review"
          >
            <Sparkles className="w-4 h-4 text-amber-200" />
          </button>
        </div>
      </div>

      {/* Center Metrics: Circular Progress Ring & Summary Numbers */}
      <div className="relative z-10 mt-6 flex items-center gap-6">
        {/* Animated Circular Ring */}
        <div className="relative w-20 h-20 flex-shrink-0 flex items-center justify-center">
          <svg className="w-full h-full transform -rotate-90" viewBox="0 0 80 80">
            <circle
              cx="40"
              cy="40"
              r={radius}
              stroke="currentColor"
              strokeWidth="7"
              className="text-white/20"
              fill="transparent"
            />
            <circle
              cx="40"
              cy="40"
              r={radius}
              stroke="#FFFFFF"
              strokeWidth="7"
              strokeDasharray={circumference}
              strokeDashoffset={strokeDashoffset}
              strokeLinecap="round"
              fill="transparent"
              className="transition-all duration-700 ease-out"
            />
          </svg>
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className="text-base font-black tracking-tight">{percentage}%</span>
          </div>
        </div>

        {/* Breakdown Stats */}
        <div className="flex-1 grid grid-cols-2 sm:grid-cols-3 gap-3">
          <div className="p-3 rounded-2xl bg-white/15 backdrop-blur-md border border-white/15">
            <span className="text-[11px] text-white/80 block">Completed</span>
            <span className="text-lg font-black">{completedTasks} / {totalTasks}</span>
          </div>

          <div className="p-3 rounded-2xl bg-white/15 backdrop-blur-md border border-white/15">
            <span className="text-[11px] text-white/80 block">Focus Done</span>
            <span className="text-lg font-black">{formatDurationMinutes(totalFocusMinutes) || '0m'}</span>
          </div>

          <div className="hidden sm:block p-3 rounded-2xl bg-white/15 backdrop-blur-md border border-white/15">
            <span className="text-[11px] text-white/80 block">Pending</span>
            <span className="text-lg font-black">{totalTasks - completedTasks}</span>
          </div>
        </div>
      </div>
    </div>
  );
};
