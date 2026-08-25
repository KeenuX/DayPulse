import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/presentation/widgets/quick_add_sheet.dart';
import 'package:daypulse/features/tasks/presentation/widgets/task_card.dart';

class DayTimelineView extends ConsumerWidget {
  final DateTime selectedDate;
  final List<TaskModel> tasks;

  const DayTimelineView({
    super.key,
    required this.selectedDate,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build timeline hours (6 AM to 11 PM)
    final hours = List.generate(18, (index) => 6 + index);

    // Group tasks by start hour
    final Map<int, List<TaskModel>> tasksByHour = {};
    final List<TaskModel> unscheduled = [];

    for (final task in tasks) {
      final tod = task.startTimeOfDay;
      if (tod != null) {
        tasksByHour.putIfAbsent(tod.hour, () => []).add(task);
      } else {
        unscheduled.add(task);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Unscheduled Section if any
        if (unscheduled.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    const Text(
                      'Anytime / Unscheduled',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...unscheduled.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskCard(task: t),
                    )),
              ],
            ),
          ),
        ],

        // Hourly Timeline
        ...hours.map((hour) {
          final timeOfDay = TimeOfDay(hour: hour, minute: 0);
          final hourLabel = AppDateUtils.formatTimeOfDay(timeOfDay);
          final slotTasks = tasksByHour[hour] ?? [];

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Marker Column
              SizedBox(
                width: 72,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    hourLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),

              // Vertical Line + Node
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: slotTasks.isNotEmpty ? AppColors.primary : Colors.grey[400],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: slotTasks.isNotEmpty ? (slotTasks.length * 90.0) : 46.0,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Slot Task Area / Tap to Add
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: slotTasks.isNotEmpty
                      ? Column(
                          children: slotTasks.map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TaskCard(key: ValueKey('${t.id}_${t.date}'), task: t),
                              )).toList(),
                        )
                      : InkWell(
                          onTap: () {
                            QuickAddSheet.show(
                              context,
                              initialDate: selectedDate,
                              initialTime: timeOfDay,
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Add task at $hourLabel',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}