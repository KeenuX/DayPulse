import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/core/utilities/duration_formatter.dart';
import 'package:daypulse/core/utilities/natural_language_parser.dart';
import 'package:daypulse/core/utilities/productivity_calculator.dart';
import 'package:daypulse/features/categories/models/category_model.dart';
import 'package:daypulse/features/tasks/models/repeat_rule.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/models/task_occurrence_model.dart';
import 'package:daypulse/features/tasks/models/task_priority.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NaturalLanguageParser Tests', () {
    test('parses simple task with 12-hour PM time', () {
      final parsed = NaturalLanguageParser.parse('Study Machine Learning at 7 PM');
      expect(parsed.title, 'Study Machine Learning');
      expect(parsed.startTime?.hour, 19);
      expect(parsed.startTime?.minute, 0);
      expect(AppDateUtils.isToday(parsed.date), isTrue);
      expect(parsed.priority, TaskPriority.medium);
    });

    test('parses task with priority and tomorrow date', () {
      final parsed = NaturalLanguageParser.parse('Gym workout tomorrow at 6:30 am !high');
      expect(parsed.title, 'Gym workout');
      expect(parsed.startTime?.hour, 6);
      expect(parsed.startTime?.minute, 30);
      expect(AppDateUtils.isTomorrow(parsed.date), isTrue);
      expect(parsed.priority, TaskPriority.high);
    });

    test('parses duration correctly', () {
      final parsed = NaturalLanguageParser.parse('Coding session for 45 mins !low');
      expect(parsed.title, 'Coding session');
      expect(parsed.durationMinutes, 45);
      expect(parsed.priority, TaskPriority.low);
    });
  });

  group('ProductivityCalculator Tests', () {
    test('calculates accurate transparent score', () {
      final now = DateTime.now();
      final todayIso = AppDateUtils.toIsoDate(now);

      final tasks = [
        TaskModel(
          id: '1',
          title: 'T1',
          date: todayIso,
          priority: TaskPriority.high,
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        TaskModel(
          id: '2',
          title: 'T2',
          date: todayIso,
          priority: TaskPriority.high,
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        TaskModel(
          id: '3',
          title: 'T3',
          date: todayIso,
          priority: TaskPriority.medium,
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        TaskModel(
          id: '4',
          title: 'T4',
          date: todayIso,
          priority: TaskPriority.low,
          completed: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final score = ProductivityCalculator.calculateScore(
        tasks: tasks,
        currentStreak: 5,
      );

      expect(score.totalScore, greaterThanOrEqualTo(85));
      expect(score.completionPoints, 30);
      expect(score.priorityPoints, 30);
      expect(score.punctualityPoints, 15);
      expect(score.consistencyPoints, 15);
    });

    test('calculates streaks with threshold accurately', () {
      final now = DateTime.now();
      final today = AppDateUtils.normalizeDate(now);
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBefore = today.subtract(const Duration(days: 2));

      final tasks = [
        TaskModel(
          id: '1',
          title: 'T1',
          date: AppDateUtils.toIsoDate(dayBefore),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        TaskModel(
          id: '2',
          title: 'T2',
          date: AppDateUtils.toIsoDate(yesterday),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
        TaskModel(
          id: '3',
          title: 'T3',
          date: AppDateUtils.toIsoDate(today),
          completed: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final streak = ProductivityCalculator.calculateStreaks(allTasks: tasks, thresholdPercentage: 70);

      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 3);
      expect(streak.isTodaySuccessful, isTrue);
      expect(streak.totalSuccessfulDays, 3);
    });
  });

  group('DurationFormatter Tests', () {
    test('formats hours and minutes accurately', () {
      expect(DurationFormatter.formatMinutes(0, showZero: true), '0m');
      expect(DurationFormatter.formatMinutes(0), '');
      expect(DurationFormatter.formatMinutes(45), '45m');
      expect(DurationFormatter.formatMinutes(60), '1h');
      expect(DurationFormatter.formatMinutes(90), '1h 30m');
      expect(DurationFormatter.formatMinutes(150), '2h 30m');
      expect(DurationFormatter.formatMinutes(null, showZero: true), '0m');
      expect(DurationFormatter.formatMinutes(null), '');
    });
  });

  group('TaskModel and CategoryModel Serialization Tests', () {
    test('TaskModel serializes to and from Map correctly', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 'task_001',
        title: 'Complete Project Architecture',
        description: 'Design and write Clean Architecture docs',
        categoryId: 'cat_work',
        date: '2026-08-25',
        startTime: '10:00',
        endTime: '12:00',
        durationMinutes: 120,
        priority: TaskPriority.high,
        completed: true,
        completedAt: now,
        reminderEnabled: true,
        reminderTime: '15',
        repeatRule: RepeatRule.weekly,
        repeatEndType: RecurrenceEndType.untilDate,
        repeatEndDate: '2026-09-30',
        repeatInterval: 2,
        repeatDaysOfWeek: [1, 3, 5],
        createdAt: now,
        updatedAt: now,
        notes: '# Requirements\n- Keep modular',
      );

      final map = task.toMap();
      final deserialized = TaskModel.fromMap(map);

      expect(deserialized.id, task.id);
      expect(deserialized.title, task.title);
      expect(deserialized.description, task.description);
      expect(deserialized.categoryId, task.categoryId);
      expect(deserialized.date, task.date);
      expect(deserialized.startTime, task.startTime);
      expect(deserialized.endTime, task.endTime);
      expect(deserialized.durationMinutes, 120);
      expect(deserialized.priority, TaskPriority.high);
      expect(deserialized.completed, isTrue);
      expect(deserialized.reminderEnabled, isTrue);
      expect(deserialized.reminderTime, '15');
      expect(deserialized.repeatRule, RepeatRule.weekly);
      expect(deserialized.repeatEndType, RecurrenceEndType.untilDate);
      expect(deserialized.repeatEndDate, '2026-09-30');
      expect(deserialized.repeatInterval, 2);
      expect(deserialized.repeatDaysOfWeek, [1, 3, 5]);
      expect(deserialized.notes, task.notes);
    });

    test('CategoryModel serializes to and from Map correctly', () {
      final now = DateTime.now();
      final category = CategoryModel(
        id: 'cat_flutter',
        name: 'Flutter Dev',
        iconCode: Icons.code_rounded.codePoint,
        colorValue: 0xFF02569B,
        createdAt: now,
      );

      final map = category.toMap();
      final deserialized = CategoryModel.fromMap(map);

      expect(deserialized.id, category.id);
      expect(deserialized.name, category.name);
      expect(deserialized.iconCode, category.iconCode);
      expect(deserialized.colorValue, category.colorValue);
    });
  });

  group('Hierarchical Subtasks Tests', () {
    test('TaskModel supports parent-child relationships and serialization', () {
      final now = DateTime.now();
      final parentTask = TaskModel(
        id: 'parent_1',
        title: 'Launch DayPulse 2.0',
        date: '2026-08-25',
        priority: TaskPriority.high,
        createdAt: now,
        updatedAt: now,
      );

      final subtask1 = TaskModel(
        id: 'sub_1',
        parentId: 'parent_1',
        title: 'Review PRs',
        date: '2026-08-25',
        priority: TaskPriority.medium,
        createdAt: now,
        updatedAt: now,
      );

      expect(parentTask.isTopLevel, isTrue);
      expect(parentTask.isSubtask, isFalse);
      expect(subtask1.isTopLevel, isFalse);
      expect(subtask1.isSubtask, isTrue);
      expect(subtask1.parentId, 'parent_1');

      final subtaskMap = subtask1.toMap();
      final deserializedSubtask = TaskModel.fromMap(subtaskMap);
      expect(deserializedSubtask.parentId, 'parent_1');
    });

    test('calculates subtask progress ratio accurately', () {
      final now = DateTime.now();
      const parentId = 'task_p1';

      final subtasks = [
        TaskModel(id: 's1', parentId: parentId, title: 'Step 1', date: '2026-08-25', completed: true, createdAt: now, updatedAt: now),
        TaskModel(id: 's2', parentId: parentId, title: 'Step 2', date: '2026-08-25', completed: true, createdAt: now, updatedAt: now),
        TaskModel(id: 's3', parentId: parentId, title: 'Step 3', date: '2026-08-25', completed: false, createdAt: now, updatedAt: now),
        TaskModel(id: 's4', parentId: parentId, title: 'Step 4', date: '2026-08-25', completed: false, createdAt: now, updatedAt: now),
      ];

      final completedCount = subtasks.where((s) => s.completed).length;
      final ratio = completedCount / subtasks.length;

      expect(completedCount, 2);
      expect(ratio, 0.5);
    });

    test('completing all subtasks marks parent task completed', () {
      final now = DateTime.now();
      const parentId = 'parent_alpha';

      TaskModel parentTask = TaskModel(
        id: parentId,
        title: 'Design Mockups',
        date: '2026-08-25',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final subtasks = [
        TaskModel(id: 's1', parentId: parentId, title: 'UI Colors', date: '2026-08-25', completed: true, createdAt: now, updatedAt: now),
        TaskModel(id: 's2', parentId: parentId, title: 'Wireframes', date: '2026-08-25', completed: true, createdAt: now, updatedAt: now),
      ];

      final allCompleted = subtasks.isNotEmpty && subtasks.every((s) => s.completed);
      if (allCompleted) {
        parentTask = parentTask.copyWith(completed: true);
      }

      expect(parentTask.completed, isTrue);
    });

    test('unchecking any subtask reopens parent task', () {
      final now = DateTime.now();
      const parentId = 'parent_beta';

      TaskModel parentTask = TaskModel(
        id: parentId,
        title: 'Study Syllabus',
        date: '2026-08-25',
        completed: true,
        createdAt: now,
        updatedAt: now,
      );

      final subtasks = [
        TaskModel(id: 's1', parentId: parentId, title: 'Mathematics', date: '2026-08-25', completed: true, createdAt: now, updatedAt: now),
        TaskModel(id: 's2', parentId: parentId, title: 'Java', date: '2026-08-25', completed: false, createdAt: now, updatedAt: now),
      ];

      final shouldCompleteParent = subtasks.isNotEmpty && subtasks.every((s) => s.completed);
      if (!shouldCompleteParent && parentTask.completed) {
        parentTask = parentTask.copyWith(completed: false);
      }

      expect(parentTask.completed, isFalse);
    });

    test('creating parent task with subtask list generates valid subtask models', () {
      final now = DateTime.now();
      final parentTask = TaskModel(
        id: 'parent_101',
        title: 'Learn Flutter & Android',
        date: '2026-08-25',
        categoryId: 'cat_work',
        priority: TaskPriority.high,
        createdAt: now,
        updatedAt: now,
      );

      final subtaskTitles = ['Widgets', 'State Management', 'Persistence'];
      final subtasks = subtaskTitles.map((title) => TaskModel(
        id: 'sub_${title.toLowerCase()}',
        parentId: parentTask.id,
        title: title,
        categoryId: parentTask.categoryId,
        date: parentTask.date,
        priority: parentTask.priority,
        completed: false,
        createdAt: now,
        updatedAt: now,
      )).toList();

      expect(subtasks.length, 3);
      expect(subtasks.every((s) => s.parentId == 'parent_101'), isTrue);
      expect(subtasks.every((s) => s.categoryId == 'cat_work'), isTrue);
      expect(subtasks.every((s) => s.priority == TaskPriority.high), isTrue);
    });

    test('Me page pending and completed tasks count only considers top-level tasks', () {
      final now = DateTime.now();
      final allTasks = [
        TaskModel(id: 't1', title: 'Task 1', date: '2026-08-25', completed: false, createdAt: now, updatedAt: now),
        TaskModel(id: 't2', title: 'Task 2', date: '2026-08-25', completed: true, createdAt: now, updatedAt: now),
        TaskModel(id: 'sub1', parentId: 't1', title: 'Subtask 1', date: '2026-08-25', completed: false, createdAt: now, updatedAt: now),
        TaskModel(id: 'sub2', parentId: 't1', title: 'Subtask 2', date: '2026-08-25', completed: false, createdAt: now, updatedAt: now),
        TaskModel(id: 'sub3', parentId: 't2', title: 'Subtask 3', date: '2026-08-25', completed: true, createdAt: now, updatedAt: now),
      ];

      final topLevelPending = allTasks.where((t) => !t.completed && t.isTopLevel).toList();
      final topLevelCompleted = allTasks.where((t) => t.completed && t.isTopLevel).toList();

      expect(topLevelPending.length, 1);
      expect(topLevelPending.first.id, 't1');
      expect(topLevelCompleted.length, 1);
      expect(topLevelCompleted.first.id, 't2');
    });
  });

  group('Recurring Tasks and Streak Audit Tests', () {
    test('Daily recurrence matches each consecutive day without spawning DB rows', () {
      final now = DateTime.now();
      final baseDate = DateTime(2026, 8, 1);
      final task = TaskModel(
        id: 'rec_daily',
        title: 'Study DSA',
        date: '2026-08-01',
        repeatRule: RepeatRule.daily,
        repeatInterval: 1,
        repeatEndType: RecurrenceEndType.never,
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isOccurringOnDate(baseDate), isTrue);
      expect(task.isOccurringOnDate(DateTime(2026, 8, 2)), isTrue);
      expect(task.isOccurringOnDate(DateTime(2026, 8, 15)), isTrue);
      expect(task.isOccurringOnDate(DateTime(2026, 7, 31)), isFalse); // Before start date
    });

    test('Weekdays recurrence only matches Monday through Friday', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 'rec_weekdays',
        title: 'Morning Standup',
        date: '2026-08-24', // Monday
        repeatRule: RepeatRule.weekdays,
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isOccurringOnDate(DateTime(2026, 8, 24)), isTrue); // Mon
      expect(task.isOccurringOnDate(DateTime(2026, 8, 25)), isTrue); // Tue
      expect(task.isOccurringOnDate(DateTime(2026, 8, 26)), isTrue); // Wed
      expect(task.isOccurringOnDate(DateTime(2026, 8, 27)), isTrue); // Thu
      expect(task.isOccurringOnDate(DateTime(2026, 8, 28)), isTrue); // Fri
      expect(task.isOccurringOnDate(DateTime(2026, 8, 29)), isFalse); // Sat
      expect(task.isOccurringOnDate(DateTime(2026, 8, 30)), isFalse); // Sun
    });

    test('Weekly recurrence on specific days matches selected weekdays', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 'rec_weekly',
        title: 'Gym Workout',
        date: '2026-08-24', // Monday
        repeatRule: RepeatRule.weekly,
        repeatDaysOfWeek: [1, 3, 5], // Mon, Wed, Fri
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isOccurringOnDate(DateTime(2026, 8, 24)), isTrue); // Mon
      expect(task.isOccurringOnDate(DateTime(2026, 8, 25)), isFalse); // Tue
      expect(task.isOccurringOnDate(DateTime(2026, 8, 26)), isTrue); // Wed
      expect(task.isOccurringOnDate(DateTime(2026, 8, 28)), isTrue); // Fri
      expect(task.isOccurringOnDate(DateTime(2026, 8, 29)), isFalse); // Sat
    });

    test('Monthly recurrence matches on same day of month', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 'rec_monthly',
        title: 'Pay Rent',
        date: '2026-08-01',
        repeatRule: RepeatRule.monthly,
        repeatInterval: 1,
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isOccurringOnDate(DateTime(2026, 8, 1)), isTrue);
      expect(task.isOccurringOnDate(DateTime(2026, 8, 2)), isFalse);
      expect(task.isOccurringOnDate(DateTime(2026, 9, 1)), isTrue);
      expect(task.isOccurringOnDate(DateTime(2026, 10, 1)), isTrue);
    });

    test('Recurrence end condition untilDate stops matching after cutoff', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 'rec_end_date',
        title: '30-Day Coding Challenge',
        date: '2026-08-01',
        repeatRule: RepeatRule.daily,
        repeatEndType: RecurrenceEndType.untilDate,
        repeatEndDate: '2026-08-30',
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isOccurringOnDate(DateTime(2026, 8, 30)), isTrue);
      expect(task.isOccurringOnDate(DateTime(2026, 8, 31)), isFalse);
      expect(task.isOccurringOnDate(DateTime(2026, 9, 1)), isFalse);
    });

    test('Recurrence end condition afterOccurrences stops matching after specified count', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 'rec_end_count',
        title: '5-Day Intensive Course',
        date: '2026-08-01',
        repeatRule: RepeatRule.daily,
        repeatEndType: RecurrenceEndType.afterOccurrences,
        repeatEndCount: 5,
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isOccurringOnDate(DateTime(2026, 8, 1)), isTrue); // 1
      expect(task.isOccurringOnDate(DateTime(2026, 8, 2)), isTrue); // 2
      expect(task.isOccurringOnDate(DateTime(2026, 8, 3)), isTrue); // 3
      expect(task.isOccurringOnDate(DateTime(2026, 8, 4)), isTrue); // 4
      expect(task.isOccurringOnDate(DateTime(2026, 8, 5)), isTrue); // 5
      expect(task.isOccurringOnDate(DateTime(2026, 8, 6)), isFalse); // 6 (exceeded)
    });

    test('Streak calculation increases by exactly 1 day when recurring task is completed', () {
      final now = DateTime.now();
      final today = AppDateUtils.normalizeDate(now);
      final yesterday = today.subtract(const Duration(days: 1));

      final recurringTask = TaskModel(
        id: 'rec_task_1',
        title: 'Daily Practice',
        date: AppDateUtils.toIsoDate(yesterday),
        repeatRule: RepeatRule.daily,
        createdAt: now,
        updatedAt: now,
      );

      final occurrences = [
        TaskOccurrenceModel(
          id: 'rec_task_1_${AppDateUtils.toIsoDate(yesterday)}',
          taskId: 'rec_task_1',
          date: AppDateUtils.toIsoDate(yesterday),
          completed: true,
          completedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        TaskOccurrenceModel(
          id: 'rec_task_1_${AppDateUtils.toIsoDate(today)}',
          taskId: 'rec_task_1',
          date: AppDateUtils.toIsoDate(today),
          completed: true,
          completedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final streak = ProductivityCalculator.calculateStreaks(
        allTasks: [recurringTask],
        occurrences: occurrences,
        thresholdPercentage: 70,
      );

      expect(streak.currentStreak, 2);
      expect(streak.isTodaySuccessful, isTrue);
    });

    test('Missing a required day breaks/resets streak', () {
      final now = DateTime.now();
      final today = AppDateUtils.normalizeDate(now);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final tasks = [
        TaskModel(id: 't1', title: 'Task 1', date: AppDateUtils.toIsoDate(twoDaysAgo), completed: true, createdAt: now, updatedAt: now),
        TaskModel(id: 't2', title: 'Task 2', date: AppDateUtils.toIsoDate(yesterday), completed: false, createdAt: now, updatedAt: now), // Missed!
        TaskModel(id: 't3', title: 'Task 3', date: AppDateUtils.toIsoDate(today), completed: true, createdAt: now, updatedAt: now),
      ];

      final streak = ProductivityCalculator.calculateStreaks(
        allTasks: tasks,
        thresholdPercentage: 70,
      );

      // Yesterday was missed (0%), so current streak on today is only 1!
      expect(streak.currentStreak, 1);
      expect(streak.longestStreak, 1);
    });

    test('Multiple task completions on the same day do not inflate streak', () {
      final now = DateTime.now();
      final today = AppDateUtils.normalizeDate(now);
      final todayIso = AppDateUtils.toIsoDate(today);

      final tasks = [
        TaskModel(id: 't1', title: 'Task 1', date: todayIso, completed: true, createdAt: now, updatedAt: now),
        TaskModel(id: 't2', title: 'Task 2', date: todayIso, completed: true, createdAt: now, updatedAt: now),
        TaskModel(id: 't3', title: 'Task 3', date: todayIso, completed: true, createdAt: now, updatedAt: now),
        TaskModel(id: 't4', title: 'Task 4', date: todayIso, completed: true, createdAt: now, updatedAt: now),
        TaskModel(id: 't5', title: 'Task 5', date: todayIso, completed: true, createdAt: now, updatedAt: now),
      ];

      final streak = ProductivityCalculator.calculateStreaks(
        allTasks: tasks,
        thresholdPercentage: 70,
      );

      // 5 completions on 1 day still equals a 1-day streak
      expect(streak.currentStreak, 1);
      expect(streak.totalSuccessfulDays, 1);
      expect(streak.isTodaySuccessful, isTrue);
    });
  });
}
