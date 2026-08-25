import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
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
      final tasksNotifier = ref.watch(tasksNotifierProvider.notifier);
      final occurrences = tasksNotifier.occurrences;
      final todayIso = AppDateUtils.toIsoDate(DateTime.now());
      final targetDateIso = filter.date ?? todayIso;

      final occOnTarget = occurrences.where((o) => o.date == targetDateIso).toList();
      final occMap = {for (final o in occOnTarget) o.taskId: o};

      List<TaskModel> result = [];

      // 1. Status Filter with occurrence synthesis
      switch (filter.status) {
        case TaskStatusFilter.all:
          result = tasks.map((t) {
            if (t.isRecurring) {
              final occ = occMap[t.id];
              return t.copyWith(
                date: targetDateIso,
                completed: occ != null ? occ.completed : false,
                completedAt: occ?.completedAt,
              );
            }
            return t;
          }).toList();
          break;

        case TaskStatusFilter.active:
          result = tasks.where((t) {
            if (t.isRecurring) {
              final occ = occMap[t.id];
              return occ == null || !occ.completed;
            }
            return !t.completed;
          }).map((t) {
            if (t.isRecurring) {
              return t.copyWith(date: targetDateIso, completed: false);
            }
            return t;
          }).toList();
          break;

        case TaskStatusFilter.completed:
          final List<TaskModel> completedList = [];
          // A. Non-recurring completed tasks
          for (final t in tasks) {
            if (!t.isRecurring && t.completed) {
              completedList.add(t);
            }
          }
          // B. Recurring tasks completed occurrences
          final recurringMap = {for (final t in tasks.where((t) => t.isRecurring)) t.id: t};
          for (final occ in occurrences) {
            if (occ.completed && !occ.isSkipped) {
              final parent = recurringMap[occ.taskId];
              if (parent != null) {
                completedList.add(parent.copyWith(
                  date: occ.date,
                  completed: true,
                  completedAt: occ.completedAt,
                ));
              }
            }
          }
          result = completedList;
          break;

        case TaskStatusFilter.overdue:
          result = tasks.where((t) => !t.isRecurring && t.isOverdue).toList();
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