import React, { useState } from 'react';
import { Sparkles, Calendar, Plus, ArrowRight, CheckCircle2, Clock } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { addDays } from 'date-fns';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { Task } from '../../types/task';
import { TaskCard } from '../tasks/TaskCard';
import { QuickAddBar } from '../today/QuickAddBar';

interface TomorrowPlannerPageProps {
  onSelectTask: (taskId: string) => void;
  onEditTask: (taskId: string) => void;
  onRescheduleTask: (taskId: string) => void;
  onOpenCreateTaskForDate: (dateStr: string) => void;
}

export const TomorrowPlannerPage: React.FC<TomorrowPlannerPageProps> = ({
  onSelectTask,
  onEditTask,
  onRescheduleTask,
  onOpenCreateTaskForDate,
}) => {
  const { tasks, occurrences, rescheduleTask } = useDayPulseData();

  const now = new Date();
  const todayStr = AppDateUtils.toIsoDate(now);
  const tomorrow = addDays(now, 1);
  const tomorrowStr = AppDateUtils.toIsoDate(tomorrow);

  // Rollover candidates (uncompleted tasks from today or overdue)
  const rolloverCandidates = tasks.filter(t => !t.parentId && !t.completed && t.date <= todayStr);

  // Tomorrow tasks (non-recurring + recurring synthesized)
  const nonRecTomorrow = tasks.filter(t => !t.parentId && t.repeatRule === 'none' && t.date === tomorrowStr);

  const occMap = new Map<string, boolean>();
  occurrences.forEach(o => {
    if (o.date === tomorrowStr) occMap.set(o.taskId, o.completed);
  });

  const recTomorrow = tasks
    .filter(t => !t.parentId && t.repeatRule !== 'none' && AppDateUtils.isOccurringOnDate(t, tomorrow))
    .map(t => ({
      ...t,
      date: tomorrowStr,
      completed: occMap.has(t.id) ? occMap.get(t.id)! : false,
    }));

  const tomorrowTasks = [...nonRecTomorrow, ...recTomorrow];

  const handleMoveAllToTomorrow = async () => {
    for (const t of rolloverCandidates) {
      await rescheduleTask(t.id, tomorrowStr);
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-24 md:pb-12 animate-fade-in">
      {/* Header */}
      <div className="rounded-3xl bg-gradient-to-tr from-purple-600 via-indigo-600 to-brand-600 text-white p-6 shadow-xl shadow-indigo-500/20">
        <div className="flex items-center gap-2 text-xs font-semibold text-purple-200 uppercase tracking-wider">
          <Sparkles className="w-4 h-4 text-amber-300" />
          <span>Evening Planning Workflow</span>
        </div>
        <h2 className="text-2xl font-black tracking-tight mt-1">Plan Tomorrow</h2>
        <p className="text-xs text-indigo-100/90 mt-0.5">
          {AppDateUtils.formatDisplayDate(tomorrow)} • Prepare your focus and priorities ahead of time
        </p>

        <div className="flex items-center gap-3 mt-4">
          <button
            onClick={() => onOpenCreateTaskForDate(tomorrowStr)}
            className="flex items-center gap-2 px-4 py-2 rounded-2xl bg-white text-indigo-700 text-xs font-bold shadow-md hover:bg-indigo-50 active:scale-95 transition-all"
          >
            <Plus className="w-4 h-4 stroke-[3]" />
            <span>Add Task for Tomorrow</span>
          </button>
        </div>
      </div>

      {/* Rollover Section if there are uncompleted tasks */}
      {rolloverCandidates.length > 0 && (
        <div className="p-5 rounded-3xl bg-amber-500/10 border border-amber-500/20 space-y-3">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
            <div>
              <span className="text-xs font-bold text-amber-600 dark:text-amber-400 uppercase tracking-wider">
                Unfinished Tasks ({rolloverCandidates.length})
              </span>
              <p className="text-xs text-slate-600 dark:text-slate-300 mt-0.5">
                Carry forward tasks from today or earlier that need more time.
              </p>
            </div>

            <button
              onClick={handleMoveAllToTomorrow}
              className="px-4 py-2 rounded-xl bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold shadow-sm self-start sm:self-auto active:scale-95 transition-all"
            >
              Move All to Tomorrow
            </button>
          </div>

          <div className="space-y-1.5 pt-1">
            {rolloverCandidates.map(t => (
              <div
                key={t.id}
                className="flex items-center justify-between px-3.5 py-2.5 rounded-2xl bg-white/70 dark:bg-surface-dark/70 border border-amber-500/15 text-xs"
              >
                <span className="font-semibold text-slate-800 dark:text-slate-200 truncate mr-2">{t.title}</span>
                <button
                  onClick={() => rescheduleTask(t.id, tomorrowStr)}
                  className="flex items-center gap-1 text-[11px] font-bold text-brand-600 dark:text-brand-400 hover:underline flex-shrink-0"
                >
                  <span>Move</span>
                  <ArrowRight className="w-3 h-3" />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Planned Tasks for Tomorrow */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h3 className="text-base font-bold text-slate-900 dark:text-white">
            Tomorrow's Schedule ({tomorrowTasks.length})
          </h3>
          <span className="text-xs text-slate-400">{AppDateUtils.formatShortDate(tomorrow)}</span>
        </div>

        {tomorrowTasks.length > 0 ? (
          <div className="space-y-2.5">
            {tomorrowTasks.map(task => (
              <TaskCard
                key={task.id}
                task={task}
                targetDate={tomorrowStr}
                onSelect={onSelectTask}
                onEdit={onEditTask}
                onReschedule={onRescheduleTask}
              />
            ))}
          </div>
        ) : (
          <div className="text-center py-12 px-4 rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border space-y-3">
            <Calendar className="w-8 h-8 text-slate-300 dark:text-slate-600 mx-auto" />
            <p className="text-xs text-slate-500 dark:text-slate-400">
              No tasks scheduled for tomorrow yet. Set up your top priorities!
            </p>
            <button
              onClick={() => onOpenCreateTaskForDate(tomorrowStr)}
              className="text-xs font-bold text-brand-500 hover:text-brand-600"
            >
              + Add a task for tomorrow
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
