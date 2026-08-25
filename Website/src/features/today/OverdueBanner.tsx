import React, { useState } from 'react';
import { AlertCircle, Calendar, ChevronDown, ChevronUp, ArrowRight } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { addDays } from 'date-fns';

export const OverdueBanner: React.FC = () => {
  const { tasks, rescheduleTask } = useDayPulseData();
  const [isExpanded, setIsExpanded] = useState(false);

  const todayStr = AppDateUtils.toIsoDate(new Date());
  const tomorrowStr = AppDateUtils.toIsoDate(addDays(new Date(), 1));

  // Find all overdue uncompleted top-level tasks
  const overdueTasks = tasks.filter(t => !t.parentId && !t.completed && t.date < todayStr);

  if (overdueTasks.length === 0) return null;

  const handleRescheduleAllToday = async () => {
    for (const t of overdueTasks) {
      await rescheduleTask(t.id, todayStr);
    }
  };

  const handleRescheduleAllTomorrow = async () => {
    for (const t of overdueTasks) {
      await rescheduleTask(t.id, tomorrowStr);
    }
  };

  return (
    <div className="rounded-2xl bg-rose-500/10 border border-rose-500/25 p-4 text-slate-800 dark:text-slate-100 transition-all">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-rose-500/20 text-rose-500 flex items-center justify-center flex-shrink-0">
            <AlertCircle className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold text-rose-600 dark:text-rose-400 uppercase tracking-wider">
                Attention Required
              </span>
              <span className="px-2 py-0.5 rounded-full bg-rose-500/20 text-rose-600 dark:text-rose-300 text-[11px] font-extrabold">
                {overdueTasks.length} Overdue
              </span>
            </div>
            <p className="text-xs text-slate-600 dark:text-slate-300 mt-0.5">
              You have {overdueTasks.length} uncompleted task(s) from previous days.
            </p>
          </div>
        </div>

        {/* Batch action buttons */}
        <div className="flex items-center gap-2 flex-wrap">
          <button
            onClick={handleRescheduleAllToday}
            className="px-3 py-1.5 rounded-xl bg-rose-500 hover:bg-rose-600 text-white text-xs font-bold shadow-sm active:scale-95 transition-all"
          >
            Move All to Today
          </button>
          <button
            onClick={handleRescheduleAllTomorrow}
            className="px-3 py-1.5 rounded-xl bg-surface-light dark:bg-surface-dark hover:bg-slate-100 dark:hover:bg-surface-dark-variant text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-surface-dark-border text-xs font-bold shadow-sm transition-colors"
          >
            Move to Tomorrow
          </button>
          <button
            onClick={() => setIsExpanded(!isExpanded)}
            className="p-1.5 rounded-xl text-slate-400 hover:text-slate-600 dark:hover:text-white"
            title="Toggle list"
          >
            {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Expanded list of overdue tasks */}
      {isExpanded && (
        <div className="mt-3 pt-3 border-t border-rose-500/20 space-y-1.5">
          {overdueTasks.map(t => (
            <div
              key={t.id}
              className="flex items-center justify-between px-3 py-2 rounded-xl bg-white/60 dark:bg-surface-dark/60 border border-rose-500/15 text-xs"
            >
              <div className="flex items-center gap-2 truncate mr-2">
                <span className="font-semibold text-slate-800 dark:text-slate-200 truncate">{t.title}</span>
                <span className="text-[10px] text-slate-400">({AppDateUtils.formatShortDate(t.date)})</span>
              </div>

              <div className="flex items-center gap-1.5 flex-shrink-0">
                <button
                  onClick={() => rescheduleTask(t.id, todayStr)}
                  className="px-2 py-1 rounded-lg bg-brand-500/10 text-brand-600 dark:text-brand-400 hover:bg-brand-500/20 font-semibold text-[11px]"
                >
                  Today
                </button>
                <button
                  onClick={() => rescheduleTask(t.id, tomorrowStr)}
                  className="px-2 py-1 rounded-lg bg-slate-100 dark:bg-surface-dark-variant text-slate-600 dark:text-slate-300 hover:bg-slate-200 font-semibold text-[11px]"
                >
                  Tomorrow
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
