import React, { useState } from 'react';
import { Clock, Zap } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { startOfWeek, endOfWeek, eachDayOfInterval, format, isSameDay } from 'date-fns';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { formatDurationMinutes } from '../../core/utilities/durationFormatter';

export const FocusMetricsCard: React.FC = () => {
  const { tasks, occurrences } = useDayPulseData();
  const [selectedDayIdx, setSelectedDayIdx] = useState<number>(new Date().getDay());

  const now = new Date();
  const weekStart = startOfWeek(now, { weekStartsOn: 0 }); // Sunday
  const weekEnd = endOfWeek(now, { weekStartsOn: 0 });
  const weekDays = eachDayOfInterval({ start: weekStart, end: weekEnd });

  let totalWeeklyMinutes = 0;

  const focusStats = weekDays.map((day, idx) => {
    const dStr = AppDateUtils.toIsoDate(day);
    const dayName = format(day, 'EEE');

    // 1. Regular tasks on this day
    const regTasks = tasks.filter(t => !t.parentId && t.repeatRule === 'none' && t.date === dStr && t.completed);
    // 2. Occurrences
    const doneOcc = occurrences.filter(o => o.completed && o.date === dStr);
    const occTasks = doneOcc
      .map(o => tasks.find(t => t.id === o.taskId))
      .filter((t): t is typeof tasks[0] => t !== undefined);

    const allDone = [...regTasks, ...occTasks];

    const dayMinutes = allDone.reduce((acc, t) => acc + (t.durationMinutes || 0), 0);
    totalWeeklyMinutes += dayMinutes;

    return {
      day,
      dayName,
      dateStr: dStr,
      isToday: isSameDay(day, now),
      focusMinutes: dayMinutes,
      completedCount: allDone.length,
    };
  });

  const maxMinutes = Math.max(60, ...focusStats.map(s => s.focusMinutes));
  const activeFocus = focusStats[selectedDayIdx] || focusStats[0];

  return (
    <div className="rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border p-5 sm:p-6 shadow-sm space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Clock className="w-4 h-4 text-sky-500" />
          <h3 className="text-base font-bold text-slate-900 dark:text-white">
            Weekly Focus Analytics
          </h3>
        </div>

        <div className="flex items-baseline gap-1 text-sky-600 dark:text-sky-400">
          <span className="text-xl font-black">{formatDurationMinutes(totalWeeklyMinutes) || '0m'}</span>
          <span className="text-xs font-semibold text-slate-400">total</span>
        </div>
      </div>

      {/* Weekday Focus Bars */}
      <div className="grid grid-cols-7 gap-2 sm:gap-4 items-end h-36 pt-4 px-2 select-none">
        {focusStats.map((stat, idx) => {
          const isSelected = selectedDayIdx === idx;
          const barHeightPercent = Math.max(8, Math.round((stat.focusMinutes / maxMinutes) * 100));

          return (
            <div
              key={stat.dayName}
              onClick={() => setSelectedDayIdx(idx)}
              className="flex flex-col items-center gap-2 h-full justify-end cursor-pointer group"
            >
              {/* Duration above bar */}
              <span
                className={`text-[9px] font-bold transition-opacity whitespace-nowrap ${
                  stat.focusMinutes > 0 ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'
                } ${isSelected ? 'text-sky-500 font-extrabold' : 'text-slate-400'}`}
              >
                {stat.focusMinutes > 0 ? formatDurationMinutes(stat.focusMinutes) : '0m'}
              </span>

              {/* Bar */}
              <div className="w-full max-w-[36px] bg-slate-100 dark:bg-surface-dark-subtle rounded-2xl p-1 flex flex-col justify-end h-full">
                <div
                  className={`w-full rounded-xl transition-all duration-300 ${
                    isSelected
                      ? 'bg-gradient-to-t from-sky-600 to-sky-400 shadow-md shadow-sky-500/30'
                      : stat.isToday
                      ? 'bg-sky-400/80 dark:bg-sky-500/80'
                      : stat.focusMinutes > 0
                      ? 'bg-slate-300 dark:bg-surface-dark-variant group-hover:bg-sky-300'
                      : 'bg-transparent'
                  }`}
                  style={{ height: `${barHeightPercent}%` }}
                />
              </div>

              {/* Day Label */}
              <span
                className={`text-xs font-bold ${
                  isSelected ? 'text-sky-500' : stat.isToday ? 'text-slate-900 dark:text-white underline' : 'text-slate-400'
                }`}
              >
                {stat.dayName}
              </span>
            </div>
          );
        })}
      </div>

      {/* Selected Day Focus Inspector */}
      <div className="p-4 rounded-2xl bg-sky-500/5 border border-sky-500/15 flex items-center justify-between text-xs">
        <div>
          <span className="font-bold text-slate-800 dark:text-slate-200">
            {AppDateUtils.formatDisplayDate(activeFocus.day)}
          </span>
          <p className="text-[11px] text-slate-400 mt-0.5">
            {activeFocus.completedCount} completed task{activeFocus.completedCount === 1 ? '' : 's'} on this day
          </p>
        </div>

        <div className="text-right">
          <div className="text-base font-black text-sky-600 dark:text-sky-400">
            {formatDurationMinutes(activeFocus.focusMinutes) || '0 minutes'}
          </div>
          <span className="text-[10px] text-slate-400">total focus time</span>
        </div>
      </div>
    </div>
  );
};
