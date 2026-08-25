import React, { useState } from 'react';
import { CheckCircle2, Circle, Plus, Trash2 } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { Task } from '../../types/task';

interface SubtasksListProps {
  parentId: string;
  parentDate: string;
  parentPriority: Task['priority'];
}

export const SubtasksList: React.FC<SubtasksListProps> = ({
  parentId,
  parentDate,
  parentPriority,
}) => {
  const { tasks, toggleTaskCompletion, deleteTask, addTask } = useDayPulseData();
  const [subtaskInput, setSubtaskInput] = useState('');

  const subtasks = tasks.filter(t => t.parentId === parentId);
  if (subtasks.length === 0 && !subtaskInput) {
    // Show quick add subtask input
  }

  const handleAdd = async () => {
    if (!subtaskInput.trim()) return;
    await addTask({
      parentId,
      title: subtaskInput.trim(),
      date: parentDate,
      priority: parentPriority,
      completed: false,
      reminderEnabled: false,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
    });
    setSubtaskInput('');
  };

  const completedCount = subtasks.filter(st => st.completed).length;

  return (
    <div className="mt-3 pt-3 border-t border-slate-100 dark:border-surface-dark-border/60 space-y-2">
      {/* Subtasks header info if multiple */}
      {subtasks.length > 0 && (
        <div className="flex items-center justify-between text-[11px] font-semibold text-slate-400">
          <span>Subtasks</span>
          <span>{completedCount}/{subtasks.length}</span>
        </div>
      )}

      {/* Subtask list */}
      <div className="space-y-1">
        {subtasks.map(st => (
          <div
            key={st.id}
            className="flex items-center justify-between py-1 px-2 rounded-lg hover:bg-slate-50 dark:hover:bg-surface-dark-subtle group transition-colors"
          >
            <button
              onClick={() => toggleTaskCompletion(st)}
              className="flex items-center gap-2 text-left"
            >
              {st.completed ? (
                <CheckCircle2 className="w-4 h-4 text-emerald-500 fill-emerald-500/20 flex-shrink-0" />
              ) : (
                <Circle className="w-4 h-4 text-slate-400 dark:text-slate-500 stroke-[2] flex-shrink-0" />
              )}
              <span
                className={`text-xs ${
                  st.completed ? 'line-through text-slate-400' : 'text-slate-700 dark:text-slate-200'
                }`}
              >
                {st.title}
              </span>
            </button>

            <button
              onClick={() => deleteTask(st.id)}
              className="opacity-0 group-hover:opacity-100 p-1 text-slate-400 hover:text-rose-500 transition-opacity"
            >
              <Trash2 className="w-3.5 h-3.5" />
            </button>
          </div>
        ))}
      </div>

      {/* Inline Quick Add Input */}
      <div className="flex items-center gap-2 pt-1">
        <input
          type="text"
          placeholder="Add a step..."
          value={subtaskInput}
          onChange={e => setSubtaskInput(e.target.value)}
          onKeyDown={e => {
            if (e.key === 'Enter') {
              e.preventDefault();
              handleAdd();
            }
          }}
          className="flex-1 px-2.5 py-1.5 rounded-lg bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border text-xs outline-none text-slate-800 dark:text-slate-200 placeholder-slate-400"
        />
        <button
          onClick={handleAdd}
          className="p-1.5 rounded-lg bg-slate-200 dark:bg-surface-dark-variant hover:bg-slate-300 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300 text-xs font-semibold"
        >
          <Plus className="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
  );
};
