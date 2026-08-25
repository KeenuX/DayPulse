import React, { useState, useEffect } from 'react';
import { Clock, Sun, CloudSun, Moon, X, Sparkles, Plus, Minus } from 'lucide-react';
import { AppDateUtils } from '../../core/utilities/dateUtils';
import { formatDurationMinutes } from '../../core/utilities/durationFormatter';

interface TimePickerFieldProps {
  label?: string;
  value?: string | null; // HH:mm (24-hour format)
  onChange: (timeStr: string) => void;
  onClear?: () => void;
  durationMinutes?: number | null;
  onDurationChange?: (mins: number | null) => void;
  showDuration?: boolean;
}

export const TimePickerField: React.FC<TimePickerFieldProps> = ({
  label = 'Start Time',
  value,
  onChange,
  onClear,
  durationMinutes,
  onDurationChange,
  showDuration = true,
}) => {
  const [isOpen, setIsOpen] = useState(false);

  // Parse existing value or default to 9:00 AM
  let initialHour12 = 9;
  let initialMinute = 0;
  let initialPeriod: 'AM' | 'PM' = 'AM';

  if (value) {
    const [hStr, mStr] = value.split(':');
    let h = parseInt(hStr, 10);
    const m = parseInt(mStr || '0', 10);
    if (!isNaN(h) && !isNaN(m)) {
      initialPeriod = h >= 12 ? 'PM' : 'AM';
      h = h % 12;
      initialHour12 = h === 0 ? 12 : h;
      initialMinute = m;
    }
  }

  const [selectedHour, setSelectedHour] = useState<number>(initialHour12);
  const [selectedMinute, setSelectedMinute] = useState<number>(initialMinute);
  const [selectedPeriod, setSelectedPeriod] = useState<'AM' | 'PM'>(initialPeriod);

  useEffect(() => {
    if (value) {
      const [hStr, mStr] = value.split(':');
      let h = parseInt(hStr, 10);
      const m = parseInt(mStr || '0', 10);
      if (!isNaN(h) && !isNaN(m)) {
        const p = h >= 12 ? 'PM' : 'AM';
        h = h % 12;
        setSelectedHour(h === 0 ? 12 : h);
        setSelectedMinute(m);
        setSelectedPeriod(p);
      }
    }
  }, [value]);

  const emitTime = (hour: number, minute: number, period: 'AM' | 'PM') => {
    let h24 = hour % 12;
    if (period === 'PM') h24 += 12;
    const hPad = h24 < 10 ? `0${h24}` : `${h24}`;
    const mPad = minute < 10 ? `0${minute}` : `${minute}`;
    onChange(`${hPad}:${mPad}`);
  };

  const handleHourSelect = (h: number) => {
    setSelectedHour(h);
    emitTime(h, selectedMinute, selectedPeriod);
  };

  const handleMinuteSelect = (m: number) => {
    setSelectedMinute(m);
    emitTime(selectedHour, m, selectedPeriod);
  };

  const handlePeriodToggle = (p: 'AM' | 'PM') => {
    setSelectedPeriod(p);
    emitTime(selectedHour, selectedMinute, p);
  };

  // Quick Preset Handlers
  const quickPresets = [
    { label: 'Morning', time: '09:00', hour: 9, minute: 0, period: 'AM' as const, icon: Sun },
    { label: 'Noon', time: '12:00', hour: 12, minute: 0, period: 'PM' as const, icon: Sun },
    { label: 'Afternoon', time: '15:00', hour: 3, minute: 0, period: 'PM' as const, icon: CloudSun },
    { label: 'Evening', time: '18:00', hour: 6, minute: 0, period: 'PM' as const, icon: Moon },
    { label: 'Night', time: '21:00', hour: 9, minute: 0, period: 'PM' as const, icon: Moon },
  ];

  const durationPresets = [15, 30, 45, 60, 90, 120];

  const hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  const minutes = [0, 15, 30, 45];

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <label className="block text-xs font-bold uppercase tracking-wider text-slate-400">
          {label}
        </label>
        {value && (
          <button
            type="button"
            onClick={() => {
              if (onClear) onClear();
              onChange('');
            }}
            className="text-[11px] font-semibold text-rose-500 hover:text-rose-600 flex items-center gap-0.5"
          >
            <X className="w-3 h-3" />
            <span>Clear Time</span>
          </button>
        )}
      </div>

      {/* Main Trigger Card */}
      <div
        onClick={() => setIsOpen(!isOpen)}
        className={`p-3.5 rounded-2xl border transition-all cursor-pointer select-none flex items-center justify-between shadow-sm ${
          value
            ? 'bg-brand-500/5 dark:bg-brand-950/20 border-brand-500/40'
            : 'bg-slate-50 dark:bg-surface-dark-subtle border-slate-200 dark:border-surface-dark-border hover:border-brand-300'
        }`}
      >
        <div className="flex items-center gap-3">
          <div className={`w-9 h-9 rounded-xl flex items-center justify-center ${
            value ? 'bg-brand-500 text-white shadow-md shadow-brand-500/20' : 'bg-slate-200 dark:bg-surface-dark-variant text-slate-500'
          }`}>
            <Clock className="w-4 h-4" />
          </div>

          <div>
            <div className="text-sm font-bold text-slate-800 dark:text-white">
              {value ? AppDateUtils.formatTime12(value) : 'Select start time'}
            </div>
            <span className="text-[11px] text-slate-400">
              {value ? 'Tap to customize hour & minutes' : 'Optional scheduled time'}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {durationMinutes && durationMinutes > 0 && (
            <span className="px-2.5 py-1 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400 text-xs font-bold border border-amber-500/20">
              {formatDurationMinutes(durationMinutes)}
            </span>
          )}
          <span className="text-xs font-bold text-brand-500">
            {isOpen ? 'Close' : 'Set Time'}
          </span>
        </div>
      </div>

      {/* Expanded Interactive Picker Dialog */}
      {isOpen && (
        <div className="p-4 rounded-3xl bg-slate-50/90 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border space-y-4 animate-slide-up shadow-inner">
          {/* 1. Quick Presets Row */}
          <div>
            <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 block mb-1.5">
              Quick Presets
            </span>
            <div className="flex flex-wrap gap-1.5">
              {quickPresets.map(preset => {
                const isSelected = value === preset.time;
                const Icon = preset.icon;
                return (
                  <button
                    key={preset.label}
                    type="button"
                    onClick={() => {
                      setSelectedHour(preset.hour);
                      setSelectedMinute(preset.minute);
                      setSelectedPeriod(preset.period);
                      onChange(preset.time);
                    }}
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold border transition-all ${
                      isSelected
                        ? 'bg-brand-500 text-white border-brand-500 shadow-sm'
                        : 'bg-white dark:bg-surface-dark border-slate-200 dark:border-surface-dark-border text-slate-600 dark:text-slate-300 hover:border-brand-300'
                    }`}
                  >
                    <Icon className="w-3 h-3" />
                    <span>{preset.label}</span>
                    <span className="text-[10px] opacity-75">{AppDateUtils.formatTime12(preset.time)}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* 2. Visual Hour & Minute Selector Grid */}
          <div className="p-4 rounded-2xl bg-white dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border space-y-3">
            {/* Display + AM/PM switch */}
            <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-surface-dark-border">
              <div className="text-xl font-black text-slate-900 dark:text-white font-mono tracking-wider">
                {selectedHour < 10 ? `0${selectedHour}` : selectedHour}:
                {selectedMinute < 10 ? `0${selectedMinute}` : selectedMinute}
              </div>

              {/* AM / PM Toggle */}
              <div className="flex p-0.5 rounded-xl bg-slate-100 dark:bg-surface-dark-variant">
                <button
                  type="button"
                  onClick={() => handlePeriodToggle('AM')}
                  className={`px-3 py-1 rounded-lg text-xs font-bold transition-all ${
                    selectedPeriod === 'AM'
                      ? 'bg-brand-500 text-white shadow-sm'
                      : 'text-slate-500 dark:text-slate-400'
                  }`}
                >
                  AM
                </button>
                <button
                  type="button"
                  onClick={() => handlePeriodToggle('PM')}
                  className={`px-3 py-1 rounded-lg text-xs font-bold transition-all ${
                    selectedPeriod === 'PM'
                      ? 'bg-brand-500 text-white shadow-sm'
                      : 'text-slate-500 dark:text-slate-400'
                  }`}
                >
                  PM
                </button>
              </div>
            </div>

            {/* Hours Grid */}
            <div>
              <span className="text-[10px] font-bold text-slate-400 block mb-1">Hour</span>
              <div className="grid grid-cols-6 sm:grid-cols-12 gap-1">
                {hours.map(h => (
                  <button
                    key={h}
                    type="button"
                    onClick={() => handleHourSelect(h)}
                    className={`h-8 rounded-xl text-xs font-bold transition-all ${
                      selectedHour === h
                        ? 'bg-brand-500 text-white shadow-sm shadow-brand-500/25 scale-105'
                        : 'bg-slate-50 dark:bg-surface-dark-subtle text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-variant'
                    }`}
                  >
                    {h}
                  </button>
                ))}
              </div>
            </div>

            {/* Minutes Grid */}
            <div>
              <span className="text-[10px] font-bold text-slate-400 block mb-1">Minute</span>
              <div className="grid grid-cols-4 gap-1.5">
                {minutes.map(m => (
                  <button
                    key={m}
                    type="button"
                    onClick={() => handleMinuteSelect(m)}
                    className={`py-1.5 rounded-xl text-xs font-bold transition-all ${
                      selectedMinute === m
                        ? 'bg-indigo-600 text-white shadow-sm scale-105'
                        : 'bg-slate-50 dark:bg-surface-dark-subtle text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-variant'
                    }`}
                  >
                    :{m < 10 ? `0${m}` : m}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* 3. Duration Selector & Presets */}
          {showDuration && onDurationChange && (
            <div className="p-4 rounded-2xl bg-white dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border space-y-2.5">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-800 dark:text-white flex items-center gap-1.5">
                  <Clock className="w-3.5 h-3.5 text-amber-500" />
                  <span>Duration</span>
                </span>

                <div className="flex items-center gap-1.5">
                  <button
                    type="button"
                    onClick={() => {
                      const cur = durationMinutes || 0;
                      if (cur > 15) onDurationChange(cur - 15);
                      else onDurationChange(null);
                    }}
                    className="p-1 rounded-lg bg-slate-100 dark:bg-surface-dark-variant hover:bg-slate-200 text-slate-600 dark:text-slate-300"
                    title="-15 mins"
                  >
                    <Minus className="w-3 h-3" />
                  </button>

                  <span className="text-xs font-black text-amber-600 dark:text-amber-400 min-w-[50px] text-center font-mono">
                    {durationMinutes && durationMinutes > 0 ? formatDurationMinutes(durationMinutes) : 'None'}
                  </span>

                  <button
                    type="button"
                    onClick={() => {
                      const cur = durationMinutes || 0;
                      onDurationChange(cur + 15);
                    }}
                    className="p-1 rounded-lg bg-slate-100 dark:bg-surface-dark-variant hover:bg-slate-200 text-slate-600 dark:text-slate-300"
                    title="+15 mins"
                  >
                    <Plus className="w-3 h-3" />
                  </button>
                </div>
              </div>

              {/* Quick Duration Chips */}
              <div className="flex flex-wrap gap-1.5 pt-1">
                {durationPresets.map(mins => (
                  <button
                    key={mins}
                    type="button"
                    onClick={() => onDurationChange(mins)}
                    className={`px-3 py-1 rounded-xl text-xs font-semibold border transition-all ${
                      durationMinutes === mins
                        ? 'bg-amber-500 text-white border-amber-500 shadow-sm'
                        : 'bg-slate-50 dark:bg-surface-dark-subtle border-slate-200 dark:border-surface-dark-border text-slate-600 dark:text-slate-300 hover:border-amber-300'
                    }`}
                  >
                    {formatDurationMinutes(mins)}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
