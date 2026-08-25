import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';
import 'package:daypulse/features/progress/models/productivity_metrics.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class DailyCompletedCard extends ConsumerStatefulWidget {
  final List<DailyMetric> weeklyMetrics;
  final String mostProductiveDay;
  final List<TaskModel> allTasks;

  const DailyCompletedCard({
    super.key,
    required this.weeklyMetrics,
    required this.mostProductiveDay,
    required this.allTasks,
  });

  @override
  ConsumerState<DailyCompletedCard> createState() => _DailyCompletedCardState();
}

class _DailyCompletedCardState extends ConsumerState<DailyCompletedCard> {
  int _weekOffset = 0;
  int? _hoveredOrSelectedDayIndex;

  @override
  void initState() {
    super.initState();
    // Default selected day to today (0=Sun, 1=Mon, ..., 6=Sat)
    _hoveredOrSelectedDayIndex = DateTime.now().weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = ref.watch(categoriesNotifierProvider).value ?? [];

    final now = DateTime.now().add(Duration(days: _weekOffset * 7));
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final dateRangeLabel = '${startOfWeek.day}/${startOfWeek.month} - ${endOfWeek.day}/${endOfWeek.month}';

    // 7 Days for this week
    final weekDays = List.generate(7, (i) => AppDateUtils.normalizeDate(startOfWeek.add(Duration(days: i))));

    // Compute metrics and category breakdown for each day of the week
    final List<_DayStats> dayStatsList = [];
    int totalWeekCompleted = 0;
    int totalWeekPlanned = 0;

    final tasksNotifier = ref.watch(tasksNotifierProvider.notifier);
    for (int i = 0; i < 7; i++) {
      final dayDate = weekDays[i];
      final dayTasks = tasksNotifier.getTasksForDate(dayDate);
      final dayCompletedTasks = dayTasks.where((t) => t.completed).toList();

      totalWeekCompleted += dayCompletedTasks.length;
      totalWeekPlanned += dayTasks.length;

      // Group completed tasks by category
      final Map<String, int> catCount = {};
      for (final t in dayCompletedTasks) {
        final cId = t.categoryId ?? '__none__';
        catCount[cId] = (catCount[cId] ?? 0) + 1;
      }

      final List<_CategoryPercent> catBreakdown = [];
      final totalCompletedCount = dayCompletedTasks.length;

      catCount.forEach((catId, count) {
        final cat = categories.where((c) => c.id == catId).firstOrNull;
        final name = cat?.name ?? (catId == '__none__' ? 'General' : 'Category');
        final color = cat?.color ?? Colors.blueGrey;
        final pct = totalCompletedCount > 0 ? (count / totalCompletedCount) * 100.0 : 0.0;

        catBreakdown.add(_CategoryPercent(
          categoryName: name,
          color: color,
          count: count,
          percentage: pct,
        ));
      });

      // Sort descending by count
      catBreakdown.sort((a, b) => b.count.compareTo(a.count));

      dayStatsList.add(_DayStats(
        date: dayDate,
        dayName: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][i],
        plannedCount: dayTasks.length,
        completedCount: dayCompletedTasks.length,
        categories: catBreakdown,
      ));
    }

    final hasData = totalWeekCompleted > 0;
    final rateStr = totalWeekPlanned > 0 ? '${((totalWeekCompleted / totalWeekPlanned) * 100).round()}%' : '--';

    final selectedDayStats = (_hoveredOrSelectedDayIndex != null &&
            _hoveredOrSelectedDayIndex! >= 0 &&
            _hoveredOrSelectedDayIndex! < dayStatsList.length)
        ? dayStatsList[_hoveredOrSelectedDayIndex!]
        : dayStatsList[DateTime.now().weekday % 7];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Daily Completed & Week Pager
            Row(
              children: [
                Text(
                  'Daily Completed',
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
                      onPressed: () => setState(() {
                        _weekOffset--;
                      }),
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
                      onPressed: () => setState(() {
                        _weekOffset++;
                      }),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              hasData ? '$totalWeekCompleted tasks completed this week' : 'Tap any day to see category percentage breakdown.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),

            // Chart area with 7 interactive vertical day bars
            SizedBox(
              height: 130,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dayStatsList.asMap().entries.map((entry) {
                  final dayIndex = entry.key;
                  final dayStats = entry.value;
                  final count = dayStats.completedCount;
                  final isSelected = _hoveredOrSelectedDayIndex == dayIndex;
                  final heightRatio = (count / 8.0).clamp(0.12, 1.0);

                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _hoveredOrSelectedDayIndex = dayIndex),
                    child: GestureDetector(
                      onTap: () => setState(() => _hoveredOrSelectedDayIndex = dayIndex),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (count > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF5B86E5) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          Container(
                            width: 18,
                            height: 80 * heightRatio,
                            decoration: BoxDecoration(
                              color: count > 0
                                  ? (isSelected ? const Color(0xFF3858D6) : const Color(0xFF5B86E5))
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF0FF)),
                              borderRadius: BorderRadius.circular(5),
                              border: isSelected
                                  ? Border.all(
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dayStats.dayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF1E293B))
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Interactive Category Breakdown Inspector (Hover / Tap info)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        size: 15,
                        color: selectedDayStats.completedCount > 0 ? const Color(0xFF5B86E5) : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${DateFormat('EEEE, MMM d').format(selectedDayStats.date)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${selectedDayStats.completedCount} completed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selectedDayStats.completedCount > 0 ? const Color(0xFF5B86E5) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (selectedDayStats.categories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'No completed tasks recorded on this day.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                      ),
                    )
                  else ...[
                    // Proportional Multi-color Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: selectedDayStats.categories.map((c) {
                            return Expanded(
                              flex: (c.percentage * 10).round().clamp(1, 1000),
                              child: Container(color: c.color),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Category chips with percentages
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: selectedDayStats.categories.map((cat) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: cat.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              cat.categoryName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cat.percentage.toStringAsFixed(0)}% (${cat.count})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cat.color,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Bottom Metrics: Tasks Completion Rate & Most Productive Day
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tasks Completion Rate',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                Text(
                  rateStr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Most Productive Day',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                Text(
                  hasData ? widget.mostProductiveDay : '--',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayStats {
  final DateTime date;
  final String dayName;
  final int plannedCount;
  final int completedCount;
  final List<_CategoryPercent> categories;

  _DayStats({
    required this.date,
    required this.dayName,
    required this.plannedCount,
    required this.completedCount,
    required this.categories,
  });
}

class _CategoryPercent {
  final String categoryName;
  final Color color;
  final int count;
  final double percentage;

  _CategoryPercent({
    required this.categoryName,
    required this.color,
    required this.count,
    required this.percentage,
  });
}
