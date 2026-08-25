import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDateFormat = DateFormat('EEEE, MMMM d');
  static final DateFormat _shortDateFormat = DateFormat('MMM d');
  static final DateFormat _timeFormat12 = DateFormat('h:mm a');

  static String toIsoDate(DateTime date) => _isoDateFormat.format(date);

  static DateTime parseIsoDate(String isoDate) => _isoDateFormat.parse(isoDate);

  static String formatDisplayDate(DateTime date) => _displayDateFormat.format(date);

  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);

  static String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return _timeFormat12.format(dt);
  }

  static TimeOfDay? parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}
    return null;
  }

  static String formatTimeStringTo12Hour(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    final tod = parseTimeString(timeStr);
    if (tod == null) return timeStr;
    return formatTimeOfDay(tod);
  }

  static String timeOfDayToString(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  static String relativeDateLabel(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    if (isYesterday(date)) return 'Yesterday';
    return formatShortDate(date);
  }

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static List<DateTime> getDaysInWeek(DateTime weekDate) {
    final normalized = normalizeDate(weekDate);
    // Find Monday (weekday 1)
    final monday = normalized.subtract(Duration(days: normalized.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }
}