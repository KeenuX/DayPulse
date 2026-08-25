import React from 'react';
import { X, Sparkles, CheckCircle2, AlertCircle, ArrowRight, Flame, Clock } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { ProductivityCalculator } from '../../core/utilities/productivityCalculator';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { formatDurationMinutes } from '../../core/utilities/durationFormatter';

interface DailySummaryModalProps {
  isOpen: boolean;
  onClose: () => void;
  onNavigateToPlanner: () => void;
}

export const DailySummaryModal: React.FC<DailySummaryModalProps> = ({
  isOpen,
  onClose,
  onNavigateToPlanner,
}) => {
  const { tasks, occurrences, rescheduleTask, getTasksForDate } = useDayPulseData();

  if (!isOpen) return null;

  const now = new Date();
  const todayTasks = getTasksForDate(now);
  const streakData = ProductivityCalculator.calculateStreaks(tasks, occurrences);
  const scoreData = ProductivityCalculator.calculateScore(todayTasks, streakData.currentStreak);

  const completedTasks = todayTasks.filter(t => t.completed);
  const pendingTasks = todayTasks.filter(t => !t.completed);

  const totalFocusMinutes = completedTasks.reduce((acc, t) => acc + (t.durationMinutes || 0), 0);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in" onClick={onClose}>
      <div
        className="w-full max-w-lg bg-white dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border rounded-3xl shadow-2xl overflow-hidden animate-slide-up"
        onClick={e => e.stopPropagation()}
      >
        {/* Header Banner */}
        <div className="p-6 bg-gradient-to-tr from-brand-600 to-indigo-600 text-white relative">
          <button
            onClick={onClose}
            className="absolute top-4 right-4 p-1.5 rounded-full bg-white/10 hover:bg-white/20 text-white transition-colors"
          >
            <X className="w-4 h-4" />
          </button>

          <div className="flex items-center gap-2 text-indigo-100 text-xs font-semibold uppercase tracking-wider">
            <Sparkles className="w-4 h-4 text-amber-300" />
            <span>Daily Review & Summary</span>
          </div>

          <h3 className="text-2xl font-black mt-1">Today's Pulse</h3>
          <p className="text-xs text-indigo-100/90">{AppDateUtils.formatDisplayDate(new Date())}</p>

          {/* Score Hero */}
          <div className="mt-4 flex items-center justify-between p-3.5 rounded-2xl bg-white/15 backdrop-blur-md border border-white/20">
            <div>
              <span className="text-[11px] font-medium text-white/80">Productivity Score</span>
              <div className="text-3xl font-black">{scoreData.totalScore} <span className="text-sm font-normal text-white/70">/ 100</span></div>
            </div>

            <div className="flex items-center gap-3">
              {streakData.currentStreak > 0 && (
                <div className="flex items-center gap-1 px-3 py-1.5 rounded-xl bg-white/20 text-white text-xs font-bold">
                  <Flame className="w-4 h-4 text-amber-300 fill-amber-300" />
                  <span>{streakData.currentStreak}d Streak</span>
                </div>
              )}

              {totalFocusMinutes > 0 && (
                <div className="flex items-center gap-1 px-3 py-1.5 rounded-xl bg-white/20 text-white text-xs font-bold">
                  <Clock className="w-4 h-4 text-sky-200" />
                  <span>{formatDurationMinutes(totalFocusMinutes)}</span>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Content Body */}
        <div className="p-6 space-y-4 max-h-[60vh] overflow-y-auto">
          {/* Summary Explanation */}
          <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed italic bg-slate-50 dark:bg-surface-dark-subtle p-3 rounded-xl border border-slate-100 dark:border-surface-dark-border">
            "{scoreData.summaryExplanation}"
          </p>

          {/* Completed Tasks List */}
          <div>
            <div className="flex items-center justify-between text-xs font-bold uppercase tracking-wider text-slate-400 mb-2">
              <span className="flex items-center gap-1.5 text-emerald-500">
                <CheckCircle2 className="w-3.5 h-3.5" />
                <span>Completed Today ({completedTasks.length})</span>
              </span>
            </div>

            {completedTasks.length > 0 ? (
              <div className="space-y-1">
                {completedTasks.map(t => (
                  <div
                    key={t.id}
                    className="flex items-center gap-2 px-3 py-2 rounded-xl bg-emerald-50/50 dark:bg-emerald-950/20 text-xs font-medium text-slate-700 dark:text-slate-300 border border-emerald-500/10"
                  >
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500 flex-shrink-0" />
                    <span className="truncate">{t.title}</span>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-xs text-slate-400 py-2">No tasks completed yet today.</div>
            )}
          </div>

          {/* Pending Tasks List */}
          {pendingTasks.length > 0 && (
            <div>
              <div className="flex items-center justify-between text-xs font-bold uppercase tracking-wider text-slate-400 mb-2">
                <span className="flex items-center gap-1.5 text-amber-500">
                  <AlertCircle className="w-3.5 h-3.5" />
                  <span>Unfinished ({pendingTasks.length})</span>
                </span>
              </div>

              <div className="space-y-1">
                {pendingTasks.map(t => (
                  <div
                    key={t.id}
                    className="flex items-center justify-between px-3 py-2 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle text-xs font-medium text-slate-700 dark:text-slate-300 border border-slate-100 dark:border-surface-dark-border"
                  >
                    <span className="truncate">{t.title}</span>
                    <button
                      onClick={() => {
                        const tomStr = AppDateUtils.toIsoDate(new Date(Date.now() + 86400000));
                        rescheduleTask(t.id, tomStr);
                      }}
                      className="text-[11px] font-semibold text-brand-500 hover:text-brand-600 flex-shrink-0 ml-2"
                    >
                      Move to Tomorrow
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 bg-slate-50 dark:bg-surface-dark-bg/60 border-t border-slate-100 dark:border-surface-dark-border flex items-center justify-between">
          <button
            onClick={onClose}
            className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-surface-dark-variant"
          >
            Done
          </button>

          <button
            onClick={() => {
              onClose();
              onNavigateToPlanner();
            }}
            className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-brand-500 hover:bg-brand-600 text-white text-xs font-bold shadow-md shadow-brand-500/25 active:scale-95 transition-all"
          >
            <span>Open Tomorrow Planner</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
};
