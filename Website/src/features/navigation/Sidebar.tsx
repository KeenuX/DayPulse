import React from 'react';
import {
  CheckSquare,
  Calendar,
  BarChart3,
  Sparkles,
  FolderOpen,
  Settings,
  Plus,
  Flame,
  Sun,
  Moon,
  Search,
} from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { useTheme } from '../../core/theme/ThemeContext';
import { ProductivityCalculator } from '../../core/utilities/productivityCalculator';
import { CategoryIcon } from '../categories/CategoryIcon';

interface SidebarProps {
  currentTab: string;
  onSelectTab: (tab: string) => void;
  onOpenCreateTask: () => void;
  onOpenCommandPalette: () => void;
  onSelectCategory?: (categoryId: string) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  onOpenCreateTask,
  onOpenCommandPalette,
  onSelectCategory,
}) => {
  const { tasks, occurrences, categories } = useDayPulseData();
  const { isDark, toggleTheme } = useTheme();

  const streakData = ProductivityCalculator.calculateStreaks(tasks, occurrences);

  const mainNavItems = [
    { id: 'today', label: 'Today', icon: CheckSquare },
    { id: 'tasks', label: 'Tasks', icon: CheckSquare },
    { id: 'calendar', label: 'Calendar', icon: Calendar },
    { id: 'progress', label: 'Me / Analytics', icon: BarChart3 },
    { id: 'planner', label: 'Plan Tomorrow', icon: Sparkles },
    { id: 'categories', label: 'Categories', icon: FolderOpen },
  ];

  return (
    <aside className="hidden md:flex flex-col w-64 bg-surface-light dark:bg-surface-dark border-r border-surface-light-border dark:border-surface-dark-border h-screen sticky top-0 z-30 select-none">
      {/* Brand Header */}
      <div className="p-5 flex items-center justify-between border-b border-surface-light-border/60 dark:border-surface-dark-border/60">
        <div className="flex items-center gap-3 cursor-pointer" onClick={() => onSelectTab('today')}>
          <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-brand-500 to-indigo-500 flex items-center justify-center shadow-lg shadow-brand-500/25">
            <svg viewBox="0 0 128 128" className="w-6 h-6 text-white" fill="none">
              <path
                d="M 28 66 L 46 66 L 56 42 L 72 88 L 84 56 L 94 66 L 102 66"
                stroke="currentColor"
                strokeWidth="10"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </div>
          <div>
            <h1 className="text-lg font-bold text-slate-800 dark:text-white tracking-tight">DayPulse</h1>
            <p className="text-xs text-slate-400 font-medium">Daily Flow & Focus</p>
          </div>
        </div>

        {/* Live Streak Pill */}
        {streakData.currentStreak > 0 && (
          <div
            onClick={() => onSelectTab('progress')}
            className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-500 text-xs font-bold cursor-pointer hover:bg-amber-500/20 transition-colors"
            title={`${streakData.currentStreak} day streak!`}
          >
            <Flame className="w-3.5 h-3.5 fill-amber-500 text-amber-500 animate-pulse" />
            <span>{streakData.currentStreak}d</span>
          </div>
        )}
      </div>

      {/* Quick Search Shortcut */}
      <div className="px-4 pt-4 pb-2">
        <button
          onClick={onOpenCommandPalette}
          className="w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl bg-slate-100 dark:bg-surface-dark-subtle/80 hover:bg-slate-200/80 dark:hover:bg-surface-dark-variant text-slate-400 text-xs transition-colors border border-transparent hover:border-slate-300 dark:hover:border-slate-700"
        >
          <div className="flex items-center gap-2">
            <Search className="w-3.5 h-3.5" />
            <span>Search or command...</span>
          </div>
          <kbd className="px-1.5 py-0.5 rounded bg-white dark:bg-surface-dark font-mono text-[10px] text-slate-500 shadow-sm border border-slate-200 dark:border-slate-700">
            Ctrl K
          </kbd>
        </button>
      </div>

      {/* Primary Action Button */}
      <div className="p-4 pt-2">
        <button
          onClick={onOpenCreateTask}
          className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-gradient-to-r from-brand-500 to-indigo-600 hover:from-brand-600 hover:to-indigo-700 text-white text-sm font-semibold shadow-md shadow-brand-500/25 transition-all duration-200 active:scale-[0.98]"
        >
          <Plus className="w-4 h-4 stroke-[2.5]" />
          <span>New Task</span>
        </button>
      </div>

      {/* Main Navigation Menu */}
      <nav className="flex-1 px-3 py-2 space-y-1 overflow-y-auto">
        <div className="text-[11px] font-bold uppercase tracking-wider text-slate-400 px-3 py-1">Menu</div>
        {mainNavItems.map(item => {
          const Icon = item.icon;
          const isActive = currentTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onSelectTab(item.id)}
              className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-brand-500/10 text-brand-600 dark:text-brand-400 font-semibold'
                  : 'text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-subtle hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              <Icon className={`w-4 h-4 ${isActive ? 'text-brand-500' : 'text-slate-400'}`} />
              <span>{item.label}</span>
            </button>
          );
        })}

        {/* Categories Quick List */}
        {categories.length > 0 && (
          <div className="pt-4">
            <div className="flex items-center justify-between text-[11px] font-bold uppercase tracking-wider text-slate-400 px-3 py-1">
              <span>Categories</span>
              <span className="text-[10px] lowercase font-normal">{categories.length} total</span>
            </div>
            <div className="space-y-0.5 mt-1">
              {categories.slice(0, 5).map(cat => (
                <button
                  key={cat.id}
                  onClick={() => {
                    if (onSelectCategory) {
                      onSelectCategory(cat.id);
                    } else {
                      onSelectTab('tasks');
                    }
                  }}
                  className="w-full flex items-center justify-between px-3 py-1.5 rounded-lg text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-subtle transition-colors group"
                >
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full" style={{ backgroundColor: cat.colorHex }} />
                    <span className="truncate max-w-[120px]">{cat.name}</span>
                  </div>
                  <CategoryIcon iconName={cat.iconName} className="w-3 h-3 text-slate-400 opacity-0 group-hover:opacity-100 transition-opacity" />
                </button>
              ))}
            </div>
          </div>
        )}
      </nav>

      {/* Footer Settings & Theme Switcher */}
      <div className="p-3 border-t border-surface-light-border/60 dark:border-surface-dark-border/60 space-y-1">
        <button
          onClick={toggleTheme}
          className="w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-subtle transition-colors"
        >
          <div className="flex items-center gap-2.5">
            {isDark ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4 text-indigo-500" />}
            <span>{isDark ? 'Light Theme' : 'Dark Theme'}</span>
          </div>
          <span className="text-[10px] text-slate-400 capitalize">{isDark ? 'Dark' : 'Light'}</span>
        </button>

        <button
          onClick={() => onSelectTab('settings')}
          className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs font-medium transition-colors ${
            currentTab === 'settings'
              ? 'bg-brand-500/10 text-brand-600 dark:text-brand-400 font-semibold'
              : 'text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-subtle'
          }`}
        >
          <Settings className="w-4 h-4 text-slate-400" />
          <span>Settings & Data</span>
        </button>
      </div>
    </aside>
  );
};
