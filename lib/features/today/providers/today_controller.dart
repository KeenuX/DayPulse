import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';
import 'package:daypulse/features/today/models/time_block.dart';

class TodayStats {
  final int totalCount;
  final int completedCount;
  final int remainingCount;
  final double completionPercentage;
  final int completedDurationMinutes;
  final int plannedDurationMinutes;

  const TodayStats({
    required this.totalCount,
    required this.completedCount,
    required this.remainingCount,
    required this.completionPercentage,
    required this.completedDurationMinutes,
    required this.plannedDurationMinutes,
  });

  static const TodayStats empty = TodayStats(
    totalCount: 0,
    completedCount: 0,
    remainingCount: 0,
    completionPercentage: 0.0,
    completedDurationMinutes: 0,
    plannedDurationMinutes: 0,
  );
}

final todayDateProvider = Provider<DateTime>((ref) {
  return AppDateUtils.normalizeDate(DateTime.now());
});

final todayTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasksAsync = ref.watch(tasksNotifierProvider);
  final today = ref.watch(todayDateProvider);

  return tasksAsync.when(
    data: (_) {
      final todayList = ref.watch(tasksNotifierProvider.notifier).getTasksForDate(today);
      return todayList;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final todayTimeBlockTasksProvider = Provider<Map<TimeBlockType, List<TaskModel>>>((ref) {
  final tasks = ref.watch(todayTasksProvider);

  final Map<TimeBlockType, List<TaskModel>> grouped = {
    TimeBlockType.morning: [],
    TimeBlockType.afternoon: [],
    TimeBlockType.evening: [],
    TimeBlockType.unscheduled: [],
  };

  for (final task in tasks) {
    if (task.startTime == null) {
      grouped[TimeBlockType.unscheduled]!.add(task);
      continue;
    }

    final tod = task.startTimeOfDay;
    if (tod == null) {
      grouped[TimeBlockType.unscheduled]!.add(task);
    } else if (tod.hour < 12) {
      grouped[TimeBlockType.morning]!.add(task);
    } else if (tod.hour < 17) {
      grouped[TimeBlockType.afternoon]!.add(task);
    } else {
      grouped[TimeBlockType.evening]!.add(task);
    }
  }

  return grouped;
});

final todayStatsProvider = Provider<TodayStats>((ref) {
  final tasks = ref.watch(todayTasksProvider);
  if (tasks.isEmpty) return TodayStats.empty;

  final total = tasks.length;
  final completed = tasks.where((t) => t.completed).length;
  final remaining = total - completed;
  final percentage = total > 0 ? completed / total : 0.0;

  int plannedMins = 0;
  int completedMins = 0;

  for (final task in tasks) {
    final dur = task.durationMinutes ?? 30; // fallback 30 mins
    plannedMins += dur;
    if (task.completed) {
      completedMins += dur;
    }
  }

  return TodayStats(
    totalCount: total,
    completedCount: completed,
    remainingCount: remaining,
    completionPercentage: percentage,
    completedDurationMinutes: completedMins,
    plannedDurationMinutes: plannedMins,
  );
});