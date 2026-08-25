import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:daypulse/core/theme/theme_provider.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/core/utilities/productivity_calculator.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';
import 'package:daypulse/features/progress/models/productivity_metrics.dart';
import 'package:daypulse/features/progress/models/streak_data.dart';

final progressAnalyticsProvider = Provider<ProgressDashboardData?>((ref) {
  final tasksAsync = ref.watch(tasksNotifierProvider);
  final categoriesAsync = ref.watch(categoriesNotifierProvider);
  final prefs = ref.watch(preferencesServiceProvider);

  final tasks = tasksAsync.value?.where((t) => t.isTopLevel).toList();
  final categories = categoriesAsync.value;

  if (tasks == null || categories == null) return null;

  final tasksNotifier = ref.watch(tasksNotifierProvider.notifier);
  final occurrences = tasksNotifier.occurrences;

  final int streakThreshold = prefs.streakThreshold;

  // 1. Calculate Streaks
  final streakResult = ProductivityCalculator.calculateStreaks(
    allTasks: tasks,
    occurrences: occurrences,
    thresholdPercentage: streakThreshold,
  );

  final streakData = StreakData(
    currentStreak: streakResult.currentStreak,
    longestStreak: streakResult.longestStreak,
    totalSuccessfulDays: streakResult.totalSuccessfulDays,
    isTodaySuccessful: streakResult.isTodaySuccessful,
    streakThresholdPercentage: streakThreshold,
  );

  // 2. Today's score
  final todayTasks = tasksNotifier.getTasksForDate(DateTime.now());
  final scoreBreakdown = ProductivityCalculator.calculateScore(
    tasks: todayTasks,
    currentStreak: streakResult.currentStreak,
  );

  // 3. Weekly Metrics (Last 7 Days)
  final now = DateTime.now();
  final List<DailyMetric> weeklyMetrics = [];
  final dayFormat = DateFormat('E'); // Mon, Tue...

  for (int i = 6; i >= 0; i--) {
    final d = now.subtract(Duration(days: i));
    final dayTasks = tasksNotifier.getTasksForDate(d);
    final planned = dayTasks.length;
    final completed = dayTasks.where((t) => t.completed).length;
    final rate = planned > 0 ? completed / planned : 0.0;

    weeklyMetrics.add(DailyMetric(
      date: d,
      dayLabel: dayFormat.format(d),
      plannedCount: planned,
      completedCount: completed,
      completionRate: rate,
    ));
  }

  // Find most productive day of week
  String mostProductiveDay = 'None yet';
  int maxDayCompleted = 0;
  for (final m in weeklyMetrics) {
    if (m.completedCount > maxDayCompleted) {
      maxDayCompleted = m.completedCount;
      mostProductiveDay = DateFormat('EEEE').format(m.date);
    }
  }

  // 4. Monthly Metrics (Last 30 Days)
  final List<DailyMetric> monthlyMetrics = [];
  int monthlyCompleted = 0;
  int monthlyTotal = 0;

  for (int i = 29; i >= 0; i--) {
    final d = now.subtract(Duration(days: i));
    final dayTasks = tasksNotifier.getTasksForDate(d);
    final planned = dayTasks.length;
    final completed = dayTasks.where((t) => t.completed).length;
    final rate = planned > 0 ? completed / planned : 0.0;

    monthlyTotal += planned;
    monthlyCompleted += completed;

    monthlyMetrics.add(DailyMetric(
      date: d,
      dayLabel: '${d.day}/${d.month}',
      plannedCount: planned,
      completedCount: completed,
      completionRate: rate,
    ));
  }

  final double monthlyAvgRate = monthlyTotal > 0 ? monthlyCompleted / monthlyTotal : 0.0;

  // 5. Category Distribution (including General / No Category tasks)
  final Map<String, int> catTotalMap = {};
  final Map<String, int> catCompletedMap = {};

  for (final t in tasks) {
    final catId = t.categoryId ?? '__general__';
    catTotalMap[catId] = (catTotalMap[catId] ?? 0) + 1;
    if (!t.isRecurring && t.completed) {
      catCompletedMap[catId] = (catCompletedMap[catId] ?? 0) + 1;
    }
  }

  // Include completed recurring task occurrences
  final taskMap = {for (final t in tasks) t.id: t};
  for (final occ in occurrences) {
    if (occ.completed && !occ.isSkipped) {
      final parent = taskMap[occ.taskId];
      if (parent != null) {
        final catId = parent.categoryId ?? '__general__';
        catCompletedMap[catId] = (catCompletedMap[catId] ?? 0) + 1;
      }
    }
  }

  final List<CategoryDistribution> catDist = [];
  String mostProductiveCategory = 'None';
  int maxCatCompleted = 0;

  final totalTasksCount = tasks.isNotEmpty ? tasks.length : 1;

  for (final cat in categories) {
    final tCount = catTotalMap[cat.id] ?? 0;
    final cCount = catCompletedMap[cat.id] ?? 0;
    if (tCount > 0) {
      if (cCount > maxCatCompleted) {
        maxCatCompleted = cCount;
        mostProductiveCategory = cat.name;
      }
      catDist.add(CategoryDistribution(
        categoryId: cat.id,
        categoryName: cat.name,
        colorValue: cat.colorValue,
        taskCount: tCount,
        completedCount: cCount,
        percentage: tCount / totalTasksCount,
      ));
    }
  }

  // Include General / Uncategorized tasks if present
  final generalTotal = catTotalMap['__general__'] ?? 0;
  final generalCompleted = catCompletedMap['__general__'] ?? 0;
  if (generalTotal > 0) {
    if (generalCompleted > maxCatCompleted) {
      mostProductiveCategory = 'General';
    }
    catDist.add(CategoryDistribution(
      categoryId: '__general__',
      categoryName: 'General',
      colorValue: 0xFF64748B,
      taskCount: generalTotal,
      completedCount: generalCompleted,
      percentage: generalTotal / totalTasksCount,
    ));
  }

  catDist.sort((a, b) => b.taskCount.compareTo(a.taskCount));

  return ProgressDashboardData(
    scoreBreakdown: scoreBreakdown,
    streakData: streakData,
    weeklyMetrics: weeklyMetrics,
    mostProductiveDay: mostProductiveDay,
    mostProductiveCategory: mostProductiveCategory,
    monthlyCompletedTasks: monthlyCompleted,
    monthlyTotalTasks: monthlyTotal,
    monthlyAverageCompletionRate: monthlyAvgRate,
    monthlyTrendMetrics: monthlyMetrics,
    categoryDistribution: catDist,
    bestProductivityDay: mostProductiveDay,
  );
});