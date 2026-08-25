import React from 'react';
import { CheckSquare, Calendar, BarChart3, Plus, Sparkles, FolderOpen } from 'lucide-react';

interface BottomNavProps {
  currentTab: string;
  onSelectTab: (tab: string) => void;
  onOpenCreateTask: () => void;
}

export const BottomNav: React.FC<BottomNavProps> = ({
  currentTab,
  onSelectTab,
  onOpenCreateTask,
}) => {
  const tabs = [
    { id: 'today', label: 'Today', icon: CheckSquare },
    { id: 'tasks', label: 'Tasks', icon: CheckSquare },
    { id: 'calendar', label: 'Calendar', icon: Calendar },
    { id: 'progress', label: 'Me', icon: BarChart3 },
    { id: 'planner', label: 'Planner', icon: Sparkles },
  ];

  return (
    <div className="md:hidden fixed bottom-0 left-0 right-0 z-40 bg-surface-light/95 dark:bg-surface-dark/95 backdrop-blur-lg border-t border-surface-light-border dark:border-surface-dark-border px-2 py-1.5 flex items-center justify-around shadow-lg">
      {tabs.map(item => {
        const Icon = item.icon;
        const isActive = currentTab === item.id;
        return (
          <button
            key={item.id}
            onClick={() => onSelectTab(item.id)}
            className={`flex flex-col items-center justify-center py-1 px-3 rounded-xl transition-all ${
              isActive ? 'text-brand-500 scale-105' : 'text-slate-400 hover:text-slate-600 dark:hover:text-slate-200'
            }`}
          >
            <Icon className="w-5 h-5 stroke-[2]" />
            <span className={`text-[10px] mt-0.5 ${isActive ? 'font-bold' : 'font-medium'}`}>
              {item.label}
            </span>
          </button>
        );
      })}

      {/* Mobile Floating Action Button (FAB) */}
      <button
        onClick={onOpenCreateTask}
        className="fixed bottom-16 right-4 w-13 h-13 rounded-full bg-gradient-to-r from-brand-500 to-indigo-600 text-white flex items-center justify-center shadow-xl shadow-brand-500/40 active:scale-95 transition-transform"
        aria-label="Add task"
      >
        <Plus className="w-6 h-6 stroke-[2.5]" />
      </button>
    </div>
  );
};
