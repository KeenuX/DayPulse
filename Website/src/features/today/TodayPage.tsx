import React from 'react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { TodayHeaderCard } from './TodayHeaderCard';
import { QuickAddBar } from './QuickAddBar';
import { TimeSlotSection } from './TimeSlotSection';
import { Task } from '../../types/task';
import { Sparkles, Calendar } from 'lucide-react';

interface TodayPageProps {
  onSelectTask: (taskId: string) => void;
  onEditTask: (taskId: string) => void;
  onRescheduleTask: (taskId: string) => void;
  onOpenCreateTask: () => void;
  onOpenDailySummary: () => void;
}

export const TodayPage: React.FC<TodayPageProps> = ({
  onSelectTask,
  onEditTask,
  onRescheduleTask,
  onOpenCreateTask,
  onOpenDailySummary,
}) => {
  const { tasks, occurrences } = useDayPulseData();

  const now = new Date();
  const todayStr = AppDateUtils.toIsoDate(now);

  // 1. Get non-recurring top-level tasks for today
  const nonRecurringToday = tasks.filter(t => !t.parentId && t.repeatRule === 'none' && t.date === todayStr);

  // 2. Synthesize recurring tasks occurring today
  const occMap = new Map<string, boolean>();
  occurrences.forEach(o => {
    if (o.date === todayStr) occMap.set(o.taskId, o.completed);
  });

  const recurringToday: Task[] = tasks
    .filter(t => !t.parentId && t.repeatRule !== 'none' && AppDateUtils.isOccurringOnDate(t, now))
    .map(t => ({
      ...t,
      date: todayStr,
      completed: occMap.has(t.id) ? occMap.get(t.id)! : false,
    }));

  const allTodayTasks = [...nonRecurringToday, ...recurringToday];

  // Group by Time Slots
  const morningTasks: Task[] = [];
  const afternoonTasks: Task[] = [];
  const eveningTasks: Task[] = [];
  const anytimeTasks: Task[] = [];

  allTodayTasks.forEach(task => {
    if (!task.startTime) {
      anytimeTasks.push(task);
      return;
    }
    const [hour] = task.startTime.split(':').map(Number);
    if (hour < 12) {
      morningTasks.push(task);
    } else if (hour < 17) {
      afternoonTasks.push(task);
    } else if (hour < 21) {
      eveningTasks.push(task);
    } else {
      anytimeTasks.push(task);
    }
  });

  // Sort each slot by start time
  const sortByTime = (a: Task, b: Task) => (a.startTime || '').localeCompare(b.startTime || '');
  morningTasks.sort(sortByTime);
  afternoonTasks.sort(sortByTime);
  eveningTasks.sort(sortByTime);

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-24 md:pb-12 animate-fade-in">
      {/* Header Banner */}
      <TodayHeaderCard onOpenDailySummary={onOpenDailySummary} />

      {/* Quick Add NLP Bar */}
      <QuickAddBar onOpenFullModal={onOpenCreateTask} />

      {/* Time Slot Sections */}
      {allTodayTasks.length > 0 ? (
        <div className="space-y-6">
          <TimeSlotSection
            slot="morning"
            tasks={morningTasks}
            onSelectTask={onSelectTask}
            onEditTask={onEditTask}
            onRescheduleTask={onRescheduleTask}
          />

          <TimeSlotSection
            slot="afternoon"
            tasks={afternoonTasks}
            onSelectTask={onSelectTask}
            onEditTask={onEditTask}
            onRescheduleTask={onRescheduleTask}
          />

          <TimeSlotSection
            slot="evening"
            tasks={eveningTasks}
            onSelectTask={onSelectTask}
            onEditTask={onEditTask}
            onRescheduleTask={onRescheduleTask}
          />

          <TimeSlotSection
            slot="anytime"
            tasks={anytimeTasks}
            onSelectTask={onSelectTask}
            onEditTask={onEditTask}
            onRescheduleTask={onRescheduleTask}
          />
        </div>
      ) : (
        /* Empty State */
        <div className="text-center py-12 px-4 rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border space-y-4">
          <div className="w-16 h-16 rounded-3xl bg-brand-500/10 text-brand-500 flex items-center justify-center mx-auto shadow-sm">
            <Sparkles className="w-8 h-8" />
          </div>
          <div>
            <h3 className="text-base font-bold text-slate-800 dark:text-white">All Clear for Today!</h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1 max-w-sm mx-auto">
              No tasks scheduled for today. Add a new task using the quick-add bar above or plan your day!
            </p>
          </div>
          <button
            onClick={onOpenCreateTask}
            className="px-5 py-2.5 rounded-xl bg-brand-500 hover:bg-brand-600 text-white text-xs font-bold shadow-md shadow-brand-500/25 active:scale-95 transition-all"
          >
            + Create Today's Task
          </button>
        </div>
      )}
    </div>
  );
};
