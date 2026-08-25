import React from 'react';
import { format, startOfWeek, endOfWeek, eachDayOfInterval, isSameDay, addWeeks, subWeeks } from 'date-fns';
import { ChevronLeft, ChevronRight, Plus, Clock, CheckCircle2, Circle } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { Task } from '../../types/task';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { CategoryIcon } from '../categories/CategoryIcon';

interface WeekTimelineViewProps {
  currentDate: Date;
  onCurrentDateChange: (date: Date) => void;
  onSelectTask: (taskId: string) => void;
  onOpenCreateTaskForDate: (dateStr: string) => void;
}

export const WeekTimelineView: React.FC<WeekTimelineViewProps> = ({
  currentDate,
  onCurrentDateChange,
  onSelectTask,
  onOpenCreateTaskForDate,
}) => {
  const { tasks, occurrences, categoryMap, toggleTaskCompletion } = useDayPulseData();

  const weekStart = startOfWeek(currentDate, { weekStartsOn: 0 }); // Sunday
  const weekEnd = endOfWeek(currentDate, { weekStartsOn: 0 });
  const days = eachDayOfInterval({ start: weekStart, end: weekEnd });
  const today = new Date();

  const getTasksForDate = (date: Date): Task[] => {
    const dStr = AppDateUtils.toIsoDate(date);
    const nonRec = tasks.filter(t => !t.parentId && t.repeatRule === 'none' && t.date === dStr);

    const occMap = new Map<string, boolean>();
    occurrences.forEach(o => {
      if (o.date === dStr) occMap.set(o.taskId, o.completed);
    });

    const rec = tasks
      .filter(t => !t.parentId && t.repeatRule !== 'none' && AppDateUtils.isOccurringOnDate(t, date))
      .map(t => ({
        ...t,
        date: dStr,
        completed: occMap.has(t.id) ? occMap.get(t.id)! : false,
      }));

    return [...nonRec, ...rec];
  };

  return (
    <div className="space-y-6">
      {/* Week Navigator */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h3 className="text-xl font-bold text-slate-800 dark:text-white">
            {format(weekStart, 'MMM d')} – {format(weekEnd, 'MMM d, yyyy')}
          </h3>
          <button
            onClick={() => onCurrentDateChange(new Date())}
            className="px-3 py-1 rounded-xl bg-brand-500/10 hover:bg-brand-500/20 text-brand-600 dark:text-brand-400 text-xs font-bold transition-colors"
          >
            Current Week
          </button>
        </div>

        <div className="flex items-center gap-1">
          <button
            onClick={() => onCurrentDateChange(subWeeks(currentDate, 1))}
            className="p-2 rounded-xl text-slate-500 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-variant"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <button
            onClick={() => onCurrentDateChange(addWeeks(currentDate, 1))}
            className="p-2 rounded-xl text-slate-500 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-variant"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* 7 Days Columns */}
      <div className="grid grid-cols-1 sm:grid-cols-7 gap-3">
        {days.map(day => {
          const isToday = isSameDay(day, today);
          const dayTasks = getTasksForDate(day);
          const dayStr = AppDateUtils.toIsoDate(day);

          return (
            <div
              key={day.toISOString()}
              className={`rounded-2xl border p-3 flex flex-col min-h-[220px] transition-colors ${
                isToday
                  ? 'bg-brand-500/5 dark:bg-brand-950/20 border-brand-500/40 shadow-sm'
                  : 'bg-surface-light dark:bg-surface-dark border-slate-200/80 dark:border-surface-dark-border'
              }`}
            >
              {/* Day Header */}
              <div className="flex items-center justify-between pb-2 border-b border-slate-100 dark:border-surface-dark-border">
                <div>
                  <span className="text-[11px] font-bold text-slate-400 uppercase">{format(day, 'EEE')}</span>
                  <div
                    className={`text-base font-black ${
                      isToday ? 'text-brand-500' : 'text-slate-800 dark:text-slate-200'
                    }`}
                  >
                    {format(day, 'd')}
                  </div>
                </div>

                <button
                  onClick={() => onOpenCreateTaskForDate(dayStr)}
                  className="p-1 rounded-lg text-slate-400 hover:text-brand-500 hover:bg-slate-100 dark:hover:bg-surface-dark-variant"
                  title="Add task to day"
                >
                  <Plus className="w-3.5 h-3.5" />
                </button>
              </div>

              {/* Day Tasks List */}
              <div className="flex-1 space-y-1.5 mt-2 overflow-y-auto max-h-[300px]">
                {dayTasks.map(t => {
                  const cat = t.categoryId ? categoryMap.get(t.categoryId) : null;
                  return (
                    <div
                      key={t.id}
                      onClick={() => onSelectTask(t.id)}
                      className="p-2 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle hover:bg-slate-100 dark:hover:bg-surface-dark-variant border border-slate-100 dark:border-surface-dark-border cursor-pointer transition-colors text-xs"
                    >
                      <div className="flex items-center gap-1.5">
                        <div
                          className="w-1.5 h-1.5 rounded-full flex-shrink-0"
                          style={{ backgroundColor: cat?.colorHex || '#64748B' }}
                        />
                        <span
                          className={`font-semibold truncate ${
                            t.completed ? 'line-through text-slate-400' : 'text-slate-800 dark:text-slate-200'
                          }`}
                        >
                          {t.title}
                        </span>
                      </div>
                      {t.startTime && (
                        <div className="text-[10px] text-slate-400 mt-1 flex items-center gap-1">
                          <Clock className="w-2.5 h-2.5" />
                          <span>{AppDateUtils.formatTime12(t.startTime)}</span>
                        </div>
                      )}
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
