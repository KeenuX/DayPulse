import React, { useState } from 'react';
import { Plus, ListTodo, CheckSquare, Search } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { Task, TaskFilterStatus, TaskSortOption, TaskPriority } from '../../types/task';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { TaskFilterBar } from './TaskFilterBar';
import { TaskCard } from './TaskCard';

interface TasksPageProps {
  onSelectTask: (taskId: string) => void;
  onEditTask: (taskId: string) => void;
  onRescheduleTask: (taskId: string) => void;
  onOpenCreateTask: () => void;
  initialCategoryFilter?: string | null;
}

export const TasksPage: React.FC<TasksPageProps> = ({
  onSelectTask,
  onEditTask,
  onRescheduleTask,
  onOpenCreateTask,
  initialCategoryFilter,
}) => {
  const { tasks } = useDayPulseData();

  const [status, setStatus] = useState<TaskFilterStatus>('all');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(initialCategoryFilter || null);
  const [selectedPriority, setSelectedPriority] = useState<TaskPriority | 'all'>('all');
  const [sortBy, setSortBy] = useState<TaskSortOption>('date');
  const [searchQuery, setSearchQuery] = useState('');

  React.useEffect(() => {
    if (initialCategoryFilter !== undefined) {
      setSelectedCategory(initialCategoryFilter);
    }
  }, [initialCategoryFilter]);

  const todayStr = AppDateUtils.toIsoDate(new Date());

  // 1. Filter out subtasks from top-level list
  let filtered = tasks.filter(t => !t.parentId);

  // 2. Status Filter
  if (status === 'today') {
    filtered = filtered.filter(t => t.date === todayStr);
  } else if (status === 'upcoming') {
    filtered = filtered.filter(t => t.date > todayStr);
  } else if (status === 'completed') {
    filtered = filtered.filter(t => t.completed);
  } else if (status === 'overdue') {
    filtered = filtered.filter(t => !t.completed && t.date < todayStr);
  }

  // 3. Category Filter
  if (selectedCategory) {
    if (selectedCategory === 'general') {
      filtered = filtered.filter(t => !t.categoryId);
    } else {
      filtered = filtered.filter(t => t.categoryId === selectedCategory);
    }
  }

  // 4. Priority Filter
  if (selectedPriority !== 'all') {
    filtered = filtered.filter(t => t.priority === selectedPriority);
  }

  // 5. Search Query
  if (searchQuery.trim()) {
    const q = searchQuery.toLowerCase();
    filtered = filtered.filter(
      t =>
        t.title.toLowerCase().includes(q) ||
        (t.description && t.description.toLowerCase().includes(q)) ||
        (t.notes && t.notes.toLowerCase().includes(q))
    );
  }

  // 6. Sort
  filtered.sort((a, b) => {
    if (sortBy === 'date') {
      return a.date.localeCompare(b.date) || (a.startTime || '').localeCompare(b.startTime || '');
    }
    if (sortBy === 'priority') {
      const pWeights = { high: 3, medium: 2, low: 1 };
      return pWeights[b.priority] - pWeights[a.priority];
    }
    if (sortBy === 'title') {
      return a.title.localeCompare(b.title);
    }
    if (sortBy === 'created') {
      return b.createdAt.localeCompare(a.createdAt);
    }
    return 0;
  });

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-24 md:pb-12 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-black text-slate-900 dark:text-white tracking-tight">Tasks</h2>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            {filtered.length} task{filtered.length === 1 ? '' : 's'} matching criteria
          </p>
        </div>

        <button
          onClick={onOpenCreateTask}
          className="flex items-center gap-2 px-4 py-2.5 rounded-2xl bg-brand-500 hover:bg-brand-600 text-white text-xs font-bold shadow-md shadow-brand-500/20 active:scale-95 transition-all"
        >
          <Plus className="w-4 h-4 stroke-[2.5]" />
          <span>New Task</span>
        </button>
      </div>

      {/* Filter Bar */}
      <TaskFilterBar
        status={status}
        onStatusChange={setStatus}
        selectedCategory={selectedCategory}
        onCategoryChange={setSelectedCategory}
        selectedPriority={selectedPriority}
        onPriorityChange={setSelectedPriority}
        sortBy={sortBy}
        onSortChange={setSortBy}
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
      />

      {/* Task List */}
      {filtered.length > 0 ? (
        <div className="space-y-2.5">
          {filtered.map(task => (
            <TaskCard
              key={task.id}
              task={task}
              onSelect={onSelectTask}
              onEdit={onEditTask}
              onReschedule={onRescheduleTask}
            />
          ))}
        </div>
      ) : (
        /* Empty State */
        <div className="text-center py-16 px-4 rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border space-y-3">
          <div className="w-14 h-14 rounded-2xl bg-slate-100 dark:bg-surface-dark-variant text-slate-400 flex items-center justify-center mx-auto">
            <ListTodo className="w-7 h-7" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-slate-800 dark:text-white">No tasks found</h3>
            <p className="text-xs text-slate-400 mt-0.5 max-w-xs mx-auto">
              No tasks match the active filters or search terms. Try clearing filters or create a new task.
            </p>
          </div>
          <button
            onClick={onOpenCreateTask}
            className="px-4 py-2 rounded-xl bg-brand-500 hover:bg-brand-600 text-white text-xs font-bold shadow-sm"
          >
            Create Task
          </button>
        </div>
      )}
    </div>
  );
};
