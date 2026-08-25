import React from 'react';
import { format, addDays, subDays } from 'date-fns';
import { ChevronLeft, ChevronRight, Plus, Clock } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { Task } from '../../types/task';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { CategoryIcon } from '../categories/CategoryIcon';

interface DayTimelineViewProps {
  selectedDate: Date;
  onSelectedDateChange: (date: Date) => void;
  onSelectTask: (taskId: string) => void;
  onOpenCreateTaskForDate: (dateStr: string) => void;
}

export const DayTimelineView: React.FC<DayTimelineViewProps> = ({
  selectedDate,
  onSelectedDateChange,
  onSelectTask,
  onOpenCreateTaskForDate,
}) => {
  const { tasks, occurrences, categoryMap } = useDayPulseData();
  const dateStr = AppDateUtils.toIsoDate(selectedDate);

  const nonRec = tasks.filter(t => !t.parentId && t.repeatRule === 'none' && t.date === dateStr);
  const occMap = new Map<string, boolean>();
  occurrences.forEach(o => {
    if (o.date === dateStr) occMap.set(o.taskId, o.completed);
  });

  const rec = tasks
    .filter(t => !t.parentId && t.repeatRule !== 'none' && AppDateUtils.isOccurringOnDate(t, selectedDate))
    .map(t => ({
      ...t,
      date: dateStr,
      completed: occMap.has(t.id) ? occMap.get(t.id)! : false,
    }));

  const dayTasks = [...nonRec, ...rec];

  // Hours 06:00 to 23:00
  const hours = Array.from({ length: 18 }, (_, i) => i + 6);

  return (
    <div className="space-y-6">
      {/* Day Navigator */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h3 className="text-xl font-bold text-slate-800 dark:text-white">
            {AppDateUtils.formatDisplayDate(selectedDate)}
          </h3>
          <button
            onClick={() => onSelectedDateChange(new Date())}
            className="px-3 py-1 rounded-xl bg-brand-500/10 hover:bg-brand-500/20 text-brand-600 dark:text-brand-400 text-xs font-bold transition-colors"
          >
            Today
          </button>
        </div>

        <div className="flex items-center gap-1">
          <button
            onClick={() => onSelectedDateChange(subDays(selectedDate, 1))}
            className="p-2 rounded-xl text-slate-500 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-variant"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <button
            onClick={() => onSelectedDateChange(addDays(selectedDate, 1))}
            className="p-2 rounded-xl text-slate-500 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-variant"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Hourly Timeline */}
      <div className="rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border p-4 sm:p-6 shadow-sm space-y-4">
        {hours.map(hour => {
          const hourLabel = hour >= 12 ? `${hour === 12 ? 12 : hour - 12} PM` : `${hour} AM`;
          const matchingTasks = dayTasks.filter(t => {
            if (!t.startTime) return false;
            const h = parseInt(t.startTime.split(':')[0], 10);
            return h === hour;
          });

          return (
            <div key={hour} className="flex items-start gap-4 group">
              <span className="w-16 text-right text-xs font-bold text-slate-400 pt-1 select-none">
                {hourLabel}
              </span>

              <div className="flex-1 min-h-[48px] border-l-2 border-slate-100 dark:border-surface-dark-border/80 pl-4 py-1 space-y-2 relative">
                {matchingTasks.map(t => {
                  const cat = t.categoryId ? categoryMap.get(t.categoryId) : null;
                  return (
                    <div
                      key={t.id}
                      onClick={() => onSelectTask(t.id)}
                      className="p-3 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle hover:bg-slate-100 dark:hover:bg-surface-dark-variant border border-slate-200/60 dark:border-surface-dark-border cursor-pointer transition-all shadow-sm flex items-center justify-between"
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className="w-2.5 h-2.5 rounded-full"
                          style={{ backgroundColor: cat?.colorHex || '#64748B' }}
                        />
                        <div>
                          <div
                            className={`text-xs font-bold ${
                              t.completed ? 'line-through text-slate-400' : 'text-slate-800 dark:text-slate-200'
                            }`}
                          >
                            {t.title}
                          </div>
                          {t.startTime && (
                            <div className="text-[10px] text-slate-400 mt-0.5">
                              {AppDateUtils.formatTime12(t.startTime)} {t.endTime ? `– ${AppDateUtils.formatTime12(t.endTime)}` : ''}
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
