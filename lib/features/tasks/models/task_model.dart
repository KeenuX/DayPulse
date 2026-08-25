import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/tasks/models/repeat_rule.dart';
import 'package:daypulse/features/tasks/models/task_priority.dart';

class TaskModel {
  final String id;
  final String? parentId; // null = top-level task; not-null = subtask
  final String title;
  final String? description;
  final String? categoryId;
  final String date; // YYYY-MM-DD (Start date)
  final String? startTime; // HH:mm
  final String? endTime; // HH:mm
  final int? durationMinutes;
  final TaskPriority priority;
  final bool completed;
  final DateTime? completedAt;
  final bool reminderEnabled;
  final String? reminderTime;
  final RepeatRule repeatRule;
  final RecurrenceEndType repeatEndType;
  final String? repeatEndDate; // YYYY-MM-DD
  final int? repeatEndCount; // Number of occurrences
  final int repeatInterval; // Every N days/weeks/months (default 1)
  final List<int>? repeatDaysOfWeek; // 1=Mon ... 7=Sun
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  const TaskModel({
    required this.id,
    this.parentId,
    required this.title,
    this.description,
    this.categoryId,
    required this.date,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.priority = TaskPriority.medium,
    this.completed = false,
    this.completedAt,
    this.reminderEnabled = false,
    this.reminderTime,
    this.repeatRule = RepeatRule.none,
    this.repeatEndType = RecurrenceEndType.never,
    this.repeatEndDate,
    this.repeatEndCount,
    this.repeatInterval = 1,
    this.repeatDaysOfWeek,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  bool get isTopLevel => parentId == null;
  bool get isSubtask => parentId != null;
  bool get isRecurring => repeatRule.isRecurring;

  DateTime get scheduledDate => AppDateUtils.parseIsoDate(date);

  DateTime? get scheduledDateTime {
    if (startTime == null) return null;
    final time = AppDateUtils.parseTimeString(startTime);
    if (time == null) return null;
    final d = scheduledDate;
    return DateTime(d.year, d.month, d.day, time.hour, time.minute);
  }

  bool get isOverdue {
    if (completed) return false;
    final now = DateTime.now();
    final todayNormalized = AppDateUtils.normalizeDate(now);
    final taskDateNormalized = scheduledDate;

    if (taskDateNormalized.isBefore(todayNormalized)) {
      return true;
    }

    if (taskDateNormalized.isAtSameMomentAs(todayNormalized) && startTime != null) {
      final sdt = scheduledDateTime;
      if (sdt != null && sdt.isBefore(now)) {
        return true;
      }
    }
    return false;
  }

  TimeOfDay? get startTimeOfDay => AppDateUtils.parseTimeString(startTime);
  TimeOfDay? get endTimeOfDay => AppDateUtils.parseTimeString(endTime);

  /// Checks whether this task recurs on a given target date
  bool isOccurringOnDate(DateTime targetDate) {
    final targetNorm = AppDateUtils.normalizeDate(targetDate);
    final startNorm = AppDateUtils.normalizeDate(scheduledDate);

    if (repeatRule == RepeatRule.none) {
      return targetNorm.isAtSameMomentAs(startNorm);
    }

    if (targetNorm.isBefore(startNorm)) {
      return false;
    }

    // Check End Conditions
    if (repeatEndType == RecurrenceEndType.untilDate && repeatEndDate != null) {
      final endNorm = AppDateUtils.normalizeDate(AppDateUtils.parseIsoDate(repeatEndDate!));
      if (targetNorm.isAfter(endNorm)) return false;
    }

    final interval = repeatInterval > 0 ? repeatInterval : 1;

    switch (repeatRule) {
      case RepeatRule.daily:
        final daysDiff = targetNorm.difference(startNorm).inDays;
        if (daysDiff % interval != 0) return false;
        if (repeatEndType == RecurrenceEndType.afterOccurrences && repeatEndCount != null) {
          final occIndex = daysDiff ~/ interval;
          if (occIndex >= repeatEndCount!) return false;
        }
        return true;

      case RepeatRule.weekdays:
        if (targetNorm.weekday > 5) return false;
        if (repeatEndType == RecurrenceEndType.afterOccurrences && repeatEndCount != null) {
          final occIndex = _countWeekdaysBetween(startNorm, targetNorm);
          if (occIndex >= repeatEndCount!) return false;
        }
        return true;

      case RepeatRule.weekly:
        if (repeatDaysOfWeek != null && repeatDaysOfWeek!.isNotEmpty) {
          if (!repeatDaysOfWeek!.contains(targetNorm.weekday)) return false;
          final weeksDiff = (targetNorm.difference(startNorm).inDays / 7).floor();
          if (weeksDiff % interval != 0) return false;
          if (repeatEndType == RecurrenceEndType.afterOccurrences && repeatEndCount != null) {
            final occIndex = _countWeeklyOccurrences(startNorm, targetNorm, repeatDaysOfWeek!, interval);
            if (occIndex >= repeatEndCount!) return false;
          }
          return true;
        } else {
          final daysDiff = targetNorm.difference(startNorm).inDays;
          if (daysDiff % (7 * interval) != 0) return false;
          if (repeatEndType == RecurrenceEndType.afterOccurrences && repeatEndCount != null) {
            final occIndex = daysDiff ~/ (7 * interval);
            if (occIndex >= repeatEndCount!) return false;
          }
          return true;
        }

      case RepeatRule.monthly:
        if (targetNorm.day != startNorm.day) return false;
        final monthsDiff = (targetNorm.year - startNorm.year) * 12 + (targetNorm.month - startNorm.month);
        if (monthsDiff < 0 || monthsDiff % interval != 0) return false;
        if (repeatEndType == RecurrenceEndType.afterOccurrences && repeatEndCount != null) {
          final occIndex = monthsDiff ~/ interval;
          if (occIndex >= repeatEndCount!) return false;
        }
        return true;

      case RepeatRule.custom:
        final daysDiff = targetNorm.difference(startNorm).inDays;
        if (daysDiff % interval != 0) return false;
        if (repeatEndType == RecurrenceEndType.afterOccurrences && repeatEndCount != null) {
          final occIndex = daysDiff ~/ interval;
          if (occIndex >= repeatEndCount!) return false;
        }
        return true;

      case RepeatRule.none:
        return targetNorm.isAtSameMomentAs(startNorm);
    }
  }

  static int _countWeekdaysBetween(DateTime start, DateTime end) {
    int count = 0;
    DateTime cur = start;
    while (!cur.isAfter(end)) {
      if (cur.weekday <= 5) count++;
      cur = cur.add(const Duration(days: 1));
    }
    return count - 1; // 0-indexed
  }

  static int _countWeeklyOccurrences(DateTime start, DateTime end, List<int> days, int interval) {
    int count = 0;
    DateTime cur = start;
    while (!cur.isAfter(end)) {
      if (days.contains(cur.weekday)) {
        final weeksDiff = (cur.difference(start).inDays / 7).floor();
        if (weeksDiff % interval == 0) count++;
      }
      cur = cur.add(const Duration(days: 1));
    }
    return count - 1;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'priority': priority.value,
      'completed': completed ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_time': reminderTime,
      'repeat_rule': repeatRule.value,
      'repeat_end_type': repeatEndType.value,
      'repeat_end_date': repeatEndDate,
      'repeat_end_count': repeatEndCount,
      'repeat_interval': repeatInterval,
      'repeat_days_of_week': repeatDaysOfWeek != null ? jsonEncode(repeatDaysOfWeek) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    List<int>? parsedDays;
    if (map['repeat_days_of_week'] != null) {
      try {
        final dynamic decoded = jsonDecode(map['repeat_days_of_week'] as String);
        if (decoded is List) {
          parsedDays = decoded.map((e) => e as int).toList();
        }
      } catch (_) {}
    }

    return TaskModel(
      id: map['id'] as String,
      parentId: map['parent_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      categoryId: map['category_id'] as String?,
      date: map['date'] as String,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      durationMinutes: map['duration_minutes'] as int?,
      priority: TaskPriority.fromString(map['priority'] as String?),
      completed: (map['completed'] as int) == 1,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      reminderEnabled: (map['reminder_enabled'] as int) == 1,
      reminderTime: map['reminder_time'] as String?,
      repeatRule: RepeatRule.fromString(map['repeat_rule'] as String?),
      repeatEndType: RecurrenceEndType.fromString(map['repeat_end_type'] as String?),
      repeatEndDate: map['repeat_end_date'] as String?,
      repeatEndCount: map['repeat_end_count'] as int?,
      repeatInterval: (map['repeat_interval'] as int?) ?? 1,
      repeatDaysOfWeek: parsedDays,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      notes: map['notes'] as String?,
    );
  }

  TaskModel copyWith({
    String? id,
    String? parentId,
    bool clearParentId = false,
    String? title,
    String? description,
    String? categoryId,
    bool clearCategoryId = false,
    String? date,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    TaskPriority? priority,
    bool? completed,
    DateTime? completedAt,
    bool? reminderEnabled,
    String? reminderTime,
    RepeatRule? repeatRule,
    RecurrenceEndType? repeatEndType,
    String? repeatEndDate,
    bool clearRepeatEndDate = false,
    int? repeatEndCount,
    bool clearRepeatEndCount = false,
    int? repeatInterval,
    List<int>? repeatDaysOfWeek,
    bool clearRepeatDaysOfWeek = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return TaskModel(
      id: id ?? this.id,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      repeatRule: repeatRule ?? this.repeatRule,
      repeatEndType: repeatEndType ?? this.repeatEndType,
      repeatEndDate: clearRepeatEndDate ? null : (repeatEndDate ?? this.repeatEndDate),
      repeatEndCount: clearRepeatEndCount ? null : (repeatEndCount ?? this.repeatEndCount),
      repeatInterval: repeatInterval ?? this.repeatInterval,
      repeatDaysOfWeek: clearRepeatDaysOfWeek ? null : (repeatDaysOfWeek ?? this.repeatDaysOfWeek),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }
}