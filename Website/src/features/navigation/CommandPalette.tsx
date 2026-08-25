import React, { useState, useEffect } from 'react';
import { Search, Plus, Calendar, CheckSquare, BarChart3, Settings, Moon, Sun, ArrowRight, X, Sparkles } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { useTheme } from '../../core/theme/ThemeContext';
import { CategoryIcon } from '../categories/CategoryIcon';

interface CommandPaletteProps {
  isOpen: boolean;
  onClose: () => void;
  onNavigate: (tab: string) => void;
  onOpenCreateTask: () => void;
  onOpenCreateCategory: () => void;
  onOpenDailySummary: () => void;
  onSelectTask: (taskId: string) => void;
}

export const CommandPalette: React.FC<CommandPaletteProps> = ({
  isOpen,
  onClose,
  onNavigate,
  onOpenCreateTask,
  onOpenCreateCategory,
  onOpenDailySummary,
  onSelectTask,
}) => {
  const [query, setQuery] = useState('');
  const { tasks, categories, categoryMap } = useDayPulseData();
  const { isDark, toggleTheme } = useTheme();

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        if (isOpen) {
          onClose();
        } else {
          // Open
        }
      }
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const filteredTasks = tasks
    .filter(t => t.title.toLowerCase().includes(query.toLowerCase()) || (t.description && t.description.toLowerCase().includes(query.toLowerCase())))
    .slice(0, 5);

  const filteredCategories = categories
    .filter(c => c.name.toLowerCase().includes(query.toLowerCase()))
    .slice(0, 3);

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-20 px-4 bg-black/60 backdrop-blur-sm animate-fade-in" onClick={onClose}>
      <div
        className="w-full max-w-2xl bg-white dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border rounded-2xl shadow-2xl overflow-hidden animate-slide-up"
        onClick={e => e.stopPropagation()}
      >
        {/* Search Input Bar */}
        <div className="flex items-center px-4 py-3.5 border-b border-slate-100 dark:border-surface-dark-border gap-3">
          <Search className="w-5 h-5 text-slate-400" />
          <input
            type="text"
            placeholder="Search tasks, categories, actions... (or navigate)"
            value={query}
            onChange={e => setQuery(e.target.value)}
            autoFocus
            className="flex-1 bg-transparent text-slate-800 dark:text-slate-100 placeholder-slate-400 text-base outline-none"
          />
          <button
            onClick={onClose}
            className="p-1 rounded-lg hover:bg-slate-100 dark:hover:bg-surface-dark-variant text-slate-400"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="max-h-[60vh] overflow-y-auto p-3 space-y-4">
          {/* Quick Actions */}
          <div>
            <div className="text-xs font-semibold text-slate-400 px-3 mb-1 uppercase tracking-wider">Quick Actions</div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-1">
              <button
                onClick={() => {
                  onClose();
                  onOpenCreateTask();
                }}
                className="flex items-center gap-2.5 px-3 py-2 rounded-xl hover:bg-brand-50 dark:hover:bg-brand-900/30 text-left text-sm font-medium text-slate-700 dark:text-slate-200 hover:text-brand-600 dark:hover:text-brand-400 transition-colors"
              >
                <Plus className="w-4 h-4 text-brand-500" />
                <span>Create New Task</span>
              </button>

              <button
                onClick={() => {
                  onClose();
                  onOpenDailySummary();
                }}
                className="flex items-center gap-2.5 px-3 py-2 rounded-xl hover:bg-purple-50 dark:hover:bg-purple-900/30 text-left text-sm font-medium text-slate-700 dark:text-slate-200 hover:text-purple-600 dark:hover:text-purple-400 transition-colors"
              >
                <Sparkles className="w-4 h-4 text-purple-500" />
                <span>Daily Review / Summary</span>
              </button>

              <button
                onClick={() => {
                  onClose();
                  toggleTheme();
                }}
                className="flex items-center gap-2.5 px-3 py-2 rounded-xl hover:bg-amber-50 dark:hover:bg-amber-900/30 text-left text-sm font-medium text-slate-700 dark:text-slate-200 hover:text-amber-600 dark:hover:text-amber-400 transition-colors"
              >
                {isDark ? <Sun className="w-4 h-4 text-amber-500" /> : <Moon className="w-4 h-4 text-indigo-500" />}
                <span>Toggle {isDark ? 'Light' : 'Dark'} Mode</span>
              </button>

              <button
                onClick={() => {
                  onClose();
                  onOpenCreateCategory();
                }}
                className="flex items-center gap-2.5 px-3 py-2 rounded-xl hover:bg-emerald-50 dark:hover:bg-emerald-900/30 text-left text-sm font-medium text-slate-700 dark:text-slate-200 hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors"
              >
                <Plus className="w-4 h-4 text-emerald-500" />
                <span>Create Category</span>
              </button>
            </div>
          </div>

          {/* Navigation Items */}
          <div>
            <div className="text-xs font-semibold text-slate-400 px-3 mb-1 uppercase tracking-wider">Navigation</div>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-1">
              {[
                { id: 'today', label: 'Today', icon: CheckSquare },
                { id: 'tasks', label: 'Tasks', icon: CheckSquare },
                { id: 'calendar', label: 'Calendar', icon: Calendar },
                { id: 'progress', label: 'Me / Analytics', icon: BarChart3 },
                { id: 'planner', label: 'Plan Tomorrow', icon: Sparkles },
                { id: 'settings', label: 'Settings', icon: Settings },
              ].map(item => {
                const Icon = item.icon;
                return (
                  <button
                    key={item.id}
                    onClick={() => {
                      onClose();
                      onNavigate(item.id);
                    }}
                    className="flex items-center gap-2 px-3 py-2 rounded-xl hover:bg-slate-100 dark:hover:bg-surface-dark-variant text-left text-sm text-slate-700 dark:text-slate-200 transition-colors"
                  >
                    <Icon className="w-4 h-4 text-slate-400" />
                    <span>{item.label}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Matching Tasks */}
          {filteredTasks.length > 0 && (
            <div>
              <div className="text-xs font-semibold text-slate-400 px-3 mb-1 uppercase tracking-wider">Matching Tasks</div>
              <div className="space-y-1">
                {filteredTasks.map(task => {
                  const cat = task.categoryId ? categoryMap.get(task.categoryId) : null;
                  return (
                    <button
                      key={task.id}
                      onClick={() => {
                        onClose();
                        onSelectTask(task.id);
                      }}
                      className="w-full flex items-center justify-between px-3 py-2.5 rounded-xl hover:bg-slate-100 dark:hover:bg-surface-dark-variant text-left group transition-colors"
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className="w-2.5 h-2.5 rounded-full flex-shrink-0"
                          style={{ backgroundColor: cat?.colorHex || '#64748B' }}
                        />
                        <span className={`text-sm font-medium ${task.completed ? 'line-through text-slate-400' : 'text-slate-700 dark:text-slate-200'}`}>
                          {task.title}
                        </span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs text-slate-400">{task.date}</span>
                        <ArrowRight className="w-4 h-4 text-slate-300 group-hover:text-brand-500 transition-colors" />
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Matching Categories */}
          {filteredCategories.length > 0 && (
            <div>
              <div className="text-xs font-semibold text-slate-400 px-3 mb-1 uppercase tracking-wider">Categories</div>
              <div className="flex flex-wrap gap-2 px-3">
                {filteredCategories.map(c => (
                  <div
                    key={c.id}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold"
                    style={{ backgroundColor: `${c.colorHex}22`, color: c.colorHex }}
                  >
                    <CategoryIcon iconName={c.iconName} className="w-3.5 h-3.5" />
                    <span>{c.name}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Footer info */}
        <div className="px-4 py-2.5 bg-slate-50 dark:bg-surface-dark-bg/60 border-t border-slate-100 dark:border-surface-dark-border flex items-center justify-between text-xs text-slate-400">
          <div className="flex items-center gap-2">
            <kbd className="px-1.5 py-0.5 rounded bg-slate-200 dark:bg-surface-dark-variant font-mono">ESC</kbd>
            <span>to close</span>
          </div>
          <div>
            <kbd className="px-1.5 py-0.5 rounded bg-slate-200 dark:bg-surface-dark-variant font-mono">Ctrl+K</kbd>
            <span> toggle anywhere</span>
          </div>
        </div>
      </div>
    </div>
  );
};
