import 'dart:math';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/models/task_occurrence_model.dart';
import 'package:daypulse/features/tasks/models/task_priority.dart';

class ProductivityScoreBreakdown {
  final int totalScore; // 0 to 100
  final int completionPoints; // max 40
  final int priorityPoints; // max 30
  final int punctualityPoints; // max 15
  final int consistencyPoints; // max 15
  final String summaryExplanation;

  const ProductivityScoreBreakdown({
    required this.totalScore,
    required this.completionPoints,
    required this.priorityPoints,
    required this.punctualityPoints,
    required this.consistencyPoints,
    required this.summaryExplanation,
  });

  static const ProductivityScoreBreakdown empty = ProductivityScoreBreakdown(
    totalScore: 0,
    completionPoints: 0,
    priorityPoints: 0,
    punctualityPoints: 0,
    consistencyPoints: 0,
    summaryExplanation: 'No tasks scheduled for this period.',
  );
}

class StreakCalculationResult {
  final int currentStreak;
  final int longestStreak;
  final int totalSuccessfulDays;
  final bool isTodaySuccessful;

  const StreakCalculationResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalSuccessfulDays,
    required this.isTodaySuccessful,
  });

  static const StreakCalculationResult zero = StreakCalculationResult(
    currentStreak: 0,
    longestStreak: 0,
    totalSuccessfulDays: 0,
    isTodaySuccessful: false,
  );
}

class ProductivityCalculator {
  static ProductivityScoreBreakdown calculateScore({
    required List<TaskModel> tasks,
    required int currentStreak,
  }) {
    if (tasks.isEmpty) {
      return ProductivityScoreBreakdown.empty;
    }

    final int totalTasks = tasks.length;
    final int completedTasks = tasks.where((t) => t.completed).length;
    final double completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    // 1. Completion Points (Max 40)
    final int completionPts = (completionRate * 40).round();

    // 2. High Priority Points (Max 30)
    final highPriorityTasks = tasks.where((t) => t.priority == TaskPriority.high).toList();
    int priorityPts;
    if (highPriorityTasks.isNotEmpty) {
      final completedHighPri = highPriorityTasks.where((t) => t.completed).length;
      final highPriRate = completedHighPri / highPriorityTasks.length;
      priorityPts = (highPriRate * 30).round();
    } else {
      priorityPts = (completionRate * 30).round();
    }

    // 3. Punctuality / Overdue Penalty (Max 15)
    final overdueCount = tasks.where((t) => t.isOverdue).length;
    int punctualityPts;
    if (overdueCount == 0) {
      punctualityPts = 15;
    } else {
      final penalty = overdueCount * 5;
      punctualityPts = max(0, 15 - penalty);
    }

    // 4. Consistency Factor (Max 15 based on streak)
    int consistencyPts;
    if (currentStreak >= 5) {
      consistencyPts = 15;
    } else if (currentStreak >= 3) {
      consistencyPts = 10;
    } else if (currentStreak >= 1) {
      consistencyPts = 5;
    } else {
      consistencyPts = (completionRate > 0.5) ? 3 : 0;
    }

    final int total = (completionPts + priorityPts + punctualityPts + consistencyPts).clamp(0, 100);

    final StringBuffer explanation = StringBuffer();
    explanation.write('Completed $completedTasks of $totalTasks planned tasks');
    if (highPriorityTasks.isNotEmpty) {
      final completedHighPri = highPriorityTasks.where((t) => t.completed).length;
      explanation.write(' and $completedHighPri of ${highPriorityTasks.length} high-priority tasks.');
    } else {
      explanation.write('.');
    }
    if (overdueCount > 0) {
      explanation.write(' $overdueCount task(s) currently overdue.');
    }

    return ProductivityScoreBreakdown(
      totalScore: total,
      completionPoints: completionPts,
      priorityPoints: priorityPts,
      punctualityPoints: punctualityPts,
      consistencyPoints: consistencyPts,
      summaryExplanation: explanation.toString(),
    );
  }

