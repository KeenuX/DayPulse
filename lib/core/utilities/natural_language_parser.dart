import 'package:flutter/material.dart';
import 'package:daypulse/features/tasks/models/task_priority.dart';
import 'package:daypulse/core/utilities/date_utils.dart';

class ParsedTaskInput {
  final String title;
  final DateTime date;
  final TimeOfDay? startTime;
  final int? durationMinutes;
  final TaskPriority priority;

  ParsedTaskInput({
    required this.title,
    required this.date,
    this.startTime,
    this.durationMinutes,
    this.priority = TaskPriority.medium,
  });
}

class NaturalLanguageParser {
  static ParsedTaskInput parse(String rawText) {
    String text = rawText.trim();
    if (text.isEmpty) {
      return ParsedTaskInput(
        title: '',
        date: AppDateUtils.normalizeDate(DateTime.now()),
      );
    }

    DateTime targetDate = AppDateUtils.normalizeDate(DateTime.now());
    TimeOfDay? targetTime;
    int? duration;
    TaskPriority priority = TaskPriority.medium;

    // 1. Detect Priority
    final pHighRegex = RegExp(r'(!high|p1|\bpriority\s*high\b|\bhigh\s*priority\b)', caseSensitive: false);
    final pMedRegex = RegExp(r'(!med|!medium|p2|\bpriority\s*med\b|\bmedium\s*priority\b)', caseSensitive: false);
    final pLowRegex = RegExp(r'(!low|p3|\bpriority\s*low\b|\blow\s*priority\b)', caseSensitive: false);

    if (pHighRegex.hasMatch(text)) {
      priority = TaskPriority.high;
      text = text.replaceAll(pHighRegex, '');
    } else if (pMedRegex.hasMatch(text)) {
      priority = TaskPriority.medium;
      text = text.replaceAll(pMedRegex, '');
    } else if (pLowRegex.hasMatch(text)) {
      priority = TaskPriority.low;
      text = text.replaceAll(pLowRegex, '');
    }

    // 2. Detect Date (today, tomorrow, tonight)
    final tomorrowRegex = RegExp(r'\b(tomorrow)\b', caseSensitive: false);
    final tonightRegex = RegExp(r'\b(tonight)\b', caseSensitive: false);
    final todayRegex = RegExp(r'\b(today)\b', caseSensitive: false);

    if (tomorrowRegex.hasMatch(text)) {
      targetDate = AppDateUtils.normalizeDate(DateTime.now().add(const Duration(days: 1)));
      text = text.replaceAll(tomorrowRegex, '');
    } else if (tonightRegex.hasMatch(text)) {
      targetDate = AppDateUtils.normalizeDate(DateTime.now());
      targetTime = const TimeOfDay(hour: 20, minute: 0); // 8:00 PM default for tonight
      text = text.replaceAll(tonightRegex, '');
    } else if (todayRegex.hasMatch(text)) {
      targetDate = AppDateUtils.normalizeDate(DateTime.now());
      text = text.replaceAll(todayRegex, '');
    }

    // 3. Detect Duration (e.g. "for 30m", "for 1h", "for 45 mins", "for 2 hours")
    final durationRegex = RegExp(r'\bfor\s+(\d+)\s*(m|min|mins|minutes|h|hr|hrs|hours)\b', caseSensitive: false);
    final durMatch = durationRegex.firstMatch(text);
    if (durMatch != null) {
      final value = int.tryParse(durMatch.group(1) ?? '0') ?? 0;
      final unit = durMatch.group(2)?.toLowerCase() ?? 'm';
      if (unit.startsWith('h')) {
        duration = value * 60;
      } else {
        duration = value;
      }
      text = text.replaceRange(durMatch.start, durMatch.end, '');
    }

    // 4. Detect Time (e.g. "at 7:30 pm", "at 7pm", "at 14:00", "7:00 PM", "6am", "at 9")
    final time12Regex = RegExp(r'(?:\bat\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b', caseSensitive: false);
    final time24Regex = RegExp(r'\bat\s+(\d{1,2}):(\d{2})\b', caseSensitive: false);

    final time12Match = time12Regex.firstMatch(text);
    if (time12Match != null) {
      int hour = int.parse(time12Match.group(1)!);
      final int minute = int.tryParse(time12Match.group(2) ?? '0') ?? 0;
      final String period = time12Match.group(3)!.toLowerCase();

      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        targetTime = TimeOfDay(hour: hour, minute: minute);
        text = text.replaceRange(time12Match.start, time12Match.end, '');
      }
    } else {
      final time24Match = time24Regex.firstMatch(text);
      if (time24Match != null) {
        final int hour = int.parse(time24Match.group(1)!);
        final int minute = int.parse(time24Match.group(2)!);
        if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          targetTime = TimeOfDay(hour: hour, minute: minute);
          text = text.replaceRange(time24Match.start, time24Match.end, '');
        }
      }
    }

    // Clean up whitespace & extraneous "at" or punctuation
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    text = text.replaceAll(RegExp(r'\s+at$'), '').trim();

    return ParsedTaskInput(
      title: text.isNotEmpty ? text : rawText.trim(),
      date: targetDate,
      startTime: targetTime,
      durationMinutes: duration,
      priority: priority,
    );
  }
}