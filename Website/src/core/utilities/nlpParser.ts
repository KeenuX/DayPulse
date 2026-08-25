import { addDays } from 'date-fns';
import { TaskPriority } from '../../types/task';
import { AppDateUtils } from './dateUtils';

export interface ParsedTaskInput {
  title: string;
  date: string; // YYYY-MM-DD
  startTime?: string | null; // HH:mm
  durationMinutes?: number | null;
  priority: TaskPriority;
}

export class NaturalLanguageParser {
  static parse(rawText: string): ParsedTaskInput {
    let text = rawText.trim();
    const today = new Date();

    if (!text) {
      return {
        title: '',
        date: AppDateUtils.toIsoDate(today),
        priority: 'medium',
      };
    }

    let targetDate = AppDateUtils.toIsoDate(today);
    let targetTime: string | null = null;
    let duration: number | null = null;
    let priority: TaskPriority = 'medium';

    // 1. Detect Priority (!high, !med, !low, p1, p2, p3, high priority, etc.)
    const pHighRegex = /(!high|p1|\bpriority\s*high\b|\bhigh\s*priority\b)/i;
    const pMedRegex = /(!med|!medium|p2|\bpriority\s*med\b|\bmedium\s*priority\b)/i;
    const pLowRegex = /(!low|p3|\bpriority\s*low\b|\blow\s*priority\b)/i;

    if (pHighRegex.test(text)) {
      priority = 'high';
      text = text.replace(pHighRegex, '');
    } else if (pMedRegex.test(text)) {
      priority = 'medium';
      text = text.replace(pMedRegex, '');
    } else if (pLowRegex.test(text)) {
      priority = 'low';
      text = text.replace(pLowRegex, '');
    }

    // 2. Detect Date (tomorrow, tonight, today)
    const tomorrowRegex = /\b(tomorrow)\b/i;
    const tonightRegex = /\b(tonight)\b/i;
    const todayRegex = /\b(today)\b/i;

    if (tomorrowRegex.test(text)) {
      targetDate = AppDateUtils.toIsoDate(addDays(today, 1));
      text = text.replace(tomorrowRegex, '');
    } else if (tonightRegex.test(text)) {
      targetDate = AppDateUtils.toIsoDate(today);
      targetTime = '20:00'; // 8:00 PM default for tonight
      text = text.replace(tonightRegex, '');
    } else if (todayRegex.test(text)) {
      targetDate = AppDateUtils.toIsoDate(today);
      text = text.replace(todayRegex, '');
    }

    // 3. Detect Duration (e.g. "for 30m", "for 1h", "for 45 mins", "for 2 hours")
    const durationRegex = /\bfor\s+(\d+)\s*(m|min|mins|minutes|h|hr|hrs|hours)\b/i;
    const durMatch = text.match(durationRegex);
    if (durMatch) {
      const val = parseInt(durMatch[1], 10) || 0;
      const unit = durMatch[2].toLowerCase();
      duration = unit.startsWith('h') ? val * 60 : val;
      text = text.replace(durMatch[0], '');
    }

    // 4. Detect Time (e.g. "at 7:30 pm", "at 7pm", "at 14:00", "7:00 PM", "6am", "at 9")
    const time12Regex = /(?:\bat\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b/i;
    const time24Regex = /\bat\s+(\d{1,2}):(\d{2})\b/i;

    const time12Match = text.match(time12Regex);
    if (time12Match) {
      let hour = parseInt(time12Match[1], 10);
      const minute = parseInt(time12Match[2] || '0', 10);
      const period = time12Match[3].toLowerCase();

      if (period === 'pm' && hour < 12) hour += 12;
      if (period === 'am' && hour === 12) hour = 0;

      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        const hPad = hour < 10 ? `0${hour}` : `${hour}`;
        const mPad = minute < 10 ? `0${minute}` : `${minute}`;
        targetTime = `${hPad}:${mPad}`;
        text = text.replace(time12Match[0], '');
      }
    } else {
      const time24Match = text.match(time24Regex);
      if (time24Match) {
        const hour = parseInt(time24Match[1], 10);
        const minute = parseInt(time24Match[2], 10);
        if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          const hPad = hour < 10 ? `0${hour}` : `${hour}`;
          const mPad = minute < 10 ? `0${minute}` : `${minute}`;
          targetTime = `${hPad}:${mPad}`;
          text = text.replace(time24Match[0], '');
        }
      }
    }

    // Clean whitespace & stray connectors
    text = text.replace(/\s+/g, ' ').replace(/\s+at$/i, '').trim();

    return {
      title: text || rawText.trim(),
      date: targetDate,
      startTime: targetTime,
      durationMinutes: duration,
      priority,
    };
  }
}
