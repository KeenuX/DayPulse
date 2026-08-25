import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class CompletedTasksDonutCard extends ConsumerStatefulWidget {
  final List<TaskModel> allTasks;

  const CompletedTasksDonutCard({
    super.key,
    required this.allTasks,
  });

  @override
  ConsumerState<CompletedTasksDonutCard> createState() => _CompletedTasksDonutCardState();
}

class _CompletedTasksDonutCardState extends ConsumerState<CompletedTasksDonutCard> {
  String _selectedRange = 'In 30 days';
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = ref.watch(categoriesNotifierProvider).value ?? [];
    final tasksNotifier = ref.watch(tasksNotifierProvider.notifier);
    final occurrences = tasksNotifier.occurrences;

    final now = DateTime.now();
    DateTime cutoffDate;
    if (_selectedRange == 'In 7 days') {
      cutoffDate = now.subtract(const Duration(days: 7));
    } else if (_selectedRange == 'In 30 days') {
      cutoffDate = now.subtract(const Duration(days: 30));
    } else if (_selectedRange == 'In 90 days') {
      cutoffDate = now.subtract(const Duration(days: 90));
    } else {
      cutoffDate = DateTime(2000);
    }

    final cutoffIso = AppDateUtils.toIsoDate(cutoffDate);

    final List<TaskModel> filteredCompletedTasks = [];

    // 1. Regular non-recurring completed tasks
    for (final t in widget.allTasks) {
      if (t.isTopLevel && !t.isRecurring && t.completed) {
        if (_selectedRange == 'All time' || t.date.compareTo(cutoffIso) >= 0) {
          filteredCompletedTasks.add(t);
        }
      }
    }

    // 2. Completed occurrences for recurring tasks
    final recurringTaskMap = {
      for (final t in widget.allTasks.where((t) => t.isTopLevel && t.isRecurring)) t.id: t
    };

    for (final occ in occurrences) {
      if (occ.completed && !occ.isSkipped) {
        if (_selectedRange == 'All time' || occ.date.compareTo(cutoffIso) >= 0) {
          final parent = recurringTaskMap[occ.taskId];
          if (parent != null) {
            filteredCompletedTasks.add(parent.copyWith(
              date: occ.date,
              completed: true,
              completedAt: occ.completedAt,
            ));
          }
        }
      }
    }

    final totalCompletedCount = filteredCompletedTasks.length;

    // Group by category (including General / uncategorized)
    final Map<String, int> catCounts = {};
    for (final t in filteredCompletedTasks) {
      final cId = t.categoryId ?? '__general__';
      catCounts[cId] = (catCounts[cId] ?? 0) + 1;
    }

    final List<_CategorySlice> slices = [];
    catCounts.forEach((catId, count) {
      if (catId == '__general__') {
        slices.add(_CategorySlice(
          categoryId: '__general__',
          categoryName: 'General',
          color: const Color(0xFF64748B),
          count: count,
          percentage: totalCompletedCount > 0 ? (count / totalCompletedCount) * 100.0 : 0.0,
        ));
      } else {
        final cat = categories.where((c) => c.id == catId).firstOrNull;
        slices.add(_CategorySlice(
          categoryId: catId,
          categoryName: cat?.name ?? 'Category',
          color: cat?.color ?? const Color(0xFF5B86E5),
          count: count,
          percentage: totalCompletedCount > 0 ? (count / totalCompletedCount) * 100.0 : 0.0,
        ));
      }
    });

    // Sort descending by count
    slices.sort((a, b) => b.count.compareTo(a.count));

    final hasData = slices.isNotEmpty && totalCompletedCount > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Completed Tasks & Range Dropdown
            Row(
              children: [
                Text(
                  'Completed Tasks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalCompletedCount total',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedRange,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                  items: ['In 7 days', 'In 30 days', 'In 90 days', 'All time'].map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRange = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content: Donut Chart on left + Category list on right
            Row(
              children: [
                // Donut Ring Chart
                SizedBox(
                  width: 104,
                  height: 104,
                  child: hasData
                      ? PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            sectionsSpace: 2,
                            centerSpaceRadius: 28,
                            sections: slices.asMap().entries.map((entry) {
                              final index = entry.key;
                              final slice = entry.value;
                              final isTouched = index == _touchedIndex;
                              final radius = isTouched ? 22.0 : 18.0;

                              return PieChartSectionData(
                                color: slice.color,
                                value: slice.count.toDouble(),
                                title: isTouched ? '${slice.percentage.toStringAsFixed(0)}%' : '',
                                radius: radius,
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              width: 14,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.pie_chart_outline_rounded,
                              size: 24,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 20),

                // Right column: Breakdown list with General & Categories
                Expanded(
                  child: hasData
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: slices.take(5).map((slice) {
                            final pctStr = '${slice.percentage.toStringAsFixed(0)}%';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: slice.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      slice.categoryName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${slice.count} ($pctStr)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No completed tasks',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complete tasks to see category distribution here.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySlice {
  final String categoryId;
  final String categoryName;
  final Color color;
  final int count;
  final double percentage;

  _CategorySlice({
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.count,
    required this.percentage,
  });
}
