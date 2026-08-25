import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class AnnualHeatmapCard extends ConsumerStatefulWidget {
  final List<TaskModel> tasks;

  const AnnualHeatmapCard({super.key, required this.tasks});

  @override
  ConsumerState<AnnualHeatmapCard> createState() => _AnnualHeatmapCardState();
}

class _AnnualHeatmapCardState extends ConsumerState<AnnualHeatmapCard> {
  late int _selectedYear;
  final ScrollController _scrollController = ScrollController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _selectedDate = AppDateUtils.normalizeDate(DateTime.now());

    // Auto-scroll to current week
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final now = DateTime.now();
        final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
        final currentWeek = (dayOfYear / 7).floor();
        final targetOffset = (currentWeek * 16.0) - 60.0;
        if (targetOffset > 0) {
          _scrollController.animateTo(
            targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tasksNotifier = ref.watch(tasksNotifierProvider.notifier);

    // Start from the Sunday on or before Jan 1 of selected year
    final jan1 = DateTime(_selectedYear, 1, 1);
    final startDate = jan1.subtract(Duration(days: jan1.weekday % 7));
    const totalWeeks = 53;

    // Cache completed tasks count per date
    final Map<String, int> completedPerDate = {};
    int totalYearCompleted = 0;

    for (int w = 0; w < totalWeeks; w++) {
      for (int d = 0; d < 7; d++) {
        final cellDate = startDate.add(Duration(days: (w * 7) + d));
        if (cellDate.year == _selectedYear) {
          final cellTasks = tasksNotifier.getTasksForDate(cellDate);
          final cCount = cellTasks.where((t) => t.completed).length;
          if (cCount > 0) {
            final iso = AppDateUtils.toIsoDate(cellDate);
            completedPerDate[iso] = cCount;
            totalYearCompleted += cCount;
          }
        }
      }
    }

    // Selected cell info
    final selectedIso = _selectedDate != null ? AppDateUtils.toIsoDate(_selectedDate!) : null;
    final selectedCount = selectedIso != null ? (completedPerDate[selectedIso] ?? 0) : 0;
    final selectedFormatted = _selectedDate != null
        ? DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Annual Heatmap & Year Dropdown
            Row(
              children: [
                Text(
                  'Annual Heatmap',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B86E5).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalYearCompleted done',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B86E5),
                    ),
                  ),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: _selectedYear,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                  items: [2024, 2025, 2026, 2027].map((y) {
                    return DropdownMenuItem(
                      value: y,
                      child: Text(
                        '$y',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedYear = val;
                        _selectedDate = DateTime(val, 1, 1);
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Heatmap Grid Area
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heatmap 7-row matrix
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weekday Labels
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
                            return SizedBox(
                              height: 14,
                              child: Text(
                                d,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // 53 Weeks Grid
                      Row(
                        children: List.generate(totalWeeks, (weekIndex) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Column(
                              children: List.generate(7, (dayIndex) {
                                final cellDate = startDate.add(Duration(days: (weekIndex * 7) + dayIndex));
                                final isCurrentYear = cellDate.year == _selectedYear;
                                final dateIso = AppDateUtils.toIsoDate(cellDate);
                                final count = completedPerDate[dateIso] ?? 0;
                                final isSelected = _selectedDate != null &&
                                    AppDateUtils.toIsoDate(_selectedDate!) == dateIso;

                                Color cellColor;
                                if (!isCurrentYear) {
                                  cellColor = Colors.transparent;
                                } else if (count == 0) {
                                  cellColor = isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9);
                                } else if (count == 1) {
                                  cellColor = const Color(0xFF93C5FD);
                                } else if (count == 2) {
                                  cellColor = const Color(0xFF60A5FA);
                                } else {
                                  cellColor = const Color(0xFF2563EB);
                                }

                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (isCurrentYear) {
                                        setState(() => _selectedDate = cellDate);
                                      }
                                    },
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(bottom: 2),
                                      decoration: BoxDecoration(
                                        color: cellColor,
                                        borderRadius: BorderRadius.circular(3),
                                        border: isSelected
                                            ? Border.all(
                                                color: isDark ? Colors.white : Colors.black,
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Month labels below aligned with week indices
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Row(
                      children: List.generate(12, (monthIndex) {
                        final monthDate = DateTime(_selectedYear, monthIndex + 1, 1);
                        final monthLabel = DateFormat('MMM').format(monthDate);
                        return Container(
                          width: 60,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            monthLabel,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Interactive Day Inspector & Legend
            Row(
              children: [
                if (selectedFormatted != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedCount > 0 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 13,
                            color: selectedCount > 0 ? const Color(0xFF5B86E5) : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$selectedFormatted: $selectedCount completed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),

                // Less / More Color Legend
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Less', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    const SizedBox(width: 4),
                    _LegendBox(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    const SizedBox(width: 2),
                    const _LegendBox(color: Color(0xFF93C5FD)),
                    const SizedBox(width: 2),
                    const _LegendBox(color: Color(0xFF60A5FA)),
                    const SizedBox(width: 2),
                    const _LegendBox(color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    const Text('More', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendBox extends StatelessWidget {
  final Color color;

  const _LegendBox({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
