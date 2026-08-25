import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/features/tasks/models/task_filter.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/models/task_sort.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

final taskFilterProvider = StateProvider<TaskFilter>((ref) {
  return const TaskFilter();
});

final taskSortProvider = StateProvider<TaskSortOption>((ref) {
  return TaskSortOption.time;
});

final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasksAsync = ref.watch(tasksNotifierProvider);
  final filter = ref.watch(taskFilterProvider);
  final sort = ref.watch(taskSortProvider);

  return tasksAsync.when(
    data: (tasks) {
      List<TaskModel> result = List.from(tasks);

      // 1. Status Filter
      switch (filter.status) {
        case TaskStatusFilter.all:
          break;
        case TaskStatusFilter.active:
          result = result.where((t) => !t.completed).toList();
          break;
        case TaskStatusFilter.completed:
          result = result.where((t) => t.completed).toList();
          break;
        case TaskStatusFilter.overdue:
          result = result.where((t) => t.isOverdue).toList();
          break;
      }

      // 2. Category Filter
      if (filter.categoryId != null) {
        result = result.where((t) => t.categoryId == filter.categoryId).toList();
      }

      // 3. Priority Filter
      if (filter.priority != null) {
        result = result.where((t) => t.priority == filter.priority).toList();
      }

      // 4. Date Filter
      if (filter.date != null) {
        result = result.where((t) => t.date == filter.date).toList();
      }

      // 5. Search Query Filter & Hierarchical Visibility
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final query = filter.searchQuery!.trim().toLowerCase();
        // In search mode, find matching tasks or subtasks
        final matchingIds = <String>{};
        for (final t in tasks) {
          final titleMatch = t.title.toLowerCase().contains(query);
          final descMatch = t.description?.toLowerCase().contains(query) ?? false;
          final notesMatch = t.notes?.toLowerCase().contains(query) ?? false;
          if (titleMatch || descMatch || notesMatch) {
            matchingIds.add(t.id);
            if (t.parentId != null) {
              matchingIds.add(t.parentId!); // include parent so user sees context
            }
          }
        }
        result = result.where((t) => matchingIds.contains(t.id)).toList();
      } else {
        // By default on task feeds/lists, show top-level tasks (subtasks are embedded inside them)
        result = result.where((t) => t.isTopLevel).toList();
      }

      // 6. Sorting
      result.sort((a, b) {
        switch (sort) {
          case TaskSortOption.time:
            final dateComp = a.date.compareTo(b.date);
            if (dateComp != 0) return dateComp;
            final aTime = a.startTime ?? '99:99';
            final bTime = b.startTime ?? '99:99';
            return aTime.compareTo(bTime);

          case TaskSortOption.priority:
            final priComp = b.priority.weight.compareTo(a.priority.weight);
            if (priComp != 0) return priComp;
            return a.date.compareTo(b.date);

          case TaskSortOption.creation:
            return b.createdAt.compareTo(a.createdAt);

          case TaskSortOption.category:
            final aCat = a.categoryId ?? '';
            final bCat = b.categoryId ?? '';
            return aCat.compareTo(bCat);
        }
      });

      return result;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final overdueTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasksAsync = ref.watch(tasksNotifierProvider);
  return tasksAsync.when(
    data: (tasks) => tasks.where((t) => t.isOverdue && t.isTopLevel).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});