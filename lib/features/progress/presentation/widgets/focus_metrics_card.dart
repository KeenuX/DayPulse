import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/core/utilities/duration_formatter.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class FocusMetricsCard extends ConsumerStatefulWidget {
  final int totalFocusMinutes;

  const FocusMetricsCard({super.key, required this.totalFocusMinutes});

  @override
  ConsumerState<FocusMetricsCard> createState() => _FocusMetricsCardState();
}

class _FocusMetricsCardState extends ConsumerState<FocusMetricsCard> {
  int _weekOffset = 0;
  int? _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = DateTime.now().weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tasksNotifier = ref.watch(tasksNotifierProvider.notifier);

    final now = DateTime.now().add(Duration(days: _weekOffset * 7));
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final dateRangeLabel = '${startOfWeek.day}/${startOfWeek.month} - ${endOfWeek.day}/${endOfWeek.month}';

    // 7 Weekdays
    final weekDays = List.generate(7, (i) => AppDateUtils.normalizeDate(startOfWeek.add(Duration(days: i))));

    // Calculate completed focus minutes for each day of the week
    final List<_FocusDayData> dailyFocus = [];
    int weekTotalMinutes = 0;

    for (int i = 0; i < 7; i++) {
      final d = weekDays[i];
      final dayTasks = tasksNotifier.getTasksForDate(d);
      final completedTasks = dayTasks.where((t) => t.completed).toList();

      int dayMins = 0;
      for (final t in completedTasks) {
        dayMins += (t.durationMinutes ?? 30);
      }

      weekTotalMinutes += dayMins;
      dailyFocus.add(_FocusDayData(
        date: d,
        dayName: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][i],
        focusMinutes: dayMins,
        completedCount: completedTasks.length,
      ));
    }

    final hasFocusData = weekTotalMinutes > 0;
    const maxChartHours = 12.0;

    final selectedDay = (_selectedDayIndex != null && _selectedDayIndex! >= 0 && _selectedDayIndex! < dailyFocus.length)
        ? dailyFocus[_selectedDayIndex!]
        : dailyFocus[DateTime.now().weekday % 7];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Focus & Week Navigation Pager
            Row(
              children: [
                Text(
                  'Focus',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _weekOffset--),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateRangeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _weekOffset++),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Subtitle: Total focus time this week
            Text(
              'Total focus time this week  ${DurationFormatter.formatMinutes(weekTotalMinutes)}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),

            // Chart area with grid lines (12h, 9h, 6h, 3h, 0h) and vertical bars
            SizedBox(
              height: 130,
              child: Stack(
                children: [
                  // Horizontal Grid Lines
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [12, 9, 6, 3, 0].map((val) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${val}h',
                              style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),

                  // 7 Interactive Vertical Bars
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: dailyFocus.asMap().entries.map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        final hours = day.focusMinutes / 60.0;
                        final heightRatio = (hours / maxChartHours).clamp(day.focusMinutes > 0 ? 0.12 : 0.0, 1.0);
                        final isSelected = _selectedDayIndex == index;

                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => setState(() => _selectedDayIndex = index),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedDayIndex = index),
                            child: Container(
                              width: 24,
                              height: double.infinity,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 14,
                                height: 110 * heightRatio,
                                decoration: BoxDecoration(
                                  gradient: day.focusMinutes > 0
                                      ? LinearGradient(
                                          colors: isSelected
                                              ? [const Color(0xFF3858D6), const Color(0xFF2563EB)]
                                              : [const Color(0xFF6B93F6), const Color(0xFF4F75FF)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : null,
                                  color: day.focusMinutes > 0
                                      ? null
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF0FF)),
                                  borderRadius: BorderRadius.circular(4),
                                  border: isSelected
                                      ? Border.all(
                                          color: isDark ? Colors.white : Colors.black87,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Empty Pill Overlay if 0 minutes in entire week
                  if (!hasFocusData)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B93F6).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B93F6).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'No Focus Data This Week',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Weekday labels below
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: dailyFocus.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;
                  final isSelected = _selectedDayIndex == index;
                  return Text(
                    day.dayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF1E293B))
                          : const Color(0xFF94A3B8),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Focus Inspector Card for Selected Day
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 15, color: Color(0xFF4F75FF)),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEE, MMM d').format(selectedDay.date),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${DurationFormatter.formatMinutes(selectedDay.focusMinutes)} (${selectedDay.completedCount} done)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F75FF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusDayData {
  final DateTime date;
  final String dayName;
  final int focusMinutes;
  final int completedCount;

  _FocusDayData({
    required this.date,
    required this.dayName,
    required this.focusMinutes,
    required this.completedCount,
  });
}
