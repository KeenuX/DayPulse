import React, { useState, useRef, useEffect } from 'react';
import { format, startOfYear, endOfYear, startOfWeek, addDays, isSameDay, subDays, differenceInDays } from 'date-fns';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { Calendar, Info } from 'lucide-react';

export const AnnualHeatmapCard: React.FC = () => {
  const { tasks, occurrences } = useDayPulseData();
  const [hoveredDay, setHoveredDay] = useState<{ date: string; count: number } | null>(null);
  const scrollContainerRef = useRef<HTMLDivElement>(null);

  const now = new Date();
  const currentYear = now.getFullYear();
  const yearStart = startOfYear(now);
  const calendarStart = startOfWeek(yearStart, { weekStartsOn: 0 }); // Sunday

  // Generate 53 weeks (371 days)
  const totalDays = 53 * 7;
  const days = Array.from({ length: totalDays }, (_, i) => addDays(calendarStart, i));

  // Count completions per date
  const completionsMap = new Map<string, number>();

  // 1. Non-recurring tasks
  tasks.forEach(t => {
    if (t.completed && t.completedAt) {
      const dStr = t.completedAt.split('T')[0];
      completionsMap.set(dStr, (completionsMap.get(dStr) || 0) + 1);
    } else if (t.completed && t.date) {
      completionsMap.set(t.date, (completionsMap.get(t.date) || 0) + 1);
    }
  });

  // 2. Recurring occurrences
  occurrences.forEach(o => {
    if (o.completed && o.date) {
      completionsMap.set(o.date, (completionsMap.get(o.date) || 0) + 1);
    }
  });

  // Auto-scroll to current week
  useEffect(() => {
    if (scrollContainerRef.current) {
      const currentWeekIndex = Math.floor(differenceInDays(now, calendarStart) / 7);
      const scrollPos = Math.max(0, currentWeekIndex * 15 - 120);
      scrollContainerRef.current.scrollLeft = scrollPos;
    }
  }, []);

  // Total annual completed tasks
  let annualCompletions = 0;
  days.forEach(d => {
    const dStr = AppDateUtils.toIsoDate(d);
    annualCompletions += completionsMap.get(dStr) || 0;
  });

  // Intensity color tiers
  const getCellColor = (count: number, isDark: boolean) => {
    if (count === 0) return 'bg-slate-100 dark:bg-surface-dark-subtle/80';
    if (count === 1) return 'bg-brand-300 dark:bg-brand-900/70';
    if (count <= 3) return 'bg-brand-400 dark:bg-brand-600';
    if (count <= 5) return 'bg-brand-500 dark:bg-brand-500';
    return 'bg-brand-600 dark:bg-brand-400';
  };

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  return (
    <div className="rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border p-5 sm:p-6 shadow-sm space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-2">
            <Calendar className="w-4 h-4 text-brand-500" />
            <h3 className="text-base font-bold text-slate-900 dark:text-white">
              {currentYear} Contribution Heatmap
            </h3>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">
            53-week Sunday-aligned activity matrix • {annualCompletions} tasks finished this year
          </p>
        </div>

        {/* Hover Inspector Pill */}
        <div className="text-xs font-semibold px-3 py-1.5 rounded-xl bg-slate-100 dark:bg-surface-dark-subtle text-slate-700 dark:text-slate-200 border border-slate-200/60 dark:border-surface-dark-border">
          {hoveredDay ? (
            <span>
              <strong>{hoveredDay.count}</strong> done on {AppDateUtils.formatShortDate(hoveredDay.date)}
            </span>
          ) : (
            <span className="text-slate-400">Hover cell to inspect</span>
          )}
        </div>
      </div>

      {/* Heatmap Grid Container (Scrollable) */}
      <div
        ref={scrollContainerRef}
        className="overflow-x-auto pb-2 scroll-smooth"
      >
        <div className="min-w-[780px] space-y-2 select-none">
          {/* Month labels row */}
          <div className="grid grid-flow-col auto-cols-[14px] gap-[3px] text-[10px] font-bold text-slate-400 pl-6">
            {months.map((m, idx) => (
              <span key={m} className="col-span-4 truncate">
                {m}
              </span>
            ))}
          </div>

          {/* 7 Rows (Sun to Sat) x 53 Columns */}
          <div className="flex gap-2">
            {/* Weekday labels */}
            <div className="flex flex-col justify-between text-[9px] font-bold text-slate-400 py-0.5">
              <span>Sun</span>
              <span>Tue</span>
              <span>Thu</span>
              <span>Sat</span>
            </div>

            {/* Matrix Columns */}
            <div className="grid grid-flow-col grid-rows-7 gap-[3.5px]">
              {days.map(day => {
                const dStr = AppDateUtils.toIsoDate(day);
                const count = completionsMap.get(dStr) || 0;
                const isToday = isSameDay(day, now);

                return (
                  <div
                    key={dStr}
                    onMouseEnter={() => setHoveredDay({ date: dStr, count })}
                    onMouseLeave={() => setHoveredDay(null)}
                    className={`w-3 h-3 rounded-[3px] transition-transform hover:scale-125 cursor-pointer ${
                      count > 0
                        ? count === 1
                          ? 'bg-brand-300 dark:bg-brand-900'
                          : count <= 3
                          ? 'bg-brand-400 dark:bg-brand-700'
                          : count <= 5
                          ? 'bg-brand-500 dark:bg-brand-500'
                          : 'bg-indigo-600 dark:bg-brand-400'
                        : 'bg-slate-100 dark:bg-surface-dark-subtle/80'
                    } ${isToday ? 'ring-1 ring-amber-400' : ''}`}
                    title={`${count} completed tasks on ${dStr}`}
                  />
                );
              })}
            </div>
          </div>
        </div>
      </div>

      {/* Legend Footer */}
      <div className="flex items-center justify-between text-[11px] text-slate-400 pt-1 border-t border-slate-100 dark:border-surface-dark-border/60">
        <span>53 weeks (Sunday – Saturday)</span>

        <div className="flex items-center gap-1.5">
          <span>Less</span>
          <div className="w-2.5 h-2.5 rounded-[2px] bg-slate-100 dark:bg-surface-dark-subtle" />
          <div className="w-2.5 h-2.5 rounded-[2px] bg-brand-300 dark:bg-brand-900" />
          <div className="w-2.5 h-2.5 rounded-[2px] bg-brand-400 dark:bg-brand-700" />
          <div className="w-2.5 h-2.5 rounded-[2px] bg-brand-500 dark:bg-brand-500" />
          <div className="w-2.5 h-2.5 rounded-[2px] bg-indigo-600 dark:bg-brand-400" />
          <span>More</span>
        </div>
      </div>
    </div>
  );
};
