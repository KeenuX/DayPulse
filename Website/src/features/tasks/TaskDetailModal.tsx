import React, { useState } from 'react';
import {
  X,
  Calendar,
  Clock,
  Repeat,
  Bell,
  Star,
  Trash2,
  Edit,
  CheckCircle2,
  Circle,
  Plus,
  ArrowRight,
  Flag,
  FileText,
} from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { formatDurationMinutes } from '../../core/utilities/durationFormatter';
import { CategoryIcon } from '../categories/CategoryIcon';

interface TaskDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  taskId: string | null;
  onEdit: (taskId: string) => void;
  onReschedule: (taskId: string) => void;
}

export const TaskDetailModal: React.FC<TaskDetailModalProps> = ({
  isOpen,
  onClose,
  taskId,
  onEdit,
  onReschedule,
}) => {
  const { tasks, categoryMap, toggleTaskCompletion, toggleStarTask, deleteTask, addTask, updateTask } = useDayPulseData();
  const [subtaskInput, setSubtaskInput] = useState('');

  if (!isOpen || !taskId) return null;

  const task = tasks.find(t => t.id === taskId);
  if (!task) return null;

  const category = task.categoryId ? categoryMap.get(task.categoryId) : null;
  const childSubtasks = tasks.filter(t => t.parentId === task.id);
  const completedSubtasks = childSubtasks.filter(t => t.completed).length;
  const subtaskProgress = childSubtasks.length > 0 ? (completedSubtasks / childSubtasks.length) * 100 : 0;

  const handleAddChildSubtask = async () => {
    if (!subtaskInput.trim()) return;
    await addTask({
      parentId: task.id,
      title: subtaskInput.trim(),
      date: task.date,
      priority: task.priority,
      completed: false,
      reminderEnabled: false,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
    });
    setSubtaskInput('');
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in" onClick={onClose}>
      <div
        className="w-full max-w-xl bg-white dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border rounded-3xl shadow-2xl overflow-hidden animate-slide-up"
        onClick={e => e.stopPropagation()}
      >
        {/* Header Strip with Category color */}
        <div
          className="h-2.5 w-full"
          style={{ backgroundColor: category?.colorHex || '#4F75FF' }}
        />

        <div className="p-6 space-y-6 max-h-[85vh] overflow-y-auto">
          {/* Top Row: Category, Star & Close */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div
                className="flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold"
                style={{
                  backgroundColor: category ? `${category.colorHex}22` : '#64748B22',
                  color: category?.colorHex || '#64748B',
                }}
              >
                <CategoryIcon iconName={category?.iconName} className="w-3.5 h-3.5" />
                <span>{category ? category.name : 'General'}</span>
              </div>

              {/* Priority badge */}
              <span
                className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold uppercase tracking-wider ${
                  task.priority === 'high'
                    ? 'bg-rose-500/10 text-rose-500 border border-rose-500/20'
                    : task.priority === 'medium'
                    ? 'bg-amber-500/10 text-amber-500 border border-amber-500/20'
                    : 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20'
                }`}
              >
                {task.priority}
              </span>
            </div>

            <div className="flex items-center gap-1">
              <button
                onClick={() => toggleStarTask(task.id)}
                className={`p-2 rounded-xl transition-colors ${
                  task.isStarred ? 'text-amber-500 bg-amber-500/10' : 'text-slate-400 hover:text-slate-600 dark:hover:text-white'
                }`}
              >
                <Star className={`w-5 h-5 ${task.isStarred ? 'fill-amber-500' : ''}`} />
              </button>

              <button
                onClick={onClose}
                className="p-2 rounded-xl text-slate-400 hover:text-slate-600 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-surface-dark-variant"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* Title & Checkbox */}
          <div className="flex items-start gap-3">
            <button
              onClick={() => toggleTaskCompletion(task)}
              className="mt-1 flex-shrink-0 text-brand-500 hover:scale-110 active:scale-95 transition-transform"
            >
              {task.completed ? (
                <CheckCircle2 className="w-6 h-6 fill-emerald-500 text-white" />
              ) : (
                <Circle className="w-6 h-6 text-slate-400 dark:text-slate-500 hover:text-brand-500 stroke-[2]" />
              )}
            </button>

            <div className="flex-1">
              <h2
                className={`text-xl font-bold ${
                  task.completed ? 'line-through text-slate-400 dark:text-slate-500' : 'text-slate-900 dark:text-white'
                }`}
              >
                {task.title}
              </h2>
              {task.description && (
                <p className="text-sm text-slate-600 dark:text-slate-300 mt-1.5 leading-relaxed">
                  {task.description}
                </p>
              )}
            </div>
          </div>

          {/* Metadata Cards Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5 p-4 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-100 dark:border-surface-dark-border text-xs">
            <div className="flex items-center gap-2 text-slate-600 dark:text-slate-300">
              <Calendar className="w-4 h-4 text-brand-500" />
              <span>{AppDateUtils.formatShortDate(task.date)}</span>
            </div>

            {task.startTime && (
              <div className="flex items-center gap-2 text-slate-600 dark:text-slate-300">
                <Clock className="w-4 h-4 text-brand-500" />
                <span>{AppDateUtils.formatTime12(task.startTime)}</span>
              </div>
            )}

            {task.durationMinutes && (
              <div className="flex items-center gap-2 text-slate-600 dark:text-slate-300">
                <Clock className="w-4 h-4 text-amber-500" />
                <span>{formatDurationMinutes(task.durationMinutes)}</span>
              </div>
            )}

            {task.repeatRule !== 'none' && (
              <div className="flex items-center gap-2 text-slate-600 dark:text-slate-300 capitalize">
                <Repeat className="w-4 h-4 text-indigo-500" />
                <span>Repeats {task.repeatRule}</span>
              </div>
            )}

            {task.reminderEnabled && (
              <div className="flex items-center gap-2 text-slate-600 dark:text-slate-300">
                <Bell className="w-4 h-4 text-emerald-500" />
                <span>Alert on</span>
              </div>
            )}
          </div>

          {/* Subtasks Section */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Subtasks ({completedSubtasks}/{childSubtasks.length})
              </span>
              {childSubtasks.length > 0 && (
                <span className="text-xs font-semibold text-brand-500">{Math.round(subtaskProgress)}%</span>
              )}
            </div>

            {/* Progress bar */}
            {childSubtasks.length > 0 && (
              <div className="w-full h-1.5 rounded-full bg-slate-100 dark:bg-surface-dark-variant overflow-hidden">
                <div
                  className="h-full bg-emerald-500 rounded-full transition-all duration-300"
                  style={{ width: `${subtaskProgress}%` }}
                />
              </div>
            )}

            {/* Subtask Items */}
            <div className="space-y-1.5">
              {childSubtasks.map(st => (
                <div
                  key={st.id}
                  className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle hover:bg-slate-100 dark:hover:bg-surface-dark-variant transition-colors"
                >
                  <div className="flex items-center gap-2.5">
                    <button
                      onClick={() => toggleTaskCompletion(st)}
                      className="text-brand-500"
                    >
                      {st.completed ? (
                        <CheckCircle2 className="w-4 h-4 fill-emerald-500 text-white" />
                      ) : (
                        <Circle className="w-4 h-4 text-slate-400 stroke-[2]" />
                      )}
                    </button>
                    <span
                      className={`text-xs font-medium ${
                        st.completed ? 'line-through text-slate-400' : 'text-slate-700 dark:text-slate-200'
                      }`}
                    >
                      {st.title}
                    </span>
                  </div>

                  <button
                    onClick={() => deleteTask(st.id)}
                    className="p-1 text-slate-400 hover:text-rose-500"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              ))}
            </div>

            {/* Add Subtask input */}
            <div className="flex gap-2 pt-1">
              <input
                type="text"
                placeholder="Add subtask step..."
                value={subtaskInput}
                onChange={e => setSubtaskInput(e.target.value)}
                onKeyDown={e => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    handleAddChildSubtask();
                  }
                }}
                className="flex-1 px-3.5 py-2 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border text-xs outline-none"
              />
              <button
                onClick={handleAddChildSubtask}
                className="px-3.5 py-2 rounded-xl bg-slate-200 dark:bg-surface-dark-variant hover:bg-slate-300 text-xs font-bold text-slate-700 dark:text-slate-200"
              >
                Add
              </button>
            </div>
          </div>

          {/* Notes Section */}
          {task.notes && (
            <div className="p-4 rounded-2xl bg-amber-500/5 border border-amber-500/15 space-y-1">
              <div className="flex items-center gap-2 text-xs font-bold text-amber-500 uppercase tracking-wider">
                <FileText className="w-3.5 h-3.5" />
                <span>Notes & Reflection</span>
              </div>
              <p className="text-xs text-slate-700 dark:text-slate-300 whitespace-pre-wrap leading-relaxed">
                {task.notes}
              </p>
            </div>
          )}

          {/* Footer Action Buttons */}
          <div className="flex items-center justify-between pt-4 border-t border-slate-100 dark:border-surface-dark-border">
            <button
              onClick={() => {
                deleteTask(task.id);
                onClose();
              }}
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-950/30 transition-colors"
            >
              <Trash2 className="w-4 h-4" />
              <span>Delete</span>
            </button>

            <div className="flex items-center gap-2">
              <button
                onClick={() => {
                  onClose();
                  onReschedule(task.id);
                }}
                className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold text-slate-700 dark:text-slate-200 bg-slate-100 dark:bg-surface-dark-variant hover:bg-slate-200 transition-colors"
              >
                <Calendar className="w-4 h-4" />
                <span>Reschedule</span>
              </button>

              <button
                onClick={() => {
                  onClose();
                  onEdit(task.id);
                }}
                className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold text-white bg-brand-500 hover:bg-brand-600 shadow-md shadow-brand-500/25 active:scale-95 transition-all"
              >
                <Edit className="w-4 h-4" />
                <span>Edit Task</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
