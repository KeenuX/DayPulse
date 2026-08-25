import React, { useState } from 'react';
import {
  Calendar,
  CheckCircle2,
  Circle,
  Clock,
  Repeat,
  Star,
  Trash2,
  Edit,
  ChevronDown,
  ChevronUp,
  Plus,
  ListTodo,
} from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { Task } from '../../types/task';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { formatDurationMinutes } from '../../core/utilities/durationFormatter';
import { addDays } from 'date-fns';
import { SubtasksList } from '../tasks/SubtasksList';

interface Next7DaysTasksCardProps {
  onSelectTask?: (taskId: string) => void;
  onEditTask?: (taskId: string) => void;
  onRescheduleTask?: (taskId: string) => void;
}

export const Next7DaysTasksCard: React.FC<Next7DaysTasksCardProps> = ({
  onSelectTask,
  onEditTask,
  onRescheduleTask,
}) => {
  const { tasks, occurrences, categoryMap, toggleTaskCompletion, toggleStarTask, deleteTask, addTask } =
    useDayPulseData();

  const [expandedTaskKeys, setExpandedTaskKeys] = useState<Record<string, boolean>>({});
  const [quickSubtaskText, setQuickSubtaskText] = useState<Record<string, string>>({});

  const now = new Date();

  // Gather tasks for the next 7 days (today through today + 7)
  const next7DaysTasks: { task: Task; targetDate: string; key: string }[] = [];

  for (let i = 0; i <= 7; i++) {
    const day = addDays(now, i);
    const dayStr = AppDateUtils.toIsoDate(day);

    // 1. Regular non-recurring top-level tasks on this date
    const regularOnDay = tasks.filter(
      t => !t.parentId && t.repeatRule === 'none' && t.date === dayStr && !t.completed
    );
    regularOnDay.forEach(t => {
      next7DaysTasks.push({ task: t, targetDate: dayStr, key: `${t.id}_${dayStr}` });
    });

    // 2. Recurring tasks occurring on this date
    const recurringOnDay = tasks.filter(
      t => !t.parentId && t.repeatRule !== 'none' && AppDateUtils.isOccurringOnDate(t, day)
    );
    recurringOnDay.forEach(t => {
      const occ = occurrences.find(o => o.taskId === t.id && o.date === dayStr);
      if (!occ || !occ.completed) {
        next7DaysTasks.push({
          task: { ...t, date: dayStr },
          targetDate: dayStr,
          key: `${t.id}_${dayStr}`,
        });
      }
    });
  }

  const toggleExpand = (key: string) => {
    setExpandedTaskKeys(prev => ({ ...prev, [key]: !prev[key] }));
  };

  const handleAddSubtask = async (taskId: string, dateStr: string) => {
    const text = quickSubtaskText[taskId]?.trim();
    if (!text) return;
    await addTask({
      parentId: taskId,
      title: text,
      date: dateStr,
      priority: 'medium',
      completed: false,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
      reminderEnabled: false,
    });
    setQuickSubtaskText(prev => ({ ...prev, [taskId]: '' }));
    setExpandedTaskKeys(prev => ({ ...prev, [`${taskId}_${dateStr}`]: true }));
  };

  const formatDateLabel = (dateStr: string) => {
    const todayStr = AppDateUtils.toIsoDate(now);
    const tomorrowStr = AppDateUtils.toIsoDate(addDays(now, 1));
    if (dateStr === todayStr) return 'Today';
    if (dateStr === tomorrowStr) return 'Tomorrow';
    return AppDateUtils.formatShortDate(new Date(dateStr));
  };

  return (
    <div className="rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border p-5 sm:p-6 shadow-sm space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Calendar className="w-4 h-4 text-brand-500" />
          <h3 className="text-base font-bold text-slate-900 dark:text-white">Tasks in Next 7 Days</h3>
        </div>
        <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-brand-50 dark:bg-brand-950/40 text-brand-600 dark:text-brand-400">
          {next7DaysTasks.length} upcoming
        </span>
      </div>

      {/* Task List */}
      {next7DaysTasks.length === 0 ? (
        <div className="py-8 text-center text-slate-400 dark:text-slate-500 text-xs">
          No upcoming tasks in the next 7 days.
        </div>
      ) : (
        <div className="space-y-2">
          {next7DaysTasks.map(({ task, targetDate, key }) => {
            const category = task.categoryId ? categoryMap.get(task.categoryId) : null;
            const categoryColor = category?.colorHex || '#64748B';
            const isExpanded = !!expandedTaskKeys[key];
            const childSubtasks = tasks.filter(t => t.parentId === task.id);
            const completedSubtasks = childSubtasks.filter(t => t.completed).length;
            const dateBadge = formatDateLabel(targetDate);

            return (
              <div
                key={key}
                className="group rounded-2xl bg-slate-50/60 dark:bg-surface-dark-subtle/50 border border-slate-200/70 dark:border-surface-dark-border/80 overflow-hidden transition-all duration-200 hover:border-brand-300 dark:hover:border-brand-500/40"
              >
                {/* Main Compact Row */}
                <div className="flex items-center justify-between gap-2 p-2.5 sm:p-3 relative">
                  {/* Left Category Color Bar */}
                  <div
                    className="absolute left-0 top-2 bottom-2 w-1 rounded-r-full"
                    style={{ backgroundColor: categoryColor }}
                  />

                  {/* Left: Checkbox + Title + Category Meta */}
                  <div className="flex items-center gap-2.5 flex-1 min-w-0 pl-1.5">
                    {/* Checkbox */}
                    <button
                      onClick={() => toggleTaskCompletion(task, targetDate)}
                      className="flex-shrink-0 text-brand-500 hover:scale-110 active:scale-95 transition-transform"
                      aria-label="Toggle completed"
                    >
                      {task.completed ? (
                        <CheckCircle2 className="w-4.5 h-4.5 fill-emerald-500 text-white" />
                      ) : (
                        <Circle className="w-4.5 h-4.5 text-slate-400 hover:text-brand-500 stroke-[2]" />
                      )}
                    </button>

                    {/* Title & Small Category info */}
                    <div
                      className="flex-1 min-w-0 cursor-pointer"
                      onClick={() => (onSelectTask ? onSelectTask(task.id) : toggleExpand(key))}
                    >
                      <div className="flex items-center gap-2">
                        <span
                          className={`text-[13.5px] font-semibold truncate ${
                            task.completed
                              ? 'line-through text-slate-400 dark:text-slate-500'
                              : 'text-slate-800 dark:text-slate-100'
                          }`}
                        >
                          {task.title}
                        </span>

                        {/* High Priority Flag */}
                        {task.priority === 'high' && (
                          <span className="px-1 py-0.2 rounded text-[9px] font-bold uppercase tracking-wider bg-rose-500/10 text-rose-500">
                            High
                          </span>
                        )}
                      </div>

                      {/* Small Subtitle row */}
                      <div className="flex items-center gap-1.5 text-[11px] text-slate-500 dark:text-slate-400 mt-0.5">
                        <span className="font-medium text-slate-600 dark:text-slate-300">
                          {category ? category.name : 'General'}
                        </span>
                        <span>•</span>
                        <span>{dateBadge}</span>
                        {task.startTime && (
                          <>
                            <span>,</span>
                            <span>{AppDateUtils.formatTime12(task.startTime)}</span>
                          </>
                        )}
                        {task.repeatRule !== 'none' && (
                          <Repeat className="w-3 h-3 text-cyan-500 inline-block ml-0.5" />
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Right Action buttons & Expand down arrow */}
                  <div className="flex items-center gap-1">
                    {/* Star button */}
                    <button
                      onClick={() => toggleStarTask(task.id)}
                      className={`p-1.5 rounded-lg transition-colors ${
                        task.isStarred ? 'text-amber-500' : 'text-slate-400 hover:text-amber-500'
                      }`}
                      title="Star task"
                    >
                      <Star className={`w-3.5 h-3.5 ${task.isStarred ? 'fill-amber-500' : ''}`} />
                    </button>

                    {/* Reschedule button */}
                    {onRescheduleTask && (
                      <button
                        onClick={() => onRescheduleTask(task.id)}
                        className="p-1.5 rounded-lg text-slate-400 hover:text-brand-500"
                        title="Reschedule"
                      >
                        <Calendar className="w-3.5 h-3.5" />
                      </button>
                    )}

                    {/* Edit button */}
                    {onEditTask && (
                      <button
                        onClick={() => onEditTask(task.id)}
                        className="p-1.5 rounded-lg text-slate-400 hover:text-brand-500"
                        title="Edit"
                      >
                        <Edit className="w-3.5 h-3.5" />
                      </button>
                    )}

                    {/* Delete button */}
                    <button
                      onClick={() => deleteTask(task.id)}
                      className="p-1.5 rounded-lg text-slate-400 hover:text-rose-500"
                      title="Delete"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>

                    {/* Down Arrow Expander */}
                    <button
                      onClick={() => toggleExpand(key)}
                      className="p-1 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-transform"
                      aria-label="Expand task details"
                    >
                      {isExpanded ? (
                        <ChevronUp className="w-4 h-4 text-brand-500" />
                      ) : (
                        <ChevronDown className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                </div>

                {/* Expanded Details Section */}
                {isExpanded && (
                  <div className="px-4 py-3 bg-white dark:bg-surface-dark border-t border-slate-200/60 dark:border-surface-dark-border/60 text-xs space-y-3 animate-fade-in">
                    {/* Description / Notes */}
                    {task.description && (
                      <p className="text-slate-600 dark:text-slate-300">{task.description}</p>
                    )}

                    {/* Duration & Recurrence Meta */}
                    <div className="flex items-center gap-3 text-[11px] text-slate-500 dark:text-slate-400 flex-wrap">
                      {task.durationMinutes && (
                        <div className="flex items-center gap-1">
                          <Clock className="w-3 h-3 text-brand-500" />
                          <span>{formatDurationMinutes(task.durationMinutes)}</span>
                        </div>
                      )}
                      {task.repeatRule !== 'none' && (
                        <div className="flex items-center gap-1 text-cyan-600 dark:text-cyan-400">
                          <Repeat className="w-3 h-3" />
                          <span className="capitalize">Repeats {task.repeatRule}</span>
                        </div>
                      )}
                    </div>

                    {/* Subtasks Section */}
                    {childSubtasks.length > 0 && (
                      <div className="space-y-1.5 pt-1">
                        <div className="flex items-center justify-between text-[11px] text-slate-500">
                          <span className="font-semibold flex items-center gap-1">
                            <ListTodo className="w-3 h-3 text-brand-500" />
                            <span>Subtasks</span>
                          </span>
                          <span>
                            {completedSubtasks}/{childSubtasks.length}
                          </span>
                        </div>
                        <SubtasksList
                          parentId={task.id}
                          parentDate={task.date}
                          parentPriority={task.priority}
                        />
                      </div>
                    )}

                    {/* Inline Quick Subtask Adder */}
                    <div className="flex items-center gap-2 pt-1">
                      <input
                        type="text"
                        placeholder="Add a subtask..."
                        value={quickSubtaskText[task.id] || ''}
                        onChange={e =>
                          setQuickSubtaskText(prev => ({ ...prev, [task.id]: e.target.value }))
                        }
                        onKeyDown={e => {
                          if (e.key === 'Enter') handleAddSubtask(task.id, targetDate);
                        }}
                        className="flex-1 px-2.5 py-1.5 text-xs rounded-lg bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border focus:outline-none focus:ring-1 focus:ring-brand-500"
                      />
                      <button
                        onClick={() => handleAddSubtask(task.id, targetDate)}
                        className="px-2.5 py-1.5 rounded-lg bg-brand-500 text-white font-semibold text-xs flex items-center gap-1 hover:bg-brand-600 transition-colors"
                      >
                        <Plus className="w-3.5 h-3.5" />
                        <span>Add</span>
                      </button>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
