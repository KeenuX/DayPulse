import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/models/task_priority.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

enum CalendarViewMode {
  month('Month'),
  week('Week'),
  day('Day');

  final String label;
  const CalendarViewMode(this.label);
}

class CalendarFilterState {
  final String? categoryId; // null = all
  final TaskPriority? priority; // null = all
  final bool? isCompleted; // null = all, true = completed, false = pending

  const CalendarFilterState({
    this.categoryId,
    this.priority,
    this.isCompleted,
  });

  bool get hasActiveFilter => categoryId != null || priority != null || isCompleted != null;

  CalendarFilterState copyWith({
    String? categoryId,
    bool clearCategory = false,
    TaskPriority? priority,
    bool clearPriority = false,
    bool? isCompleted,
    bool clearCompleted = false,
  }) {
    return CalendarFilterState(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      priority: clearPriority ? null : (priority ?? this.priority),
      isCompleted: clearCompleted ? null : (isCompleted ?? this.isCompleted),
    );
  }
}

final calendarFilterProvider = StateProvider<CalendarFilterState>((ref) {
  return const CalendarFilterState();
});

final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  return AppDateUtils.normalizeDate(DateTime.now());
});

final calendarViewModeProvider = StateProvider<CalendarViewMode>((ref) {
  return CalendarViewMode.month;
});

final calendarTasksForSelectedDateProvider = Provider<List<TaskModel>>((ref) {
  final tasksAsync = ref.watch(tasksNotifierProvider);
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final filter = ref.watch(calendarFilterProvider);

  return tasksAsync.when(
    data: (_) {
      final tasks = ref.watch(tasksNotifierProvider.notifier).getTasksForDate(selectedDate);
      return tasks.where((t) {
        if (!t.isTopLevel) return false;
        if (filter.categoryId != null && t.categoryId != filter.categoryId) return false;
        if (filter.priority != null && t.priority != filter.priority) return false;
        if (filter.isCompleted != null && t.completed != filter.isCompleted) return false;
        return true;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});