  static StreakCalculationResult calculateStreaks({
    required List<TaskModel> allTasks,
    List<TaskOccurrenceModel> occurrences = const [],
    int thresholdPercentage = 70,
  }) {
    if (allTasks.isEmpty) return StreakCalculationResult.zero;

    final now = DateTime.now();
    final todayNormalized = AppDateUtils.normalizeDate(now);
    final todayStr = AppDateUtils.toIsoDate(todayNormalized);

    // Group tasks by date string (YYYY-MM-DD)
    final Map<String, List<TaskModel>> dateMap = {};

    // 1. Add non-recurring tasks
    for (final task in allTasks) {
      if (!task.isRecurring && task.isTopLevel) {
        dateMap.putIfAbsent(task.date, () => []).add(task);
      }
    }

    // 2. Add recurring tasks dynamically across history (up to today + 7 days)
    final occMap = {for (final o in occurrences) '${o.taskId}_${o.date}': o};
    final recurringTasks = allTasks.where((t) => t.isRecurring && t.isTopLevel).toList();

    if (recurringTasks.isNotEmpty) {
      // Find earliest start date among recurring tasks
      DateTime earliestDate = todayNormalized.subtract(const Duration(days: 90));
      for (final rt in recurringTasks) {
        if (rt.scheduledDate.isBefore(earliestDate)) {
          earliestDate = rt.scheduledDate;
        }
      }

      DateTime cur = earliestDate;
      while (!cur.isAfter(todayNormalized)) {
        final curIso = AppDateUtils.toIsoDate(cur);
        for (final rt in recurringTasks) {
          if (rt.isOccurringOnDate(cur)) {
            final occ = occMap['${rt.id}_$curIso'];
            if (occ != null && occ.isSkipped) continue;

            final isCompleted = occ != null ? occ.completed : false;
            dateMap.putIfAbsent(curIso, () => []).add(
                  rt.copyWith(
                    date: curIso,
                    completed: isCompleted,
                    completedAt: occ?.completedAt,
                  ),
                );
          }
        }
        cur = cur.add(const Duration(days: 1));
      }
    }

    // Calculate which days met the threshold
    final Map<String, bool> successfulDays = {};
    for (final entry in dateMap.entries) {
      final tasksOnDay = entry.value;
      if (tasksOnDay.isEmpty) continue;
      final completed = tasksOnDay.where((t) => t.completed).length;
      final percentage = (completed / tasksOnDay.length) * 100;
      successfulDays[entry.key] = percentage >= thresholdPercentage;
    }

    final bool isTodaySuccessful = successfulDays[todayStr] ?? false;
    final int totalSuccessful = successfulDays.values.where((v) => v).length;

    // Calculate current streak backward from today or yesterday
    int currentStreak = 0;
    DateTime checkDate = todayNormalized;

    final todayTasks = dateMap[todayStr] ?? [];
    if (todayTasks.isEmpty || !isTodaySuccessful) {
      // If today has no tasks or hasn't finished yet, count streak ending at yesterday
      checkDate = todayNormalized.subtract(const Duration(days: 1));
    }

    while (true) {
      final dateStr = AppDateUtils.toIsoDate(checkDate);
      final tasksOnDate = dateMap[dateStr];

      if (successfulDays[dateStr] == true) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (tasksOnDate == null || tasksOnDate.isEmpty) {
        // Rest day (0 scheduled tasks): do not break streak, but check earlier
        checkDate = checkDate.subtract(const Duration(days: 1));
        // Avoid infinite loop into the distant past
        if (checkDate.isBefore(todayNormalized.subtract(const Duration(days: 365)))) {
          break;
        }
      } else {
        // Day had tasks but failed threshold -> breaks streak!
        break;
      }
    }

    // Calculate longest streak across history
    final sortedDates = successfulDays.keys.toList()..sort();
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? prevDate;

    for (final dateKey in sortedDates) {
      final isSuccess = successfulDays[dateKey] == true;
      final currentDate = AppDateUtils.parseIsoDate(dateKey);

      if (isSuccess) {
        if (prevDate != null && currentDate.difference(prevDate).inDays == 1) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }
        prevDate = currentDate;
        longestStreak = max(longestStreak, tempStreak);
      } else {
        tempStreak = 0;
        prevDate = null;
      }
    }

    longestStreak = max(longestStreak, currentStreak);

    return StreakCalculationResult(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalSuccessfulDays: totalSuccessful,
      isTodaySuccessful: isTodaySuccessful,
    );
  }
}