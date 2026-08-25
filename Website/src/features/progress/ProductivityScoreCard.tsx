import React from 'react';
import { Award, CheckCircle2, Flag, Clock, Zap, Info } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { ProductivityCalculator } from '../../core/utilities/productivityCalculator';

export const ProductivityScoreCard: React.FC = () => {
  const { tasks, occurrences, getTasksForDate } = useDayPulseData();
  const now = new Date();
  const todayTasks = getTasksForDate(now);
  const streakData = ProductivityCalculator.calculateStreaks(tasks, occurrences);
  const scoreData = ProductivityCalculator.calculateScore(todayTasks, streakData.currentStreak);

  return (
    <div className="rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border p-5 sm:p-6 shadow-sm space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Award className="w-4 h-4 text-brand-500" />
          <h3 className="text-base font-bold text-slate-900 dark:text-white">
            Daily Productivity Score
          </h3>
        </div>

        <div className="flex items-baseline gap-1">
          <span className="text-3xl font-black text-brand-600 dark:text-brand-400">{scoreData.totalScore}</span>
          <span className="text-xs font-semibold text-slate-400">/ 100</span>
        </div>
      </div>

      {/* Explanation */}
      <p className="text-xs text-slate-500 dark:text-slate-400 italic">
        "{scoreData.summaryExplanation}"
      </p>

      {/* 4 Pillars Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-2">
        {/* Completion */}
        <div className="p-3 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-100 dark:border-surface-dark-border space-y-1">
          <div className="flex items-center justify-between text-[11px] font-semibold text-slate-400">
            <span className="flex items-center gap-1">
              <CheckCircle2 className="w-3 h-3 text-emerald-500" />
              <span>Completion</span>
            </span>
            <span className="font-bold text-slate-700 dark:text-slate-200">{scoreData.completionPoints}/40</span>
          </div>
          <div className="w-full h-1.5 rounded-full bg-slate-200 dark:bg-surface-dark-variant overflow-hidden">
            <div
              className="h-full bg-emerald-500 rounded-full"
              style={{ width: `${(scoreData.completionPoints / 40) * 100}%` }}
            />
          </div>
        </div>

        {/* Priority */}
        <div className="p-3 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-100 dark:border-surface-dark-border space-y-1">
          <div className="flex items-center justify-between text-[11px] font-semibold text-slate-400">
            <span className="flex items-center gap-1">
              <Flag className="w-3 h-3 text-rose-500" />
              <span>Priority</span>
            </span>
            <span className="font-bold text-slate-700 dark:text-slate-200">{scoreData.priorityPoints}/30</span>
          </div>
          <div className="w-full h-1.5 rounded-full bg-slate-200 dark:bg-surface-dark-variant overflow-hidden">
            <div
              className="h-full bg-rose-500 rounded-full"
              style={{ width: `${(scoreData.priorityPoints / 30) * 100}%` }}
            />
          </div>
        </div>

        {/* Punctuality */}
        <div className="p-3 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-100 dark:border-surface-dark-border space-y-1">
          <div className="flex items-center justify-between text-[11px] font-semibold text-slate-400">
            <span className="flex items-center gap-1">
              <Clock className="w-3 h-3 text-sky-500" />
              <span>Punctuality</span>
            </span>
            <span className="font-bold text-slate-700 dark:text-slate-200">{scoreData.punctualityPoints}/15</span>
          </div>
          <div className="w-full h-1.5 rounded-full bg-slate-200 dark:bg-surface-dark-variant overflow-hidden">
            <div
              className="h-full bg-sky-500 rounded-full"
              style={{ width: `${(scoreData.punctualityPoints / 15) * 100}%` }}
            />
          </div>
        </div>

        {/* Consistency */}
        <div className="p-3 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-100 dark:border-surface-dark-border space-y-1">
          <div className="flex items-center justify-between text-[11px] font-semibold text-slate-400">
            <span className="flex items-center gap-1">
              <Zap className="w-3 h-3 text-amber-500" />
              <span>Consistency</span>
            </span>
            <span className="font-bold text-slate-700 dark:text-slate-200">{scoreData.consistencyPoints}/15</span>
          </div>
          <div className="w-full h-1.5 rounded-full bg-slate-200 dark:bg-surface-dark-variant overflow-hidden">
            <div
              className="h-full bg-amber-500 rounded-full"
              style={{ width: `${(scoreData.consistencyPoints / 15) * 100}%` }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};
