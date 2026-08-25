import React, { useState } from 'react';
import { X, Calendar as CalendarIcon, Clock, ArrowRight } from 'lucide-react';
import { addDays, nextMonday } from 'date-fns';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { TimePickerField } from './TimePickerField';

interface RescheduleModalProps {
  isOpen: boolean;
  onClose: () => void;
  taskId: string | null;
}

export const RescheduleModal: React.FC<RescheduleModalProps> = ({
  isOpen,
  onClose,
  taskId,
}) => {
  const { tasks, rescheduleTask } = useDayPulseData();
  const task = tasks.find(t => t.id === taskId);

  const [customDate, setCustomDate] = useState(AppDateUtils.toIsoDate(new Date()));
  const [customTime, setCustomTime] = useState(task?.startTime || '');

  if (!isOpen || !task) return null;

  const today = new Date();
  const todayStr = AppDateUtils.toIsoDate(today);
  const tomorrowStr = AppDateUtils.toIsoDate(addDays(today, 1));
  const in2DaysStr = AppDateUtils.toIsoDate(addDays(today, 2));
  const nextMonStr = AppDateUtils.toIsoDate(nextMonday(today));

  const handleApply = async (newDate: string, newTime?: string) => {
    await rescheduleTask(task.id, newDate, newTime || task.startTime);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in" onClick={onClose}>
      <div
        className="w-full max-w-md bg-white dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border rounded-3xl shadow-2xl overflow-hidden animate-slide-up"
        onClick={e => e.stopPropagation()}
      >
        <div className="px-5 py-4 border-b border-slate-100 dark:border-surface-dark-border flex items-center justify-between">
          <div className="flex items-center gap-2">
            <CalendarIcon className="w-5 h-5 text-brand-500" />
            <h3 className="font-bold text-slate-800 dark:text-white text-base">Reschedule Task</h3>
          </div>
          <button onClick={onClose} className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-5 space-y-4 max-h-[85vh] overflow-y-auto">
          <div className="p-3 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-100 dark:border-surface-dark-border">
            <span className="text-xs text-slate-400">Current schedule:</span>
            <p className="text-sm font-semibold text-slate-700 dark:text-slate-200 truncate">{task.title}</p>
            <p className="text-xs text-brand-500 font-medium mt-0.5">
              {AppDateUtils.formatDisplayDate(task.date)} {task.startTime && `at ${AppDateUtils.formatTime12(task.startTime)}`}
            </p>
          </div>

          <div className="space-y-1.5">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Quick Options</span>
            <div className="grid grid-cols-2 gap-2">
              <button
                onClick={() => handleApply(todayStr)}
                className="flex items-center justify-between p-3 rounded-xl bg-slate-100 dark:bg-surface-dark-subtle hover:bg-brand-50 dark:hover:bg-brand-900/30 text-left transition-colors group"
              >
                <div>
                  <div className="text-xs font-bold text-slate-800 dark:text-slate-200 group-hover:text-brand-500">Today</div>
                  <div className="text-[10px] text-slate-400">{AppDateUtils.formatShortDate(todayStr)}</div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-brand-500 transition-transform group-hover:translate-x-0.5" />
              </button>

              <button
                onClick={() => handleApply(tomorrowStr)}
                className="flex items-center justify-between p-3 rounded-xl bg-slate-100 dark:bg-surface-dark-subtle hover:bg-brand-50 dark:hover:bg-brand-900/30 text-left transition-colors group"
              >
                <div>
                  <div className="text-xs font-bold text-slate-800 dark:text-slate-200 group-hover:text-brand-500">Tomorrow</div>
                  <div className="text-[10px] text-slate-400">{AppDateUtils.formatShortDate(tomorrowStr)}</div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-brand-500 transition-transform group-hover:translate-x-0.5" />
              </button>

              <button
                onClick={() => handleApply(in2DaysStr)}
                className="flex items-center justify-between p-3 rounded-xl bg-slate-100 dark:bg-surface-dark-subtle hover:bg-brand-50 dark:hover:bg-brand-900/30 text-left transition-colors group"
              >
                <div>
                  <div className="text-xs font-bold text-slate-800 dark:text-slate-200 group-hover:text-brand-500">In 2 Days</div>
                  <div className="text-[10px] text-slate-400">{AppDateUtils.formatShortDate(in2DaysStr)}</div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-brand-500 transition-transform group-hover:translate-x-0.5" />
              </button>

              <button
                onClick={() => handleApply(nextMonStr)}
                className="flex items-center justify-between p-3 rounded-xl bg-slate-100 dark:bg-surface-dark-subtle hover:bg-brand-50 dark:hover:bg-brand-900/30 text-left transition-colors group"
              >
                <div>
                  <div className="text-xs font-bold text-slate-800 dark:text-slate-200 group-hover:text-brand-500">Next Week</div>
                  <div className="text-[10px] text-slate-400">{AppDateUtils.formatShortDate(nextMonStr)}</div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-brand-500 transition-transform group-hover:translate-x-0.5" />
              </button>
            </div>
          </div>

          {/* Custom Date & Enhanced Time Picker */}
          <div className="pt-2 border-t border-slate-100 dark:border-surface-dark-border space-y-3">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Custom Date & Time</span>
            <div>
              <label className="block text-[11px] text-slate-400 mb-1">Target Date</label>
              <input
                type="date"
                value={customDate}
                onChange={e => setCustomDate(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border text-xs text-slate-800 dark:text-slate-200 outline-none"
              />
            </div>

            <TimePickerField
              label="Target Time (Optional)"
              value={customTime}
              onChange={timeStr => setCustomTime(timeStr)}
              onClear={() => setCustomTime('')}
              showDuration={false}
            />

            <button
              onClick={() => handleApply(customDate, customTime)}
              className="w-full py-3 rounded-xl bg-brand-500 hover:bg-brand-600 text-white text-xs font-bold shadow-md shadow-brand-500/20 active:scale-95 transition-all mt-2"
            >
              Apply Reschedule
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
