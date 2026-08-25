import React, { useState } from 'react';
import {
  CheckCircle2,
  Circle,
  Calendar,
  Clock,
  Repeat,
  Star,
  MoreVertical,
  Edit,
  Trash2,
  ChevronDown,
  ChevronUp,
  AlertCircle,
  ListTodo,
} from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { Task } from '../../types/task';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { formatDurationMinutes } from '../../core/utilities/durationFormatter';
import { CategoryIcon } from '../categories/CategoryIcon';
import { SubtasksList } from './SubtasksList';

interface TaskCardProps {
  task: Task;
  targetDate?: string;
  onSelect: (taskId: string) => void;
  onEdit: (taskId: string) => void;
  onReschedule: (taskId: string) => void;
}

export const TaskCard: React.FC<TaskCardProps> = ({
  task,
  targetDate,
  onSelect,
  onEdit,
  onReschedule,
}) => {
  const { categoryMap, toggleTaskCompletion, toggleStarTask, deleteTask, tasks } = useDayPulseData();
  const [showSubtasks, setShowSubtasks] = useState(false);
  const [showMenu, setShowMenu] = useState(false);

  const category = task.categoryId ? categoryMap.get(task.categoryId) : null;
  const childSubtasks = tasks.filter(t => t.parentId === task.id);
  const completedSubtasks = childSubtasks.filter(t => t.completed).length;

  const isOverdue = AppDateUtils.isTaskOverdue(task);
  const categoryColor = category?.colorHex || '#64748B';

  return (
    <div
      className={`group relative rounded-2xl bg-surface-light dark:bg-surface-dark border transition-all duration-200 shadow-sm hover:shadow-md ${
        task.completed
          ? 'border-slate-100 dark:border-surface-dark-border/40 opacity-70'
          : 'border-slate-200/80 dark:border-surface-dark-border hover:border-brand-300 dark:hover:border-brand-500/40'
      }`}
    >
      {/* Left Category Accent Strip */}
      <div
        className="absolute left-0 top-3 bottom-3 w-1.5 rounded-r-full"
        style={{ backgroundColor: categoryColor }}
      />

      <div className="p-3.5 pl-4 sm:pl-5">
        <div className="flex items-start justify-between gap-3">
          {/* Checkbox and Task Title */}
          <div className="flex items-start gap-3 flex-1 min-w-0">
            <button
              onClick={() => toggleTaskCompletion(task, targetDate)}
              className="mt-0.5 flex-shrink-0 text-brand-500 hover:scale-110 active:scale-95 transition-transform"
              aria-label={task.completed ? 'Mark pending' : 'Mark completed'}
            >
              {task.completed ? (
                <CheckCircle2 className="w-5 h-5 fill-emerald-500 text-white" />
              ) : (
                <Circle className="w-5 h-5 text-slate-400 dark:text-slate-500 hover:text-brand-500 stroke-[2]" />
              )}
            </button>

            <div className="flex-1 min-w-0 cursor-pointer" onClick={() => onSelect(task.id)}>
              <div className="flex items-center gap-2 flex-wrap">
                <span
                  className={`text-sm font-semibold truncate ${
                    task.completed
                      ? 'line-through text-slate-400 dark:text-slate-500'
                      : 'text-slate-800 dark:text-slate-100'
                  }`}
                >
                  {task.title}
                </span>

                {/* Priority Flag */}
                {task.priority !== 'medium' && (
                  <span
                    className={`px-1.5 py-0.2 rounded text-[10px] font-bold uppercase tracking-wider ${
                      task.priority === 'high'
                        ? 'bg-rose-500/10 text-rose-500'
                        : 'bg-emerald-500/10 text-emerald-500'
                    }`}
                  >
                    {task.priority}
                  </span>
                )}
              </div>

              {task.description && (
                <p className="text-xs text-slate-500 dark:text-slate-400 truncate mt-0.5">
                  {task.description}
                </p>
              )}

              {/* Badges row */}
              <div className="flex items-center gap-2 mt-2 flex-wrap text-[11px]">
                {/* Category Pill */}
                {category && (
                  <div
                    className="flex items-center gap-1 px-2 py-0.5 rounded-md font-semibold"
                    style={{
                      backgroundColor: `${category.colorHex}18`,
                      color: category.colorHex,
                    }}
                  >
                    <CategoryIcon iconName={category.iconName} className="w-3 h-3" />
                    <span>{category.name}</span>
                  </div>
                )}

                {/* Scheduled Time */}
                {task.startTime && (
                  <div className="flex items-center gap-1 text-slate-500 dark:text-slate-400 bg-slate-100 dark:bg-surface-dark-variant px-2 py-0.5 rounded-md">
                    <Clock className="w-3 h-3 text-brand-500" />
                    <span>{AppDateUtils.formatTime12(task.startTime)}</span>
                  </div>
                )}

                {/* Duration */}
                {task.durationMinutes && (
                  <div className="flex items-center gap-1 text-slate-500 dark:text-slate-400 bg-slate-100 dark:bg-surface-dark-variant px-2 py-0.5 rounded-md">
                    <span>{formatDurationMinutes(task.durationMinutes)}</span>
                  </div>
                )}

                {/* Recurrence rule */}
                {task.repeatRule !== 'none' && (
                  <div className="flex items-center gap-1 text-indigo-500 bg-indigo-500/10 px-2 py-0.5 rounded-md font-medium capitalize">
                    <Repeat className="w-3 h-3" />
                    <span>{task.repeatRule}</span>
                  </div>
                )}

                {/* Subtask count trigger */}
                {childSubtasks.length > 0 && (
                  <button
                    onClick={e => {
                      e.stopPropagation();
                      setShowSubtasks(!showSubtasks);
                    }}
                    className="flex items-center gap-1 text-slate-600 dark:text-slate-300 bg-slate-100 dark:bg-surface-dark-variant hover:bg-slate-200 px-2 py-0.5 rounded-md font-medium transition-colors"
                  >
                    <ListTodo className="w-3 h-3 text-brand-500" />
                    <span>
                      {completedSubtasks}/{childSubtasks.length}
                    </span>
                    {showSubtasks ? <ChevronUp className="w-3 h-3" /> : <ChevronDown className="w-3 h-3" />}
                  </button>
                )}
              </div>
            </div>
          </div>

          {/* Right Action buttons */}
          <div className="flex items-center gap-1 opacity-80 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity">
            <button
              onClick={() => toggleStarTask(task.id)}
              className={`p-1.5 rounded-lg transition-colors ${
                task.isStarred ? 'text-amber-500' : 'text-slate-400 hover:text-slate-600 dark:hover:text-white'
              }`}
              title="Star task"
            >
              <Star className={`w-4 h-4 ${task.isStarred ? 'fill-amber-500' : ''}`} />
            </button>

            <button
              onClick={() => onReschedule(task.id)}
              className="p-1.5 rounded-lg text-slate-400 hover:text-brand-500 hover:bg-slate-100 dark:hover:bg-surface-dark-variant"
              title="Reschedule"
            >
              <Calendar className="w-4 h-4" />
            </button>

            <button
              onClick={() => onEdit(task.id)}
              className="p-1.5 rounded-lg text-slate-400 hover:text-brand-500 hover:bg-slate-100 dark:hover:bg-surface-dark-variant"
              title="Edit"
            >
              <Edit className="w-4 h-4" />
            </button>

            <button
              onClick={() => deleteTask(task.id)}
              className="p-1.5 rounded-lg text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-950/20"
              title="Delete"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Expandable Subtasks */}
        {showSubtasks && (
          <SubtasksList
            parentId={task.id}
            parentDate={task.date}
            parentPriority={task.priority}
          />
        )}
      </div>
    </div>
  );
};
