import { format, parseISO, isBefore, isAfter, isSameDay, addDays, subDays, startOfWeek, endOfWeek, startOfMonth, endOfMonth, eachDayOfInterval, getDay, differenceInDays } from 'date-fns';
import { Task } from '../../types/task';

export class AppDateUtils {
  static toIsoDate(date: Date): string {
    return format(date, 'yyyy-MM-dd');
  }

  static parseIsoDate(dateStr: string): Date {
    try {
      return parseISO(dateStr);
    } catch {
      return new Date();
    }
  }

  static normalizeDate(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }

  static formatDisplayDate(date: Date | string): string {
    const d = typeof date === 'string' ? parseISO(date) : date;
    return format(d, 'EEEE, MMM d');
  }

  static formatShortDate(date: Date | string): string {
    const d = typeof date === 'string' ? parseISO(date) : date;
    return format(d, 'MMM d');
  }

  static formatTime12(timeStr?: string | null): string {
    if (!timeStr) return '';
    const [hStr, mStr] = timeStr.split(':');
    let hour = parseInt(hStr, 10);
    const minute = parseInt(mStr || '0', 10);
    const ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    hour = hour ? hour : 12;
    const minutePad = minute < 10 ? `0${minute}` : minute;
    return `${hour}:${minutePad} ${ampm}`;
  }

  static isDateToday(dateStr: string): boolean {
    const today = AppDateUtils.toIsoDate(new Date());
    return dateStr === today;
  }

  static isDateTomorrow(dateStr: string): boolean {
    const tomorrow = AppDateUtils.toIsoDate(addDays(new Date(), 1));
    return dateStr === tomorrow;
  }

  static isDateYesterday(dateStr: string): boolean {
    const yesterday = AppDateUtils.toIsoDate(subDays(new Date(), 1));
    return dateStr === yesterday;
  }

  static isTaskOverdue(task: Task): boolean {
    if (task.completed) return false;
    const now = new Date();
    const todayStr = AppDateUtils.toIsoDate(now);

    if (task.date < todayStr) return true;

    if (task.date === todayStr && task.startTime) {
      const [h, m] = task.startTime.split(':').map(Number);
      const taskTime = new Date(now.getFullYear(), now.getMonth(), now.getDate(), h, m);
      if (taskTime < now) return true;
    }

    return false;
  }

  static isOccurringOnDate(task: Task, targetDate: Date): boolean {
    const targetNorm = AppDateUtils.normalizeDate(targetDate);
    const startNorm = AppDateUtils.normalizeDate(AppDateUtils.parseIsoDate(task.date));

    if (task.repeatRule === 'none') {
      return isSameDay(targetNorm, startNorm);
    }

    if (isBefore(targetNorm, startNorm)) {
      return false;
    }

    // Check End Conditions
    if (task.repeatEndType === 'untilDate' && task.repeatEndDate) {
      const endNorm = AppDateUtils.normalizeDate(AppDateUtils.parseIsoDate(task.repeatEndDate));
      if (isAfter(targetNorm, endNorm)) return false;
    }

    const interval = (task.repeatInterval && task.repeatInterval > 0) ? task.repeatInterval : 1;

    switch (task.repeatRule) {
      case 'daily': {
        const daysDiff = differenceInDays(targetNorm, startNorm);
        if (daysDiff % interval !== 0) return false;
        if (task.repeatEndType === 'afterOccurrences' && task.repeatEndCount != null) {
          const occIndex = Math.floor(daysDiff / interval);
          if (occIndex >= task.repeatEndCount) return false;
        }
        return true;
      }

      case 'weekdays': {
        const dayOfWeek = targetNorm.getDay(); // 0 is Sunday, 6 is Saturday
        if (dayOfWeek === 0 || dayOfWeek === 6) return false;
        if (task.repeatEndType === 'afterOccurrences' && task.repeatEndCount != null) {
          const count = AppDateUtils.countWeekdaysBetween(startNorm, targetNorm);
          if (count >= task.repeatEndCount) return false;
        }
        return true;
      }

      case 'weekly': {
        // repeatDaysOfWeek contains 1 (Mon) to 7 (Sun)
        const targetWeekday = targetNorm.getDay() === 0 ? 7 : targetNorm.getDay();
        if (task.repeatDaysOfWeek && task.repeatDaysOfWeek.length > 0) {
          if (!task.repeatDaysOfWeek.includes(targetWeekday)) return false;
          const weeksDiff = Math.floor(differenceInDays(targetNorm, startNorm) / 7);
          if (weeksDiff % interval !== 0) return false;
          if (task.repeatEndType === 'afterOccurrences' && task.repeatEndCount != null) {
            const count = AppDateUtils.countWeeklyOccurrences(startNorm, targetNorm, task.repeatDaysOfWeek, interval);
            if (count >= task.repeatEndCount) return false;
          }
          return true;
        } else {
          const daysDiff = differenceInDays(targetNorm, startNorm);
          if (daysDiff % (7 * interval) !== 0) return false;
          if (task.repeatEndType === 'afterOccurrences' && task.repeatEndCount != null) {
            const occIndex = Math.floor(daysDiff / (7 * interval));
            if (occIndex >= task.repeatEndCount) return false;
          }
          return true;
        }
      }

      case 'monthly': {
        if (targetNorm.getDate() !== startNorm.getDate()) return false;
        const monthsDiff = (targetNorm.getFullYear() - startNorm.getFullYear()) * 12 + (targetNorm.getMonth() - startNorm.getMonth());
        if (monthsDiff < 0 || monthsDiff % interval !== 0) return false;
        if (task.repeatEndType === 'afterOccurrences' && task.repeatEndCount != null) {
          const occIndex = Math.floor(monthsDiff / interval);
          if (occIndex >= task.repeatEndCount) return false;
        }
        return true;
      }

      case 'custom': {
        const daysDiff = differenceInDays(targetNorm, startNorm);
        if (daysDiff % interval !== 0) return false;
        if (task.repeatEndType === 'afterOccurrences' && task.repeatEndCount != null) {
          const occIndex = Math.floor(daysDiff / interval);
          if (occIndex >= task.repeatEndCount) return false;
        }
        return true;
      }

      default:
        return isSameDay(targetNorm, startNorm);
    }
  }

  private static countWeekdaysBetween(start: Date, end: Date): number {
    let count = 0;
    let cur = new Date(start);
    while (!isAfter(cur, end)) {
      const d = cur.getDay();
      if (d >= 1 && d <= 5) count++;
      cur = addDays(cur, 1);
    }
    return count - 1;
  }

  private static countWeeklyOccurrences(start: Date, end: Date, days: number[], interval: number): number {
    let count = 0;
    let cur = new Date(start);
    while (!isAfter(cur, end)) {
      const weekday = cur.getDay() === 0 ? 7 : cur.getDay();
      if (days.includes(weekday)) {
        const weeksDiff = Math.floor(differenceInDays(cur, start) / 7);
        if (weeksDiff % interval === 0) count++;
      }
      cur = addDays(cur, 1);
    }
    return count - 1;
  }
}
