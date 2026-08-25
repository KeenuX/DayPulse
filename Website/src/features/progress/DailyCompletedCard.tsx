import React, { useState } from 'react';
import { BarChart2, CheckCircle2 } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { startOfWeek, endOfWeek, eachDayOfInterval, format, isSameDay } from 'date-fns';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { CategoryIcon } from '../categories/CategoryIcon';

export const DailyCompletedCard: React.FC = () => {
  const { tasks, occurrences, categoryMap } = useDayPulseData();
  const [selectedDayIdx, setSelectedDayIdx] = useState<number>(new Date().getDay()); // Default to today's weekday

  const now = new Date();
  const weekStart = startOfWeek(now, { weekStartsOn: 0 }); // Sunday
  const weekEnd = endOfWeek(now, { weekStartsOn: 0 });
  const weekDays = eachDayOfInterval({ start: weekStart, end: weekEnd });

  // Compute completions for each weekday
  const weekdayStats = weekDays.map((day, idx) => {
    const dStr = AppDateUtils.toIsoDate(day);
    const dayName = format(day, 'EEE');

    // 1. Regular tasks completed on this date
    const doneRegular = tasks.filter(t => !t.parentId && t.repeatRule === 'none' && t.completed && t.date === dStr);

    // 2. Recurring occurrences completed on this date
    const doneOcc = occurrences.filter(o => o.completed && o.date === dStr);
    const doneRecurring = doneOcc
      .map(o => tasks.find(t => t.id === o.taskId))
      .filter((t): t is typeof tasks[0] => t !== undefined);

    const allDone = [...doneRegular, ...doneRecurring];

    // Category breakdown
    const catMap = new Map<string, number>();
    allDone.forEach(t => {
      const catKey = t.categoryId || 'general';
      catMap.set(catKey, (catMap.get(catKey) || 0) + 1);
    });

    const categoryBreakdown = Array.from(catMap.entries()).map(([catId, count]) => {
      const cat = catId !== 'general' ? categoryMap.get(catId) : null;
      return {
        id: catId,
        name: cat ? cat.name : 'General',
        colorHex: cat ? cat.colorHex : '#64748B',
        iconName: cat?.iconName,
        count,
        percentage: allDone.length > 0 ? Math.round((count / allDone.length) * 100) : 0,
      };
    });

    return {
      day,
      dayName,
      dateStr: dStr,
      isToday: isSameDay(day, now),
      totalCount: allDone.length,
      categoryBreakdown,
    };
  });

  const maxCount = Math.max(1, ...weekdayStats.map(s => s.totalCount));
  const activeStat = weekdayStats[selectedDayIdx] || weekdayStats[0];

  return (
    <div className="rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border p-5 sm:p-6 shadow-sm space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <BarChart2 className="w-4 h-4 text-brand-500" />
          <h3 className="text-base font-bold text-slate-900 dark:text-white">
            Daily Completed Breakdown
          </h3>
        </div>
        <span className="text-xs font-semibold text-slate-400">Current Week</span>
      </div>

      {/* Vertical Bar Chart (7 Weekdays) */}
      <div className="grid grid-cols-7 gap-2 sm:gap-4 items-end h-40 pt-4 px-2 select-none">
        {weekdayStats.map((stat, idx) => {
          const isSelected = selectedDayIdx === idx;
          const barHeightPercent = Math.max(8, Math.round((stat.totalCount / maxCount) * 100));

          return (
            <div
              key={stat.dayName}
              onClick={() => setSelectedDayIdx(idx)}
              className="flex flex-col items-center gap-2 h-full justify-end cursor-pointer group"
            >
              {/* Count above bar */}
              <span
                className={`text-[10px] font-bold transition-opacity ${
                  stat.totalCount > 0 ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'
                } ${isSelected ? 'text-brand-500 font-extrabold' : 'text-slate-400'}`}
              >
                {stat.totalCount}
              </span>

              {/* Bar */}
              <div className="w-full max-w-[36px] bg-slate-100 dark:bg-surface-dark-subtle rounded-2xl p-1 flex flex-col justify-end h-full">
                <div
                  className={`w-full rounded-xl transition-all duration-300 ${
                    isSelected
                      ? 'bg-gradient-to-t from-brand-600 to-brand-400 shadow-md shadow-brand-500/30'
                      : stat.isToday
                      ? 'bg-brand-400/80 dark:bg-brand-500/80'
                      : stat.totalCount > 0
                      ? 'bg-slate-300 dark:bg-surface-dark-variant group-hover:bg-brand-300'
                      : 'bg-transparent'
                  }`}
                  style={{ height: `${barHeightPercent}%` }}
                />
              </div>

              {/* Day Label */}
              <span
                className={`text-xs font-bold ${
                  isSelected
                    ? 'text-brand-500'
                    : stat.isToday
                    ? 'text-slate-900 dark:text-white underline decoration-brand-500 decoration-2'
                    : 'text-slate-400'
                }`}
              >
                {stat.dayName}
              </span>
            </div>
          );
        })}
      </div>

      {/* Selected Weekday Inspector Card */}
      <div className="p-4 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-100 dark:border-surface-dark-border space-y-3">
        <div className="flex items-center justify-between text-xs font-bold text-slate-800 dark:text-slate-200">
          <span>{AppDateUtils.formatDisplayDate(activeStat.day)}</span>
          <span className="text-brand-500 font-extrabold">{activeStat.totalCount} completed</span>
        </div>

        {/* Category breakdown rows */}
        {activeStat.categoryBreakdown.length > 0 ? (
          <div className="space-y-2">
            {activeStat.categoryBreakdown.map(cat => (
              <div key={cat.id} className="space-y-1">
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-1.5 font-semibold text-slate-700 dark:text-slate-300">
                    <div className="w-2 h-2 rounded-full" style={{ backgroundColor: cat.colorHex }} />
                    <span>{cat.name}</span>
                  </div>
                  <span className="text-[11px] font-bold text-slate-500">
                    {cat.count} ({cat.percentage}%)
                  </span>
                </div>
                <div className="w-full h-1.5 rounded-full bg-slate-200 dark:bg-surface-dark-variant overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all duration-300"
                    style={{ width: `${cat.percentage}%`, backgroundColor: cat.colorHex }}
                  />
                </div>
              </div>
            ))}
          </div>
        ) : (
          <p className="text-xs text-slate-400 italic">No tasks completed on this day.</p>
        )}
      </div>
    </div>
  );
};
