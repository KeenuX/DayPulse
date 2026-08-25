import React, { useState } from 'react';
import { Calendar as CalendarIcon, Grid3X3, Columns3, Clock } from 'lucide-react';
import { MonthGridView } from './MonthGridView';
import { WeekTimelineView } from './WeekTimelineView';
import { DayTimelineView } from './DayTimelineView';

type CalendarViewMode = 'month' | 'week' | 'day';

interface CalendarPageProps {
  onSelectTask: (taskId: string) => void;
  onEditTask: (taskId: string) => void;
  onRescheduleTask: (taskId: string) => void;
  onOpenCreateTaskForDate: (dateStr: string) => void;
}

export const CalendarPage: React.FC<CalendarPageProps> = ({
  onSelectTask,
  onEditTask,
  onRescheduleTask,
  onOpenCreateTaskForDate,
}) => {
  const [viewMode, setViewMode] = useState<CalendarViewMode>('month');
  const [currentDate, setCurrentDate] = useState<Date>(new Date());
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());

  const viewTabs: { id: CalendarViewMode; label: string; icon: React.FC<{ className?: string }> }[] = [
    { id: 'month', label: 'Month', icon: Grid3X3 },
    { id: 'week', label: 'Week', icon: Columns3 },
    { id: 'day', label: 'Day', icon: Clock },
  ];

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-24 md:pb-12 animate-fade-in">
      {/* Top Header with Mode Switcher */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-black text-slate-900 dark:text-white tracking-tight">Calendar</h2>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            Plan, organize, and inspect your monthly schedule
          </p>
        </div>

        {/* View Switcher Pills */}
        <div className="flex items-center p-1 bg-surface-light dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border rounded-2xl shadow-sm">
          {viewTabs.map(tab => {
            const Icon = tab.icon;
            const isActive = viewMode === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setViewMode(tab.id)}
                className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all ${
                  isActive
                    ? 'bg-brand-500 text-white shadow-sm shadow-brand-500/20'
                    : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
                }`}
              >
                <Icon className="w-3.5 h-3.5" />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Dynamic Views */}
      {viewMode === 'month' && (
        <MonthGridView
          currentDate={currentDate}
          onCurrentDateChange={setCurrentDate}
          selectedDate={selectedDate}
          onSelectedDateChange={setSelectedDate}
          onSelectTask={onSelectTask}
          onEditTask={onEditTask}
          onRescheduleTask={onRescheduleTask}
          onOpenCreateTaskForDate={onOpenCreateTaskForDate}
        />
      )}

      {viewMode === 'week' && (
        <WeekTimelineView
          currentDate={currentDate}
          onCurrentDateChange={setCurrentDate}
          onSelectTask={onSelectTask}
          onOpenCreateTaskForDate={onOpenCreateTaskForDate}
        />
      )}

      {viewMode === 'day' && (
        <DayTimelineView
          selectedDate={selectedDate}
          onSelectedDateChange={setSelectedDate}
          onSelectTask={onSelectTask}
          onOpenCreateTaskForDate={onOpenCreateTaskForDate}
        />
      )}
    </div>
  );
};
