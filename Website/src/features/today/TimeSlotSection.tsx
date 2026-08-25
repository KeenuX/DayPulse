import React, { useState } from 'react';
import { Sun, CloudSun, Moon, Clock, ChevronDown, ChevronUp } from 'lucide-react';
import { Task } from '../../types/task';
import { TaskCard } from '../tasks/TaskCard';

export type TimeSlotType = 'morning' | 'afternoon' | 'evening' | 'anytime';

interface TimeSlotSectionProps {
  slot: TimeSlotType;
  tasks: Task[];
  onSelectTask: (taskId: string) => void;
  onEditTask: (taskId: string) => void;
  onRescheduleTask: (taskId: string) => void;
}

export const TimeSlotSection: React.FC<TimeSlotSectionProps> = ({
  slot,
  tasks,
  onSelectTask,
  onEditTask,
  onRescheduleTask,
}) => {
  const [isCollapsed, setIsCollapsed] = useState(false);

  if (tasks.length === 0) return null;

  const slotConfig = {
    morning: {
      title: 'Morning',
      timeRange: 'Before 12:00 PM',
      icon: Sun,
      color: 'text-amber-500',
      bgColor: 'bg-amber-500/10',
    },
    afternoon: {
      title: 'Afternoon',
      timeRange: '12:00 PM – 5:00 PM',
      icon: CloudSun,
      color: 'text-sky-500',
      bgColor: 'bg-sky-500/10',
    },
    evening: {
      title: 'Evening',
      timeRange: '5:00 PM – 9:00 PM',
      icon: Moon,
      color: 'text-indigo-500',
      bgColor: 'bg-indigo-500/10',
    },
    anytime: {
      title: 'Anytime / Scheduled',
      timeRange: 'Flexible time',
      icon: Clock,
      color: 'text-slate-500',
      bgColor: 'bg-slate-500/10',
    },
  }[slot];

  const Icon = slotConfig.icon;
  const completedCount = tasks.filter(t => t.completed).length;

  return (
    <div className="space-y-2.5">
      {/* Section Header */}
      <div
        className="flex items-center justify-between py-1 cursor-pointer select-none"
        onClick={() => setIsCollapsed(!isCollapsed)}
      >
        <div className="flex items-center gap-2.5">
          <div className={`w-7 h-7 rounded-lg ${slotConfig.bgColor} ${slotConfig.color} flex items-center justify-center`}>
            <Icon className="w-4 h-4" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-xs font-bold uppercase tracking-wider text-slate-700 dark:text-slate-200">
                {slotConfig.title}
              </h3>
              <span className="text-[11px] font-semibold text-slate-400">
                ({completedCount}/{tasks.length})
              </span>
            </div>
          </div>
        </div>

        <button className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 p-1">
          {isCollapsed ? <ChevronDown className="w-4 h-4" /> : <ChevronUp className="w-4 h-4" />}
        </button>
      </div>

      {/* Task Cards */}
      {!isCollapsed && (
        <div className="space-y-2">
          {tasks.map(task => (
            <TaskCard
              key={task.id}
              task={task}
              onSelect={onSelectTask}
              onEdit={onEditTask}
              onReschedule={onRescheduleTask}
            />
          ))}
        </div>
      )}
    </div>
  );
};
