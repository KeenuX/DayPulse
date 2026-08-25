import 'package:daypulse/features/tasks/models/task_priority.dart';

enum TaskStatusFilter {
  all('All'),
  active('Active'),
  completed('Completed'),
  overdue('Overdue');

  final String label;
  const TaskStatusFilter(this.label);
}

class TaskFilter {
  final TaskStatusFilter status;
  final String? categoryId;
  final TaskPriority? priority;
  final String? searchQuery;
  final String? date; // YYYY-MM-DD (optional filter)

  const TaskFilter({
    this.status = TaskStatusFilter.all,
    this.categoryId,
    this.priority,
    this.searchQuery,
    this.date,
  });

  TaskFilter copyWith({
    TaskStatusFilter? status,
    String? categoryId,
    bool clearCategory = false,
    TaskPriority? priority,
    bool clearPriority = false,
    String? searchQuery,
    String? date,
    bool clearDate = false,
  }) {
    return TaskFilter(
      status: status ?? this.status,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      priority: clearPriority ? null : (priority ?? this.priority),
      searchQuery: searchQuery ?? this.searchQuery,
      date: clearDate ? null : (date ?? this.date),
    );
  }
}