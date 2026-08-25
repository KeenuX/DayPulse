import React, { useState, useEffect } from 'react';
import {
  X,
  Calendar as CalendarIcon,
  Clock,
  Repeat,
  Bell,
  Check,
  Plus,
  Trash2,
  AlertCircle,
  Flag,
  FileText,
} from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { Task, TaskPriority } from '../../types/task';
import { RepeatRule, RecurrenceEndType } from '../../types/recurrence';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { CategoryIcon } from '../categories/CategoryIcon';
import { addDays } from 'date-fns';

interface CreateEditTaskModalProps {
  isOpen: boolean;
  onClose: () => void;
  editTaskId?: string | null;
  initialDate?: string;
  onOpenCreateCategory?: () => void;
}

export const CreateEditTaskModal: React.FC<CreateEditTaskModalProps> = ({
  isOpen,
  onClose,
  editTaskId,
  initialDate,
  onOpenCreateCategory,
}) => {
  const { tasks, categories, addTask, updateTask } = useDayPulseData();

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [categoryId, setCategoryId] = useState<string | null>(null);
  const [date, setDate] = useState(initialDate || AppDateUtils.toIsoDate(new Date()));
  const [startTime, setStartTime] = useState<string>('');
  const [endTime, setEndTime] = useState<string>('');
  const [durationMinutes, setDurationMinutes] = useState<number | null>(null);
  const [priority, setPriority] = useState<TaskPriority>('medium');
  const [reminderEnabled, setReminderEnabled] = useState(false);
  const [reminderOffset, setReminderOffset] = useState<number>(0);
  const [repeatRule, setRepeatRule] = useState<RepeatRule>('none');
  const [repeatEndType, setRepeatEndType] = useState<RecurrenceEndType>('never');
  const [repeatEndDate, setRepeatEndDate] = useState<string>('');
  const [repeatEndCount, setRepeatEndCount] = useState<number | null>(null);
  const [repeatInterval, setRepeatInterval] = useState<number>(1);
  const [repeatDaysOfWeek, setRepeatDaysOfWeek] = useState<number[]>([1, 2, 3, 4, 5]);
  const [notes, setNotes] = useState('');

  // Subtasks
  const [subtasks, setSubtasks] = useState<string[]>([]);
  const [subtaskInput, setSubtaskInput] = useState('');

  useEffect(() => {
    if (editTaskId) {
      const task = tasks.find(t => t.id === editTaskId);
      if (task) {
        setTitle(task.title);
        setDescription(task.description || '');
        setCategoryId(task.categoryId || null);
        setDate(task.date);
        setStartTime(task.startTime || '');
        setEndTime(task.endTime || '');
        setDurationMinutes(task.durationMinutes || null);
        setPriority(task.priority);
        setReminderEnabled(task.reminderEnabled);
        setReminderOffset(task.reminderOffset || 0);
        setRepeatRule(task.repeatRule);
        setRepeatEndType(task.repeatEndType);
        setRepeatEndDate(task.repeatEndDate || '');
        setRepeatEndCount(task.repeatEndCount || null);
        setRepeatInterval(task.repeatInterval || 1);
        setRepeatDaysOfWeek(task.repeatDaysOfWeek || [1, 2, 3, 4, 5]);
        setNotes(task.notes || '');
      }
    } else {
      // Reset form
      setTitle('');
      setDescription('');
      setCategoryId(null);
      setDate(initialDate || AppDateUtils.toIsoDate(new Date()));
      setStartTime('');
      setEndTime('');
      setDurationMinutes(null);
      setPriority('medium');
      setReminderEnabled(false);
      setReminderOffset(0);
      setRepeatRule('none');
      setRepeatEndType('never');
      setRepeatEndDate('');
      setRepeatEndCount(null);
      setRepeatInterval(1);
      setRepeatDaysOfWeek([1, 2, 3, 4, 5]);
      setNotes('');
      setSubtasks([]);
      setSubtaskInput('');
    }
  }, [editTaskId, initialDate, isOpen, tasks]);

  if (!isOpen) return null;

  const handleAddSubtask = () => {
    if (subtaskInput.trim()) {
      setSubtasks([...subtasks, subtaskInput.trim()]);
      setSubtaskInput('');
    }
  };

  const handleRemoveSubtask = (index: number) => {
    setSubtasks(subtasks.filter((_, i) => i !== index));
  };

  const toggleDayOfWeek = (day: number) => {
    if (repeatDaysOfWeek.includes(day)) {
      if (repeatDaysOfWeek.length > 1) {
        setRepeatDaysOfWeek(repeatDaysOfWeek.filter(d => d !== day));
      }
    } else {
      setRepeatDaysOfWeek([...repeatDaysOfWeek, day].sort());
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    // Auto-capture any pending subtask text
    const finalSubtasks = [...subtasks];
    if (subtaskInput.trim()) {
      finalSubtasks.push(subtaskInput.trim());
    }

    const taskPayload = {
      title: title.trim(),
      description: description.trim() || undefined,
      categoryId: categoryId || null,
      date,
      startTime: startTime || null,
      endTime: endTime || null,
      durationMinutes: durationMinutes || null,
      priority,
      completed: false,
      reminderEnabled,
      reminderOffset: reminderEnabled ? reminderOffset : undefined,
      repeatRule,
      repeatEndType,
      repeatEndDate: repeatEndType === 'untilDate' ? repeatEndDate : null,
      repeatEndCount: repeatEndType === 'afterOccurrences' ? repeatEndCount : null,
      repeatInterval: repeatInterval > 0 ? repeatInterval : 1,
      repeatDaysOfWeek: repeatRule === 'weekly' ? repeatDaysOfWeek : null,
      notes: notes.trim() || null,
    };

    if (editTaskId) {
      await updateTask(editTaskId, taskPayload);
    } else {
      await addTask(taskPayload, finalSubtasks);
    }

    onClose();
  };

  const todayStr = AppDateUtils.toIsoDate(new Date());
  const tomorrowStr = AppDateUtils.toIsoDate(addDays(new Date(), 1));

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in overflow-y-auto" onClick={onClose}>
      <div
        className="w-full max-w-2xl bg-white dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border rounded-3xl shadow-2xl overflow-hidden my-8 animate-slide-up"
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-100 dark:border-surface-dark-border flex items-center justify-between">
          <h2 className="text-lg font-bold text-slate-800 dark:text-white">
            {editTaskId ? 'Edit Task' : 'Create New Task'}
          </h2>
          <button
            onClick={onClose}
            className="p-1.5 rounded-xl hover:bg-slate-100 dark:hover:bg-surface-dark-variant text-slate-400"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6 max-h-[80vh] overflow-y-auto">
          {/* Title input */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              Task Title <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              placeholder="What do you need to do?"
              value={title}
              onChange={e => setTitle(e.target.value)}
              required
              autoFocus
              className="w-full px-4 py-3 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border focus:border-brand-500 text-slate-900 dark:text-white text-base outline-none transition-colors"
            />
          </div>

          {/* Description */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              Description (Optional)
            </label>
            <input
              type="text"
              placeholder="Add brief details or context..."
              value={description}
              onChange={e => setDescription(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border focus:border-brand-500 text-slate-800 dark:text-slate-200 text-sm outline-none transition-colors"
            />
          </div>

          {/* Category Selector */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="text-xs font-bold uppercase tracking-wider text-slate-400">Category</label>
              {onOpenCreateCategory && (
                <button
                  type="button"
                  onClick={onOpenCreateCategory}
                  className="text-xs font-semibold text-brand-500 hover:text-brand-600 flex items-center gap-1"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span>New Category</span>
                </button>
              )}
            </div>

            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => setCategoryId(null)}
                className={`flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold border transition-all ${
                  categoryId === null
                    ? 'bg-slate-800 text-white dark:bg-white dark:text-slate-900 border-transparent shadow-sm'
                    : 'bg-slate-100 dark:bg-surface-dark-subtle text-slate-600 dark:text-slate-300 border-transparent hover:border-slate-300 dark:hover:border-slate-700'
                }`}
              >
                <div className="w-2.5 h-2.5 rounded-full bg-slate-400" />
                <span>General (Uncategorized)</span>
              </button>

              {categories.map(cat => {
                const isSelected = categoryId === cat.id;
                return (
                  <button
                    key={cat.id}
                    type="button"
                    onClick={() => setCategoryId(cat.id)}
                    className={`flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold border transition-all ${
                      isSelected
                        ? 'border-transparent text-white shadow-sm scale-105'
                        : 'bg-slate-100 dark:bg-surface-dark-subtle text-slate-700 dark:text-slate-300 border-transparent hover:border-slate-300 dark:hover:border-slate-700'
                    }`}
                    style={isSelected ? { backgroundColor: cat.colorHex } : undefined}
                  >
                    <CategoryIcon iconName={cat.iconName} className="w-3.5 h-3.5" />
                    <span>{cat.name}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Date & Quick Date Pills */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1.5">
                Date
              </label>
              <div className="flex items-center gap-2">
                <input
                  type="date"
                  value={date}
                  onChange={e => setDate(e.target.value)}
                  className="flex-1 px-3.5 py-2.5 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border text-slate-800 dark:text-slate-200 text-sm outline-none"
                />
              </div>
              <div className="flex gap-2 mt-2">
                <button
                  type="button"
                  onClick={() => setDate(todayStr)}
                  className={`px-2.5 py-1 rounded-lg text-xs font-medium border ${
                    date === todayStr
                      ? 'bg-brand-500/10 border-brand-500/30 text-brand-600 dark:text-brand-400 font-semibold'
                      : 'bg-slate-100 dark:bg-surface-dark-subtle border-transparent text-slate-500'
                  }`}
                >
                  Today
                </button>
                <button
                  type="button"
                  onClick={() => setDate(tomorrowStr)}
                  className={`px-2.5 py-1 rounded-lg text-xs font-medium border ${
                    date === tomorrowStr
                      ? 'bg-brand-500/10 border-brand-500/30 text-brand-600 dark:text-brand-400 font-semibold'
                      : 'bg-slate-100 dark:bg-surface-dark-subtle border-transparent text-slate-500'
                  }`}
                >
                  Tomorrow
                </button>
              </div>
            </div>

            {/* Priority */}
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1.5">
                Priority
              </label>
              <div className="grid grid-cols-3 gap-2">
                {[
                  { value: 'low', label: 'Low', color: 'text-emerald-500 border-emerald-500/30 bg-emerald-500/10' },
                  { value: 'medium', label: 'Medium', color: 'text-amber-500 border-amber-500/30 bg-amber-500/10' },
                  { value: 'high', label: 'High', color: 'text-rose-500 border-rose-500/30 bg-rose-500/10' },
                ].map(p => (
                  <button
                    key={p.value}
                    type="button"
                    onClick={() => setPriority(p.value as TaskPriority)}
                    className={`py-2 px-2 rounded-xl text-xs font-bold border transition-all flex items-center justify-center gap-1.5 ${
                      priority === p.value
                        ? `${p.color} ring-2 ring-offset-1 ring-slate-400/20`
                        : 'bg-slate-100 dark:bg-surface-dark-subtle border-transparent text-slate-500 dark:text-slate-400'
                    }`}
                  >
                    <Flag className="w-3.5 h-3.5" />
                    <span>{p.label}</span>
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Time & Duration */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1.5">
                Start Time
              </label>
              <input
                type="time"
                value={startTime}
                onChange={e => setStartTime(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border text-slate-800 dark:text-slate-200 text-sm outline-none"
              />
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1.5">
                End Time
              </label>
              <input
                type="time"
                value={endTime}
                onChange={e => setEndTime(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border text-slate-800 dark:text-slate-200 text-sm outline-none"
              />
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1.5">
                Duration (min)
              </label>
              <input
                type="number"
                min="0"
                step="5"
                placeholder="e.g. 30"
                value={durationMinutes || ''}
                onChange={e => setDurationMinutes(e.target.value ? parseInt(e.target.value, 10) : null)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border text-slate-800 dark:text-slate-200 text-sm outline-none"
              />
            </div>
          </div>

          {/* Recurrence Rule Engine */}
          <div className="p-4 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200/80 dark:border-surface-dark-border space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Repeat className="w-4 h-4 text-brand-500" />
                <span className="text-xs font-bold uppercase tracking-wider text-slate-700 dark:text-slate-200">
                  Repeat Schedule
                </span>
              </div>
            </div>

            <div className="flex flex-wrap gap-2">
              {[
                { value: 'none', label: 'Does not repeat' },
                { value: 'daily', label: 'Daily' },
                { value: 'weekdays', label: 'Weekdays (Mon-Fri)' },
                { value: 'weekly', label: 'Weekly' },
                { value: 'monthly', label: 'Monthly' },
                { value: 'custom', label: 'Custom' },
              ].map(r => (
                <button
                  key={r.value}
                  type="button"
                  onClick={() => setRepeatRule(r.value as RepeatRule)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-semibold border transition-all ${
                    repeatRule === r.value
                      ? 'bg-brand-500 text-white border-brand-500 shadow-sm'
                      : 'bg-white dark:bg-surface-dark text-slate-600 dark:text-slate-300 border-slate-200 dark:border-surface-dark-border hover:border-brand-300'
                  }`}
                >
                  {r.label}
                </button>
              ))}
            </div>

            {/* Weekly Days selection */}
            {repeatRule === 'weekly' && (
              <div>
                <label className="block text-xs font-medium text-slate-400 mb-2">Repeat on days:</label>
                <div className="flex gap-1.5">
                  {[
                    { day: 1, label: 'M' },
                    { day: 2, label: 'T' },
                    { day: 3, label: 'W' },
                    { day: 4, label: 'T' },
                    { day: 5, label: 'F' },
                    { day: 6, label: 'S' },
                    { day: 7, label: 'S' },
                  ].map(d => {
                    const isSelected = repeatDaysOfWeek.includes(d.day);
                    return (
                      <button
                        key={d.day}
                        type="button"
                        onClick={() => toggleDayOfWeek(d.day)}
                        className={`w-8 h-8 rounded-full text-xs font-bold transition-all ${
                          isSelected
                            ? 'bg-brand-500 text-white shadow-sm'
                            : 'bg-white dark:bg-surface-dark text-slate-500 border border-slate-200 dark:border-surface-dark-border'
                        }`}
                      >
                        {d.label}
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Recurrence End Conditions */}
            {repeatRule !== 'none' && (
              <div className="pt-2 border-t border-slate-200 dark:border-surface-dark-border/60 grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Ends</label>
                  <select
                    value={repeatEndType}
                    onChange={e => setRepeatEndType(e.target.value as RecurrenceEndType)}
                    className="w-full px-3 py-2 rounded-xl bg-white dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border text-xs text-slate-800 dark:text-slate-200 outline-none"
                  >
                    <option value="never">Never (repeats indefinitely)</option>
                    <option value="untilDate">On date</option>
                    <option value="afterOccurrences">After number of occurrences</option>
                  </select>
                </div>

                {repeatEndType === 'untilDate' && (
                  <div>
                    <label className="block text-xs font-medium text-slate-400 mb-1">End Date</label>
                    <input
                      type="date"
                      value={repeatEndDate}
                      onChange={e => setRepeatEndDate(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-white dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border text-xs text-slate-800 dark:text-slate-200 outline-none"
                    />
                  </div>
                )}

                {repeatEndType === 'afterOccurrences' && (
                  <div>
                    <label className="block text-xs font-medium text-slate-400 mb-1">Occurrences Count</label>
                    <input
                      type="number"
                      min="1"
                      placeholder="e.g. 10"
                      value={repeatEndCount || ''}
                      onChange={e => setRepeatEndCount(e.target.value ? parseInt(e.target.value, 10) : null)}
                      className="w-full px-3 py-2 rounded-xl bg-white dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border text-xs text-slate-800 dark:text-slate-200 outline-none"
                    />
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Subtasks Builder (Hierarchical checklist) */}
          {!editTaskId && (
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-2">
                Subtasks / Checklist
              </label>

              {subtasks.length > 0 && (
                <div className="space-y-2 mb-3">
                  {subtasks.map((st, i) => (
                    <div
                      key={i}
                      className="flex items-center justify-between px-3 py-2 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200/80 dark:border-surface-dark-border text-xs text-slate-800 dark:text-slate-200"
                    >
                      <div className="flex items-center gap-2">
                        <div className="w-1.5 h-1.5 rounded-full bg-brand-500" />
                        <span>{st}</span>
                      </div>
                      <button
                        type="button"
                        onClick={() => handleRemoveSubtask(i)}
                        className="text-slate-400 hover:text-rose-500 p-1"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  ))}
                </div>
              )}

              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder="Add a subtask step..."
                  value={subtaskInput}
                  onChange={e => setSubtaskInput(e.target.value)}
                  onKeyDown={e => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      handleAddSubtask();
                    }
                  }}
                  className="flex-1 px-3.5 py-2 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border text-xs outline-none"
                />
                <button
                  type="button"
                  onClick={handleAddSubtask}
                  className="px-3.5 py-2 rounded-xl bg-slate-200 dark:bg-surface-dark-variant hover:bg-slate-300 dark:hover:bg-slate-700 text-xs font-semibold text-slate-700 dark:text-slate-200"
                >
                  Add
                </button>
              </div>
            </div>
          )}

          {/* Notes */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              Notes
            </label>
            <textarea
              rows={2}
              placeholder="Additional thoughts, markdown links, or reflections..."
              value={notes}
              onChange={e => setNotes(e.target.value)}
              className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border text-slate-800 dark:text-slate-200 text-xs outline-none resize-none"
            />
          </div>

          {/* Submit / Cancel Buttons */}
          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100 dark:border-surface-dark-border">
            <button
              type="button"
              onClick={onClose}
              className="px-5 py-2.5 rounded-xl text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-subtle"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-6 py-2.5 rounded-xl bg-gradient-to-r from-brand-500 to-indigo-600 hover:from-brand-600 hover:to-indigo-700 text-white text-sm font-semibold shadow-md shadow-brand-500/25 active:scale-95 transition-transform"
            >
              {editTaskId ? 'Save Changes' : 'Create Task'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
