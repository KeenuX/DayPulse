import React from 'react';
import {
  ChevronLeft,
  ChevronRight,
  Calendar as CalendarIcon,
  Plus,
  Clock,
  CheckCircle2,
  Circle,
} from 'lucide-react';
import {
  format,
  startOfWeek,
  endOfWeek,
  startOfMonth,
  endOfMonth,
  eachDayOfInterval,
  isSameMonth,
  isSameDay,
  addMonths,
  subMonths,
} from 'date-fns';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { Task } from '../../types/task';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { TaskCard } from '../tasks/TaskCard';
import { CategoryIcon } from '../categories/CategoryIcon';

interface MonthGridViewProps {
  currentDate: Date;
  onCurrentDateChange: (date: Date) => void;
  selectedDate: Date;
  onSelectedDateChange: (date: Date) => void;
  onSelectTask: (taskId: string) => void;
  onEditTask: (taskId: string) => void;
  onRescheduleTask: (taskId: string) => void;
  onOpenCreateTaskForDate: (dateStr: string) => void;
}

export const MonthGridView: React.FC<MonthGridViewProps> = ({
  currentDate,
  onCurrentDateChange,
  selectedDate,
  onSelectedDateChange,
  onSelectTask,
  onEditTask,
  onRescheduleTask,
  onOpenCreateTaskForDate,
}) => {
  const { tasks, occurrences, categoryMap } = useDayPulseData();

  const monthStart = startOfMonth(currentDate);
  const monthEnd = endOfMonth(monthStart);
  const calendarStart = startOfWeek(monthStart, { weekStartsOn: 0 }); // Sunday
  const calendarEnd = endOfWeek(monthEnd, { weekStartsOn: 0 });

  const calendarDays = eachDayOfInterval({ start: calendarStart, end: calendarEnd });
  const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  const today = new Date();
  const selectedDateStr = AppDateUtils.toIsoDate(selectedDate);

  // Synthesize tasks for a given date
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

  const selectedDayTasks = getTasksForDate(selectedDate);

  return (
    <div className="space-y-6">
      {/* Month Navigator Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h3 className="text-xl font-bold text-slate-800 dark:text-white">
            {format(currentDate, 'MMMM yyyy')}
          </h3>
          <button
            onClick={() => {
              const now = new Date();
              onCurrentDateChange(now);
              onSelectedDateChange(now);
            }}
            className="px-3 py-1 rounded-xl bg-brand-500/10 hover:bg-brand-500/20 text-brand-600 dark:text-brand-400 text-xs font-bold transition-colors"
          >
            Today
          </button>
        </div>

        <div className="flex items-center gap-1">
          <button
            onClick={() => onCurrentDateChange(subMonths(currentDate, 1))}
            className="p-2 rounded-xl text-slate-500 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-variant transition-colors"
            title="Previous Month"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <button
            onClick={() => onCurrentDateChange(addMonths(currentDate, 1))}
            className="p-2 rounded-xl text-slate-500 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-variant transition-colors"
            title="Next Month"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* 7-Column Calendar Grid */}
      <div className="rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border p-4 sm:p-6 shadow-sm overflow-hidden">
        {/* Weekday Labels Header */}
        <div className="grid grid-cols-7 gap-1 text-center mb-3">
          {weekdays.map(day => (
            <div key={day} className="text-xs font-bold text-slate-400 py-1 uppercase tracking-wider">
              {day}
            </div>
          ))}
        </div>

        {/* 7-Column Days Matrix */}
        <div className="grid grid-cols-7 gap-1 sm:gap-2">
          {calendarDays.map(day => {
            const isCurrentMonth = isSameMonth(day, currentDate);
            const isSelected = isSameDay(day, selectedDate);
            const isToday = isSameDay(day, today);
            const dayTasks = getTasksForDate(day);
            const hasTasks = dayTasks.length > 0;

            return (
              <button
                key={day.toISOString()}
                onClick={() => onSelectedDateChange(day)}
                className={`relative min-h-[52px] sm:min-h-[64px] p-1 sm:p-2 rounded-2xl flex flex-col items-center justify-between transition-all select-none ${
                  isSelected
                    ? 'bg-brand-500 text-white shadow-md shadow-brand-500/25 ring-2 ring-brand-400 ring-offset-2 dark:ring-offset-surface-dark'
                    : isToday
                    ? 'bg-brand-500/10 text-brand-600 dark:text-brand-400 font-bold border border-brand-500/30'
                    : isCurrentMonth
                    ? 'text-slate-800 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-surface-dark-subtle'
                    : 'text-slate-300 dark:text-slate-600 opacity-40 hover:opacity-80'
                }`}
              >
                {/* Date Number */}
                <span
                  className={`text-xs sm:text-sm font-bold ${
                    isSelected
                      ? 'text-white'
                      : isToday
                      ? 'text-brand-500'
                      : isCurrentMonth
                      ? 'text-slate-700 dark:text-slate-200'
                      : 'text-slate-400 dark:text-slate-600'
                  }`}
                >
                  {format(day, 'd')}
                </span>

                {/* Task Indicator Dots */}
                {hasTasks && (
                  <div className="flex items-center gap-0.5 justify-center mt-1 flex-wrap max-w-full px-0.5">
                    {dayTasks.slice(0, 3).map((t, idx) => {
                      const cat = t.categoryId ? categoryMap.get(t.categoryId) : null;
                      const dotColor = isSelected ? '#FFFFFF' : cat?.colorHex || '#64748B';
                      return (
                        <div
                          key={idx}
                          className="w-1.5 h-1.5 rounded-full"
                          style={{ backgroundColor: dotColor }}
                        />
                      );
                    })}
                    {dayTasks.length > 3 && (
                      <span className={`text-[8px] leading-none ${isSelected ? 'text-white' : 'text-slate-400'}`}>
                        +
                      </span>
                    )}
                  </div>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Selected Day Task List Panel */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h4 className="text-base font-bold text-slate-800 dark:text-white">
              {AppDateUtils.formatDisplayDate(selectedDate)}
            </h4>
            <p className="text-xs text-slate-400">
              {selectedDayTasks.length} task{selectedDayTasks.length === 1 ? '' : 's'} scheduled
            </p>
          </div>

          <button
            onClick={() => onOpenCreateTaskForDate(selectedDateStr)}
            className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-brand-500 hover:bg-brand-600 text-white text-xs font-bold shadow-sm active:scale-95 transition-all"
          >
            <Plus className="w-4 h-4 stroke-[2.5]" />
            <span>Add to Date</span>
          </button>
        </div>

        {selectedDayTasks.length > 0 ? (
          <div className="space-y-2.5">
            {selectedDayTasks.map(task => (
              <TaskCard
                key={task.id}
                task={task}
                targetDate={selectedDateStr}
                onSelect={onSelectTask}
                onEdit={onEditTask}
                onReschedule={onRescheduleTask}
              />
            ))}
          </div>
        ) : (
          <div className="text-center py-10 px-4 rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border space-y-2">
            <CalendarIcon className="w-8 h-8 text-slate-300 dark:text-slate-600 mx-auto" />
            <p className="text-xs text-slate-500 dark:text-slate-400">
              No tasks scheduled for {AppDateUtils.formatShortDate(selectedDate)}.
            </p>
            <button
              onClick={() => onOpenCreateTaskForDate(selectedDateStr)}
              className="text-xs font-bold text-brand-500 hover:text-brand-600 mt-1 inline-block"
            >
              + Create a task for this date
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
