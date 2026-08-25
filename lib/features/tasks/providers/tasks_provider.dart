import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:daypulse/core/database/database_provider.dart';
import 'package:daypulse/core/notifications/notification_service.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/tasks/models/reminder_offset.dart';
import 'package:daypulse/features/tasks/models/repeat_rule.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/models/task_occurrence_model.dart';
import 'package:daypulse/features/tasks/models/task_priority.dart';
import 'package:daypulse/features/tasks/repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository?>((ref) {
  final db = ref.watch(databaseProvider).value;
  if (db == null) return null;
  return TaskRepository(db);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final tasksNotifierProvider = StateNotifierProvider<TasksNotifier, AsyncValue<List<TaskModel>>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final notifService = ref.watch(notificationServiceProvider);
  return TasksNotifier(repository, notifService);
});

// Top-level tasks (parentId == null)
final topLevelTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasksAsync = ref.watch(tasksNotifierProvider);
  final allTasks = tasksAsync.value ?? [];
  return allTasks.where((t) => t.isTopLevel).toList();
});

// Subtasks for a specific parent task
final subtasksForParentProvider = Provider.family<List<TaskModel>, String>((ref, parentId) {
  final tasksNotifier = ref.watch(tasksNotifierProvider.notifier);
  return tasksNotifier.getSubtasksForParent(parentId);
});

// Subtasks for a specific parent task on a specific occurrence date
final subtasksForParentOnDateProvider = Provider.family<List<TaskModel>, ({String parentId, String dateIso})>((ref, args) {
  final tasksNotifier = ref.watch(tasksNotifierProvider.notifier);
  return tasksNotifier.getSubtasksForParent(args.parentId, occurrenceDate: args.dateIso);
});

// Tasks occurring on a specific ISO date (synthesizing recurring occurrences dynamically)
final tasksForDateProvider = Provider.family<List<TaskModel>, String>((ref, dateIso) {
  ref.watch(tasksNotifierProvider); // re-evaluate when tasks change
  final tasksNotifier = ref.watch(tasksNotifierProvider.notifier);
  final targetDate = AppDateUtils.parseIsoDate(dateIso);
  return tasksNotifier.getTasksForDate(targetDate);
});

class TasksNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final TaskRepository? _repository;
  final NotificationService _notificationService;
  List<TaskOccurrenceModel> _occurrences = [];

  TasksNotifier(this._repository, this._notificationService) : super(const AsyncValue.loading()) {
    if (_repository != null) {
      loadTasks();
    }
  }

  List<TaskOccurrenceModel> get occurrences => _occurrences;

  Future<void> loadTasks() async {
    if (_repository == null) return;
    try {
      final tasks = await _repository.getAllTasks();
      _occurrences = await _repository.getAllOccurrences();
      state = AsyncValue.data(tasks);

      // Re-sync future notifications
      for (final t in tasks) {
        if (t.reminderEnabled && !t.completed) {
          _scheduleReminderIfNeeded(t);
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Synthesizes tasks dynamically for any target date
  List<TaskModel> getTasksForDate(DateTime date) {
    final dateIso = AppDateUtils.toIsoDate(date);
    final allBaseTasks = state.value ?? [];
    final occurrencesOnDate = _occurrences.where((o) => o.date == dateIso).toList();
    final occurrenceMap = {for (final o in occurrencesOnDate) o.taskId: o};

    final List<TaskModel> result = [];

    for (final task in allBaseTasks) {
      if (task.isSubtask) continue; // Top-level tasks only

      if (!task.isRecurring) {
        if (task.date == dateIso) {
          result.add(task);
        }
      } else {
        // Recurring task
        if (task.isOccurringOnDate(date)) {
          final occ = occurrenceMap[task.id];
          if (occ != null && occ.isSkipped) {
            continue; // Skipped occurrence
          }

          final isCompleted = occ != null ? occ.completed : false;
          final completedAt = occ?.completedAt;

          result.add(task.copyWith(
            date: dateIso,
            completed: isCompleted,
            completedAt: completedAt,
          ));
        }
      }
    }

    result.sort((a, b) {
      final aTime = a.startTime ?? '99:99';
      final bTime = b.startTime ?? '99:99';
      final timeComp = aTime.compareTo(bTime);
      if (timeComp != 0) return timeComp;
      return b.priority.index.compareTo(a.priority.index);
    });

    return result;
  }

  /// Returns subtasks for parent task, accounting for occurrence date if recurring
  List<TaskModel> getSubtasksForParent(String parentId, {String? occurrenceDate}) {
    final allBaseTasks = state.value ?? [];
    final baseSubtasks = allBaseTasks.where((t) => t.parentId == parentId).toList();
    if (baseSubtasks.isEmpty) return [];

    final parent = allBaseTasks.where((t) => t.id == parentId).firstOrNull;
    if (parent == null || !parent.isRecurring || occurrenceDate == null) {
      return baseSubtasks;
    }

    final occurrencesOnDate = _occurrences.where((o) => o.date == occurrenceDate).toList();
    final occurrenceMap = {for (final o in occurrencesOnDate) o.taskId: o};

    return baseSubtasks.map((s) {
      final occ = occurrenceMap[s.id];
      if (occ != null) {
        return s.copyWith(
          date: occurrenceDate,
          completed: occ.completed,
          completedAt: occ.completedAt,
        );
      }
      return s.copyWith(date: occurrenceDate, completed: false, completedAt: null);
    }).toList();
  }

  Future<void> addTask(TaskModel task) async {
    if (_repository == null) return;
    try {
      await _repository.insertTask(task);
      _scheduleReminderIfNeeded(task);
      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTaskWithSubtasks(TaskModel parentTask, List<String> subtaskTitles) async {
    if (_repository == null) return;
    try {
      await _repository.insertTask(parentTask);
      _scheduleReminderIfNeeded(parentTask);

      for (final title in subtaskTitles) {
        if (title.trim().isEmpty) continue;
        final subtask = TaskModel(
          id: const Uuid().v4(),
          parentId: parentTask.id,
          title: title.trim(),
          categoryId: parentTask.categoryId,
          date: parentTask.date,
          priority: parentTask.priority,
          completed: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _repository.insertTask(subtask);
      }

      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TaskModel?> addSubtask({
    required String parentId,
    required String title,
  }) async {
    if (_repository == null) return null;
    try {
      final currentTasks = state.value ?? [];
      final parent = currentTasks.where((t) => t.id == parentId).firstOrNull;

      final subtask = TaskModel(
        id: const Uuid().v4(),
        parentId: parentId,
        title: title.trim(),
        categoryId: parent?.categoryId,
        date: parent?.date ?? AppDateUtils.toIsoDate(DateTime.now()),
        priority: parent?.priority ?? TaskPriority.medium,
        completed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.insertTask(subtask);

      if (parent != null && parent.completed && !parent.isRecurring) {
        await _repository.toggleTaskCompletion(parent.id, false);
      }

      await loadTasks();
      return subtask;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    if (_repository == null) return;
    try {
      await _repository.updateTask(task);
      if (task.reminderEnabled && !task.completed) {
        _scheduleReminderIfNeeded(task);
      } else {
        await _notificationService.cancelTaskReminder(task.id);
      }
      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(String id, {bool thisOccurrenceOnly = false, String? occurrenceDate}) async {
    if (_repository == null) return;
    try {
      if (thisOccurrenceOnly && occurrenceDate != null) {
        await _repository.setOccurrenceSkipped(id, occurrenceDate, true);
      } else {
        await _notificationService.cancelTaskReminder(id);
        await _repository.deleteOccurrencesForTask(id);
        await _repository.deleteTask(id);
      }
      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleTaskCompletion(String id, bool completed, {String? occurrenceDate}) async {
    if (_repository == null) return;
    try {
      final currentTasks = state.value ?? [];
      final task = currentTasks.firstWhere((t) => t.id == id, orElse: () => throw Exception('Task not found'));
      final targetDate = occurrenceDate ?? task.date;

      if (task.isRecurring) {
        await _repository.setOccurrenceCompletion(id, targetDate, completed);

        // If top-level recurring task completed, sync subtasks for this date
        if (task.isTopLevel) {
          final subtasks = currentTasks.where((t) => t.parentId == id).toList();
          for (final s in subtasks) {
            await _repository.setOccurrenceCompletion(s.id, targetDate, completed);
          }
        }
      } else if (task.isSubtask) {
        final parent = currentTasks.where((t) => t.id == task.parentId).firstOrNull;
        if (parent != null && parent.isRecurring) {
          await _repository.setOccurrenceCompletion(id, targetDate, completed);
          final siblings = currentTasks.where((t) => t.parentId == parent.id).toList();
          final occs = await _repository.getOccurrencesForDate(targetDate);
          final occMap = {for (final o in occs) o.taskId: o.completed};

          final allSiblingsCompleted = siblings.isNotEmpty && siblings.every((s) {
            if (s.id == id) return completed;
            return occMap[s.id] ?? false;
          });

          if (allSiblingsCompleted) {
            await _repository.setOccurrenceCompletion(parent.id, targetDate, true);
          } else if (!completed) {
            await _repository.setOccurrenceCompletion(parent.id, targetDate, false);
          }
        } else {
          await _repository.toggleTaskCompletion(id, completed);
          if (parent != null) {
            final siblings = currentTasks.where((t) => t.parentId == parent.id).toList();
            final allSiblingsCompleted = siblings.isNotEmpty && siblings.every((s) => s.id == id ? completed : s.completed);
            if (allSiblingsCompleted) {
              await _repository.toggleTaskCompletion(parent.id, true);
            } else if (!completed && parent.completed) {
              await _repository.toggleTaskCompletion(parent.id, false);
            }
          }
        }
      } else {
        await _repository.toggleTaskCompletion(id, completed);
        if (task.isTopLevel) {
          final subtasks = currentTasks.where((t) => t.parentId == id).toList();
          for (final s in subtasks) {
            if (s.completed != completed) {
              await _repository.toggleTaskCompletion(s.id, completed);
            }
          }
        }
      }

      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rescheduleTask(String id, DateTime newDate, {TimeOfDay? newTime}) async {
    if (_repository == null) return;
    try {
      final dateIso = AppDateUtils.toIsoDate(newDate);
      final timeStr = newTime != null ? AppDateUtils.timeOfDayToString(newTime) : null;
      await _repository.rescheduleTask(id, dateIso, newStartTime: timeStr);

      final currentTasks = state.value ?? [];
      final task = currentTasks.firstWhere((t) => t.id == id, orElse: () => throw Exception('Task not found'));
      final updatedTask = task.copyWith(
        date: dateIso,
        startTime: timeStr ?? task.startTime,
      );

      if (updatedTask.reminderEnabled && !updatedTask.completed) {
        _scheduleReminderIfNeeded(updatedTask);
      }

      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> moveOverdueTaskToToday(String id) async {
    final today = AppDateUtils.normalizeDate(DateTime.now());
    await rescheduleTask(id, today);
  }

  void _scheduleReminderIfNeeded(TaskModel task) {
    if (!task.reminderEnabled || task.completed) return;

    int offsetMinutes = 0;
    if (task.reminderTime != null && task.reminderTime != 'none') {
      final offset = ReminderOffset.fromString(task.reminderTime);
      offsetMinutes = offset.minutesBefore ?? 0;
    }

    final now = DateTime.now();

    if (task.isRecurring) {
      // Schedule reminders for the next 14 upcoming occurrences
      final today = AppDateUtils.normalizeDate(now);
      DateTime cur = today;
      final cutoff = today.add(const Duration(days: 14));

      while (!cur.isAfter(cutoff)) {
        if (task.isOccurringOnDate(cur)) {
          final curIso = AppDateUtils.toIsoDate(cur);
          DateTime scheduledDt;
          if (task.startTimeOfDay != null) {
            scheduledDt = DateTime(cur.year, cur.month, cur.day, task.startTimeOfDay!.hour, task.startTimeOfDay!.minute);
          } else {
            scheduledDt = DateTime(cur.year, cur.month, cur.day, 9, 0);
          }

          final reminderDateTime = scheduledDt.subtract(Duration(minutes: offsetMinutes));
          if (reminderDateTime.isAfter(now)) {
            _notificationService.scheduleTaskReminder(
              taskId: '${task.id}_$curIso',
              title: 'Task Reminder: ${task.title}',
              body: offsetMinutes > 0
                  ? '${task.title} starts in $offsetMinutes minutes.'
                  : 'It\'s time to start ${task.title}!',
              scheduledDateTime: reminderDateTime,
            );
          }
        }
        cur = cur.add(const Duration(days: 1));
      }
    } else {
      DateTime scheduledDt;
      if (task.scheduledDateTime != null) {
        scheduledDt = task.scheduledDateTime!;
      } else {
        final d = task.scheduledDate;
        scheduledDt = DateTime(d.year, d.month, d.day, 9, 0);
      }

      final reminderDateTime = scheduledDt.subtract(Duration(minutes: offsetMinutes));
      if (reminderDateTime.isAfter(now)) {
        _notificationService.scheduleTaskReminder(
          taskId: task.id,
          title: 'Task Reminder: ${task.title}',
          body: offsetMinutes > 0
              ? '${task.title} starts in $offsetMinutes minutes.'
              : 'It\'s time to start ${task.title}!',
          scheduledDateTime: reminderDateTime,
        );
      }
    }
  }

  Future<void> clearAll() async {
    if (_repository == null) return;
    await _notificationService.cancelAllReminders();
    await _repository.clearAllData();
    await loadTasks();
  }

  Future<String> exportJson() async {
    if (_repository == null) throw Exception('Database not ready');
    return await _repository.exportDataAsJson();
  }

  Future<int> importJson(String jsonString, {bool overwrite = false}) async {
    if (_repository == null) throw Exception('Database not ready');
    final count = await _repository.importDataFromJson(jsonString, overwrite: overwrite);
    await loadTasks();
    return count;
  }
}