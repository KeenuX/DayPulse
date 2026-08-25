import React, { useState } from 'react';
import { PieChart, Tag } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { subDays } from 'date-fns';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { CategoryIcon } from '../categories/CategoryIcon';

type TimeRangeFilter = '7d' | '30d' | '90d' | 'all';

export const CategoryDonutCard: React.FC = () => {
  const { tasks, occurrences, categoryMap } = useDayPulseData();
  const [range, setRange] = useState<TimeRangeFilter>('30d');
  const [hoveredCategory, setHoveredCategory] = useState<string | null>(null);

  const now = new Date();
  const todayStr = AppDateUtils.toIsoDate(now);

  const cutoffDate =
    range === '7d'
      ? subDays(now, 7)
      : range === '30d'
      ? subDays(now, 30)
      : range === '90d'
      ? subDays(now, 90)
      : null;

  const cutoffStr = cutoffDate ? AppDateUtils.toIsoDate(cutoffDate) : '1970-01-01';

  // 1. Gather all completed tasks in range
  const completedInPeriod = tasks.filter(
    t => !t.parentId && t.repeatRule === 'none' && t.completed && t.date >= cutoffStr && t.date <= todayStr
  );

  // 2. Add occurrences
  const completedOccInPeriod = occurrences.filter(
    o => o.completed && o.date >= cutoffStr && o.date <= todayStr
  );

  const occTasks = completedOccInPeriod
    .map(o => tasks.find(t => t.id === o.taskId))
    .filter((t): t is typeof tasks[0] => t !== undefined);

  const allCompleted = [...completedInPeriod, ...occTasks];
  const totalCompleted = allCompleted.length;

  // Aggregate by Category
  const catCounts = new Map<string, number>();
  allCompleted.forEach(t => {
    const key = t.categoryId || 'general';
    catCounts.set(key, (catCounts.get(key) || 0) + 1);
  });

  const categorySegments = Array.from(catCounts.entries()).map(([catId, count]) => {
    const cat = catId !== 'general' ? categoryMap.get(catId) : null;
    return {
      id: catId,
      name: cat ? cat.name : 'General',
      colorHex: cat ? cat.colorHex : '#64748B',
      iconName: cat?.iconName,
      count,
      percentage: totalCompleted > 0 ? (count / totalCompleted) * 100 : 0,
    };
  });

  // Sort by count descending
  categorySegments.sort((a, b) => b.count - a.count);

  // SVG Donut calculation
  const size = 160;
  const strokeWidth = 24;
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;

  let currentOffset = 0;
  const renderedSlices = categorySegments.map(segment => {
    const strokeDasharray = `${(segment.percentage / 100) * circumference} ${circumference}`;
    const strokeDashoffset = -currentOffset;
    currentOffset += (segment.percentage / 100) * circumference;

    return {
      ...segment,
      strokeDasharray,
      strokeDashoffset,
    };
  });

  return (
    <div className="rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border p-5 sm:p-6 shadow-sm space-y-5">
      {/* Header & Filter */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <PieChart className="w-4 h-4 text-brand-500" />
          <h3 className="text-base font-bold text-slate-900 dark:text-white">
            Category Distribution
          </h3>
        </div>

        {/* Range Switcher */}
        <div className="flex items-center p-0.5 bg-slate-100 dark:bg-surface-dark-subtle rounded-xl text-xs font-semibold">
          {[
            { id: '7d', label: '7d' },
            { id: '30d', label: '30d' },
            { id: '90d', label: '90d' },
            { id: 'all', label: 'All Time' },
          ].map(r => (
            <button
              key={r.id}
              onClick={() => setRange(r.id as TimeRangeFilter)}
              className={`px-3 py-1 rounded-lg transition-all ${
                range === r.id
                  ? 'bg-white dark:bg-surface-dark text-brand-600 dark:text-brand-400 font-bold shadow-sm'
                  : 'text-slate-500 dark:text-slate-400'
              }`}
            >
              {r.label}
            </button>
          ))}
        </div>
      </div>

      {totalCompleted > 0 ? (
        <div className="flex flex-col sm:flex-row items-center gap-6 pt-2">
          {/* SVG Donut Chart */}
          <div className="relative w-44 h-44 flex items-center justify-center flex-shrink-0">
            <svg className="w-full h-full transform -rotate-90" viewBox={`0 0 ${size} ${size}`}>
              {/* Background circle */}
              <circle
                cx={size / 2}
                cy={size / 2}
                r={radius}
                stroke="currentColor"
                strokeWidth={strokeWidth}
                className="text-slate-100 dark:text-surface-dark-subtle"
                fill="transparent"
              />
              {/* Slices */}
              {renderedSlices.map(slice => {
                const isHovered = hoveredCategory === slice.id;
                return (
                  <circle
                    key={slice.id}
                    cx={size / 2}
                    cy={size / 2}
                    r={radius}
                    stroke={slice.colorHex}
                    strokeWidth={isHovered ? strokeWidth + 4 : strokeWidth}
                    strokeDasharray={slice.strokeDasharray}
                    strokeDashoffset={slice.strokeDashoffset}
                    fill="transparent"
                    className="transition-all duration-300 cursor-pointer"
                    onMouseEnter={() => setHoveredCategory(slice.id)}
                    onMouseLeave={() => setHoveredCategory(null)}
                  />
                );
              })}
            </svg>

            {/* Center Label */}
            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
              <span className="text-2xl font-black text-slate-800 dark:text-white">{totalCompleted}</span>
              <span className="text-[10px] uppercase font-bold tracking-wider text-slate-400">Done</span>
            </div>
          </div>

          {/* Legend and Percentages */}
          <div className="flex-1 w-full space-y-2">
            {categorySegments.map(segment => {
              const isHovered = hoveredCategory === segment.id;
              return (
                <div
                  key={segment.id}
                  onMouseEnter={() => setHoveredCategory(segment.id)}
                  onMouseLeave={() => setHoveredCategory(null)}
                  className={`flex items-center justify-between p-2 rounded-xl transition-colors cursor-pointer ${
                    isHovered
                      ? 'bg-slate-100 dark:bg-surface-dark-subtle'
                      : 'hover:bg-slate-50 dark:hover:bg-surface-dark-subtle/50'
                  }`}
                >
                  <div className="flex items-center gap-2">
                    <div
                      className="w-3 h-3 rounded-full flex-shrink-0"
                      style={{ backgroundColor: segment.colorHex }}
                    />
                    <span className="text-xs font-semibold text-slate-800 dark:text-slate-200">
                      {segment.name}
                    </span>
                  </div>

                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-slate-600 dark:text-slate-300">
                      {segment.count}
                    </span>
                    <span className="text-xs font-semibold text-slate-400 w-10 text-right">
                      {Math.round(segment.percentage)}%
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      ) : (
        <div className="text-center py-10 text-xs text-slate-400">
          No completed tasks found in this time range.
        </div>
      )}
    </div>
  );
};
