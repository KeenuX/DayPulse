import React from 'react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { ProductivityCalculator } from '../../core/utilities/productivityCalculator';
import { StreakHeroCard } from './StreakHeroCard';
import { ProductivityScoreCard } from './ProductivityScoreCard';
import { AnnualHeatmapCard } from './AnnualHeatmapCard';
import { DailyCompletedCard } from './DailyCompletedCard';
import { CategoryDonutCard } from './CategoryDonutCard';
import { FocusMetricsCard } from './FocusMetricsCard';
import { Next7DaysTasksCard } from './Next7DaysTasksCard';
import { User, Sparkles, HelpCircle } from 'lucide-react';

interface ProgressPageProps {
  onSelectTask?: (taskId: string) => void;
  onEditTask?: (taskId: string) => void;
  onRescheduleTask?: (taskId: string) => void;
}

export const ProgressPage: React.FC<ProgressPageProps> = ({
  onSelectTask,
  onEditTask,
  onRescheduleTask,
}) => {
  const { tasks, occurrences, preferences } = useDayPulseData();
  const streakData = ProductivityCalculator.calculateStreaks(tasks, occurrences);
  const now = new Date();
  const todayStr = AppDateUtils.toIsoDate(now);

  // 1. Completed top-level tasks: regular completed + recurring completed occurrences
  const regularCompleted = tasks.filter(t => !t.parentId && t.repeatRule === 'none' && t.completed).length;
  const recurringCompletedOccurrences = occurrences.filter(o => o.completed && !o.isSkipped).length;
  const totalCompletedCount = regularCompleted + recurringCompletedOccurrences;

  // 2. Pending top-level tasks: regular pending + today's uncompleted recurring tasks
  const regularPending = tasks.filter(t => !t.parentId && t.repeatRule === 'none' && !t.completed).length;
  const todayRecurringPending = tasks
    .filter(t => !t.parentId && t.repeatRule !== 'none' && AppDateUtils.isOccurringOnDate(t, now))
    .filter(t => {
      const occ = occurrences.find(o => o.taskId === t.id && o.date === todayStr);
      return !occ || !occ.completed;
    }).length;
  const totalPendingCount = regularPending + todayRecurringPending;

  const currentStreak = streakData.currentStreak > 0 ? streakData.currentStreak : 1;

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-24 md:pb-12 animate-fade-in">
      {/* 1. Profile Header */}
      <div className="flex items-center gap-3.5 p-1">
        <div className="w-12 h-12 rounded-full bg-slate-200 dark:bg-surface-dark-variant flex items-center justify-center text-slate-500 dark:text-slate-400 font-bold shadow-inner">
          <User className="w-6 h-6" />
        </div>
        <div>
          <h2 className="text-xl font-bold text-slate-900 dark:text-white tracking-tight">
            Kept to your plan for {currentStreak} day{currentStreak > 1 ? 's' : ''}!
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            {preferences?.userName || 'DayPulse User'} · Local & Private Offline Dashboard
          </p>
        </div>
      </div>

      {/* 2. Productivity Hub Banner */}
      <div className="rounded-2xl bg-gradient-to-r from-brand-500 via-indigo-500 to-purple-500 p-4 text-white flex items-center justify-between shadow-md shadow-brand-500/20">
        <div className="font-bold text-sm sm:text-base">Productivity Dashboard</div>
        <div className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-white text-brand-600 font-bold text-xs shadow-sm">
          <Sparkles className="w-3.5 h-3.5 fill-brand-600" />
          <span>100% Free</span>
        </div>
      </div>

      {/* 3. 2-Column Summary Cards Row */}
      <div className="grid grid-cols-2 gap-4">
        {/* Completed Tasks */}
        <div className="rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border p-5 text-center shadow-sm">
          <div className="text-xs font-semibold text-slate-400">Completed Tasks</div>
          <div className="text-3xl sm:text-4xl font-black text-slate-900 dark:text-white mt-1.5">
            {totalCompletedCount}
          </div>
        </div>

        {/* Pending Tasks */}
        <div className="rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border p-5 text-center shadow-sm">
          <div className="flex items-center justify-center gap-1 text-xs font-semibold text-slate-400">
            <span>Pending Tasks</span>
            <HelpCircle className="w-3.5 h-3.5 text-slate-400" />
          </div>
          <div className="text-3xl sm:text-4xl font-black text-slate-900 dark:text-white mt-1.5">
            {totalPendingCount}
          </div>
        </div>
      </div>

      {/* Streak Hero Card */}
      <StreakHeroCard />

      {/* Productivity Score Breakdown */}
      <ProductivityScoreCard />

      {/* 53-Week Annual Heatmap */}
      <AnnualHeatmapCard />

      {/* Daily & Category Visualizations */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <DailyCompletedCard />
        <CategoryDonutCard />
      </div>

      {/* Weekly Focus Time Metrics */}
      <FocusMetricsCard />

      {/* Tasks in Next 7 Days (Compact & Expandable) */}
      <Next7DaysTasksCard
        onSelectTask={onSelectTask}
        onEditTask={onEditTask}
        onRescheduleTask={onRescheduleTask}
      />
    </div>
  );
};
