import { addDays, subDays, differenceInDays } from 'date-fns';
import { Task } from '../../types/task';
import { TaskOccurrence } from '../../types/recurrence';
import { ProductivityScoreBreakdown, StreakCalculationResult } from '../../types/analytics';
import { AppDateUtils } from './dateUtils';

export class ProductivityCalculator {
  static calculateScore(tasks: Task[], currentStreak: number): ProductivityScoreBreakdown {
    if (!tasks || tasks.length === 0) {
      return {
        totalScore: 0,
        completionPoints: 0,
        priorityPoints: 0,
        punctualityPoints: 0,
        consistencyPoints: 0,
        summaryExplanation: 'No tasks scheduled for this period.',
      };
    }

    const totalTasks = tasks.length;
    const completedTasks = tasks.filter(t => t.completed).length;
    const completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0;

    // 1. Completion Points (Max 40)
    const completionPts = Math.round(completionRate * 40);

    // 2. High Priority Points (Max 30)
    const highPriorityTasks = tasks.filter(t => t.priority === 'high');
    let priorityPts = 0;
    if (highPriorityTasks.length > 0) {
      const completedHighPri = highPriorityTasks.filter(t => t.completed).length;
      const highPriRate = completedHighPri / highPriorityTasks.length;
      priorityPts = Math.round(highPriRate * 30);
    } else {
      priorityPts = Math.round(completionRate * 30);
    }

    // 3. Punctuality / Overdue Penalty (Max 15)
    const overdueCount = tasks.filter(t => AppDateUtils.isTaskOverdue(t)).length;
    let punctualityPts = 15;
    if (overdueCount > 0) {
      punctualityPts = Math.max(0, 15 - overdueCount * 5);
    }

    // 4. Consistency Factor (Max 15)
    let consistencyPts = 0;
    if (currentStreak >= 5) {
      consistencyPts = 15;
    } else if (currentStreak >= 3) {
      consistencyPts = 10;
    } else if (currentStreak >= 1) {
      consistencyPts = 5;
    } else {
      consistencyPts = completionRate > 0.5 ? 3 : 0;
    }

    const total = Math.min(100, Math.max(0, completionPts + priorityPts + punctualityPts + consistencyPts));

    let explanation = `Completed ${completedTasks} of ${totalTasks} planned tasks`;
    if (highPriorityTasks.length > 0) {
      const completedHighPri = highPriorityTasks.filter(t => t.completed).length;
      explanation += ` and ${completedHighPri} of ${highPriorityTasks.length} high-priority tasks.`;
    } else {
      explanation += '.';
    }
    if (overdueCount > 0) {
      explanation += ` ${overdueCount} task(s) currently overdue.`;
    }

    return {
      totalScore: total,
      completionPoints: completionPts,
      priorityPoints: priorityPts,
      punctualityPoints: punctualityPts,
      consistencyPoints: consistencyPts,
      summaryExplanation: explanation,
    };
  }

  static calculateStreaks(
    allTasks: Task[],
    occurrences: TaskOccurrence[] = [],
    thresholdPercentage: number = 70
  ): StreakCalculationResult {
    if (!allTasks || allTasks.length === 0) {
      return {
        currentStreak: 0,
        longestStreak: 0,
        totalSuccessfulDays: 0,
        isTodaySuccessful: false,
      };
    }

    const now = new Date();
    const todayNorm = AppDateUtils.normalizeDate(now);
    const todayStr = AppDateUtils.toIsoDate(todayNorm);

    const dateMap = new Map<string, Task[]>();

    // 1. Add non-recurring top-level tasks
    for (const task of allTasks) {
      if (task.repeatRule === 'none' && !task.parentId) {
        if (!dateMap.has(task.date)) {
          dateMap.set(task.date, []);
        }
        dateMap.get(task.date)!.push(task);
      }
    }

    // 2. Synthesize recurring tasks across the last 90 days up to today
    const occMap = new Map<string, TaskOccurrence>();
    for (const occ of occurrences) {
      occMap.set(`${occ.taskId}_${occ.date}`, occ);
    }

    const recurringTasks = allTasks.filter(t => t.repeatRule !== 'none' && !t.parentId);

    if (recurringTasks.length > 0) {
      let earliestDate = subDays(todayNorm, 90);
      for (const rt of recurringTasks) {
        const rtStart = AppDateUtils.parseIsoDate(rt.date);
        if (rtStart < earliestDate) {
          earliestDate = rtStart;
        }
      }

      let cur = earliestDate;
      while (cur <= todayNorm) {
        const curIso = AppDateUtils.toIsoDate(cur);
        for (const rt of recurringTasks) {
          if (AppDateUtils.isOccurringOnDate(rt, cur)) {
            const occ = occMap.get(`${rt.id}_${curIso}`);
            if (occ && occ.isSkipped) continue;

            const isDone = occ ? occ.completed : false;
            if (!dateMap.has(curIso)) {
              dateMap.set(curIso, []);
            }
            dateMap.get(curIso)!.push({
              ...rt,
              date: curIso,
              completed: isDone,
              completedAt: occ?.completedAt,
            });
          }
        }
        cur = addDays(cur, 1);
      }
    }

    // Determine successful days (meeting threshold)
    const successfulDays = new Map<string, boolean>();
    for (const [dateStr, tasksOnDay] of dateMap.entries()) {
      if (tasksOnDay.length === 0) continue;
      const done = tasksOnDay.filter(t => t.completed).length;
      const rate = (done / tasksOnDay.length) * 100;
      successfulDays.set(dateStr, rate >= thresholdPercentage);
    }

    const isTodaySuccessful = successfulDays.get(todayStr) === true;
    let totalSuccessful = 0;
    for (const val of successfulDays.values()) {
      if (val) totalSuccessful++;
    }

    // Calculate current streak backwards
    let currentStreak = 0;
    let checkDate = todayNorm;

    const todayTasks = dateMap.get(todayStr) || [];
    if (todayTasks.length === 0 || !isTodaySuccessful) {
      checkDate = subDays(todayNorm, 1);
    }

    const maxCheckLimit = subDays(todayNorm, 365);
    while (checkDate >= maxCheckLimit) {
      const dateStr = AppDateUtils.toIsoDate(checkDate);
      const tasksOnDate = dateMap.get(dateStr);

      if (successfulDays.get(dateStr) === true) {
        currentStreak++;
        checkDate = subDays(checkDate, 1);
      } else if (!tasksOnDate || tasksOnDate.length === 0) {
        // Rest day (0 scheduled tasks): do not break streak
        checkDate = subDays(checkDate, 1);
      } else {
        // Had tasks and failed threshold -> break streak
        break;
      }
    }

    // Longest streak across history
    const sortedDates = Array.from(successfulDays.keys()).sort();
    let longestStreak = 0;
    let tempStreak = 0;
    let prevDate: Date | null = null;

    for (const dateKey of sortedDates) {
      const isSuccess = successfulDays.get(dateKey) === true;
      const curDate = AppDateUtils.parseIsoDate(dateKey);

      if (isSuccess) {
        if (prevDate && differenceInDays(curDate, prevDate) === 1) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }
        prevDate = curDate;
        longestStreak = Math.max(longestStreak, tempStreak);
      } else {
        tempStreak = 0;
        prevDate = null;
      }
    }

    longestStreak = Math.max(longestStreak, currentStreak);

    return {
      currentStreak,
      longestStreak,
      totalSuccessfulDays: totalSuccessful,
      isTodaySuccessful,
    };
  }
}
