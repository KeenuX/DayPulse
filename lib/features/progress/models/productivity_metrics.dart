import 'package:daypulse/features/progress/models/streak_data.dart';
import 'package:daypulse/core/utilities/productivity_calculator.dart';

class DailyMetric {
  final DateTime date;
  final String dayLabel; // "Mon", "Tue", etc.
  final int plannedCount;
  final int completedCount;
  final double completionRate;

  const DailyMetric({
    required this.date,
    required this.dayLabel,
    required this.plannedCount,
    required this.completedCount,
    required this.completionRate,
  });
}

class CategoryDistribution {
  final String categoryId;
  final String categoryName;
  final int colorValue;
  final int taskCount;
  final int completedCount;
  final double percentage; // 0.0 to 1.0

  const CategoryDistribution({
    required this.categoryId,
    required this.categoryName,
    required this.colorValue,
    required this.taskCount,
    required this.completedCount,
    required this.percentage,
  });
}

class ProgressDashboardData {
  // Score
  final ProductivityScoreBreakdown scoreBreakdown;

  // Streak
  final StreakData streakData;

  // Weekly (Last 7 days)
  final List<DailyMetric> weeklyMetrics;
  final String mostProductiveDay;
  final String mostProductiveCategory;

  // Monthly (Last 30 days)
  final int monthlyCompletedTasks;
  final int monthlyTotalTasks;
  final double monthlyAverageCompletionRate;
  final List<DailyMetric> monthlyTrendMetrics;
  final List<CategoryDistribution> categoryDistribution;
  final String bestProductivityDay;

  const ProgressDashboardData({
    required this.scoreBreakdown,
    required this.streakData,
    required this.weeklyMetrics,
    required this.mostProductiveDay,
    required this.mostProductiveCategory,
    required this.monthlyCompletedTasks,
    required this.monthlyTotalTasks,
    required this.monthlyAverageCompletionRate,
    required this.monthlyTrendMetrics,
    required this.categoryDistribution,
    required this.bestProductivityDay,
  });
}