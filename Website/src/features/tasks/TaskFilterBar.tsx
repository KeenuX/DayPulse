import React from 'react';
import { Search, Filter, ArrowUpDown, Tag, Flag } from 'lucide-react';
import { TaskFilterStatus, TaskSortOption, TaskPriority } from '../../types/task';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { CategoryIcon } from '../categories/CategoryIcon';

interface TaskFilterBarProps {
  status: TaskFilterStatus;
  onStatusChange: (status: TaskFilterStatus) => void;
  selectedCategory: string | null;
  onCategoryChange: (categoryId: string | null) => void;
  selectedPriority: TaskPriority | 'all';
  onPriorityChange: (priority: TaskPriority | 'all') => void;
  sortBy: TaskSortOption;
  onSortChange: (sort: TaskSortOption) => void;
  searchQuery: string;
  onSearchChange: (query: string) => void;
}

export const TaskFilterBar: React.FC<TaskFilterBarProps> = ({
  status,
  onStatusChange,
  selectedCategory,
  onCategoryChange,
  selectedPriority,
  onPriorityChange,
  sortBy,
  onSortChange,
  searchQuery,
  onSearchChange,
}) => {
  const { categories } = useDayPulseData();

  const statusTabs: { id: TaskFilterStatus; label: string }[] = [
    { id: 'all', label: 'All' },
    { id: 'today', label: 'Today' },
    { id: 'upcoming', label: 'Upcoming' },
    { id: 'completed', label: 'Completed' },
    { id: 'overdue', label: 'Overdue' },
  ];

  return (
    <div className="space-y-3">
      {/* Search and Secondary Filters row */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2.5">
        {/* Search bar */}
        <div className="relative flex-1">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <input
            type="text"
            placeholder="Filter tasks by title or notes..."
            value={searchQuery}
            onChange={e => onSearchChange(e.target.value)}
            className="w-full pl-9.5 pr-4 py-2 rounded-xl bg-surface-light dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border text-xs text-slate-800 dark:text-slate-200 placeholder-slate-400 outline-none focus:border-brand-500 transition-colors shadow-sm"
          />
        </div>

        {/* Filter Dropdowns */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 sm:pb-0">
          {/* Category Dropdown */}
          <select
            value={selectedCategory || ''}
            onChange={e => onCategoryChange(e.target.value ? e.target.value : null)}
            className="px-3 py-2 rounded-xl bg-surface-light dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border text-xs font-medium text-slate-700 dark:text-slate-200 outline-none shadow-sm cursor-pointer"
          >
            <option value="">All Categories</option>
            <option value="general">General (Uncategorized)</option>
            {categories.map(c => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>

          {/* Priority Dropdown */}
          <select
            value={selectedPriority}
            onChange={e => onPriorityChange(e.target.value as TaskPriority | 'all')}
            className="px-3 py-2 rounded-xl bg-surface-light dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border text-xs font-medium text-slate-700 dark:text-slate-200 outline-none shadow-sm cursor-pointer"
          >
            <option value="all">All Priorities</option>
            <option value="high">High Priority</option>
            <option value="medium">Medium Priority</option>
            <option value="low">Low Priority</option>
          </select>

          {/* Sort Dropdown */}
          <select
            value={sortBy}
            onChange={e => onSortChange(e.target.value as TaskSortOption)}
            className="px-3 py-2 rounded-xl bg-surface-light dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border text-xs font-medium text-slate-700 dark:text-slate-200 outline-none shadow-sm cursor-pointer"
          >
            <option value="date">Sort: Date</option>
            <option value="priority">Sort: Priority</option>
            <option value="title">Sort: Title</option>
            <option value="created">Sort: Created</option>
          </select>
        </div>
      </div>

      {/* Status Pills Tabs */}
      <div className="flex items-center gap-1.5 overflow-x-auto pb-1">
        {statusTabs.map(tab => {
          const isActive = status === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => onStatusChange(tab.id)}
              className={`px-4 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap transition-all ${
                isActive
                  ? 'bg-brand-500 text-white shadow-sm shadow-brand-500/20'
                  : 'bg-surface-light dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border text-slate-600 dark:text-slate-300 hover:border-slate-300 dark:hover:border-slate-600'
              }`}
            >
              {tab.label}
            </button>
          );
        })}
      </div>
    </div>
  );
};
