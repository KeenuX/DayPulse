import React, { useState } from 'react';
import { Plus, Sparkles, Calendar, Clock, Flag, ArrowRight } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { NaturalLanguageParser, ParsedTaskInput } from '../../core/utilities/nlpParser';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { formatDurationMinutes } from '../../core/utilities/durationFormatter';

interface QuickAddBarProps {
  onOpenFullModal: () => void;
}

export const QuickAddBar: React.FC<QuickAddBarProps> = ({ onOpenFullModal }) => {
  const { addTask } = useDayPulseData();
  const [text, setText] = useState('');

  const parsed: ParsedTaskInput | null = text.trim() ? NaturalLanguageParser.parse(text) : null;

  const handleQuickSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!text.trim() || !parsed) return;

    await addTask({
      title: parsed.title,
      date: parsed.date,
      startTime: parsed.startTime || null,
      durationMinutes: parsed.durationMinutes || null,
      priority: parsed.priority,
      completed: false,
      reminderEnabled: !!parsed.startTime,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
    });

    setText('');
  };

  const todayStr = AppDateUtils.toIsoDate(new Date());

  return (
    <div className="rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border p-3 sm:p-4 shadow-sm hover:shadow-md transition-shadow">
      <form onSubmit={handleQuickSubmit} className="space-y-2">
        <div className="flex items-center gap-2 sm:gap-3">
          <div className="w-8 h-8 rounded-xl bg-brand-500/10 text-brand-500 flex items-center justify-center flex-shrink-0">
            <Sparkles className="w-4 h-4" />
          </div>

          <input
            type="text"
            placeholder='Quick add: "Study chemistry tomorrow at 4pm !high for 1h"...'
            value={text}
            onChange={e => setText(e.target.value)}
            className="flex-1 bg-transparent text-sm text-slate-900 dark:text-white placeholder-slate-400 outline-none"
          />

          <button
            type="submit"
            disabled={!text.trim()}
            className="px-4 py-2 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:opacity-40 text-white text-xs font-bold shadow-md shadow-brand-500/20 active:scale-95 transition-all flex items-center gap-1.5"
          >
            <span>Add</span>
            <Plus className="w-3.5 h-3.5 stroke-[3]" />
          </button>
        </div>

        {/* Live NLP Badges Preview */}
        {parsed && text.trim() && (
          <div className="flex items-center gap-2 pt-2 border-t border-slate-100 dark:border-surface-dark-border/60 flex-wrap text-[11px] animate-fade-in">
            <span className="text-slate-400 font-medium">Auto-detected:</span>

            {/* Date */}
            <span className="flex items-center gap-1 px-2 py-0.5 rounded-lg bg-slate-100 dark:bg-surface-dark-variant text-slate-600 dark:text-slate-300 font-semibold">
              <Calendar className="w-3 h-3 text-brand-500" />
              <span>{parsed.date === todayStr ? 'Today' : AppDateUtils.formatShortDate(parsed.date)}</span>
            </span>

            {/* Time */}
            {parsed.startTime && (
              <span className="flex items-center gap-1 px-2 py-0.5 rounded-lg bg-slate-100 dark:bg-surface-dark-variant text-slate-600 dark:text-slate-300 font-semibold">
                <Clock className="w-3 h-3 text-brand-500" />
                <span>{AppDateUtils.formatTime12(parsed.startTime)}</span>
              </span>
            )}

            {/* Duration */}
            {parsed.durationMinutes && (
              <span className="flex items-center gap-1 px-2 py-0.5 rounded-lg bg-slate-100 dark:bg-surface-dark-variant text-slate-600 dark:text-slate-300 font-semibold">
                <span>{formatDurationMinutes(parsed.durationMinutes)}</span>
              </span>
            )}

            {/* Priority */}
            <span
              className={`flex items-center gap-1 px-2 py-0.5 rounded-lg font-bold uppercase tracking-wider ${
                parsed.priority === 'high'
                  ? 'bg-rose-500/10 text-rose-500'
                  : parsed.priority === 'low'
                  ? 'bg-emerald-500/10 text-emerald-500'
                  : 'bg-amber-500/10 text-amber-500'
              }`}
            >
              <Flag className="w-3 h-3" />
              <span>{parsed.priority}</span>
            </span>
          </div>
        )}
      </form>
    </div>
  );
};
