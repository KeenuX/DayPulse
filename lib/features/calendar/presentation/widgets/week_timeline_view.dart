import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/presentation/widgets/quick_add_sheet.dart';
import 'package:daypulse/features/tasks/presentation/widgets/task_card.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';
import 'package:daypulse/features/calendar/providers/calendar_provider.dart';

class WeekTimelineView extends ConsumerWidget {
  final DateTime selectedDate;
  final List<TaskModel> allTasks;

  const WeekTimelineView({
    super.key,
    required this.selectedDate,
    required this.allTasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weekDays = AppDateUtils.getDaysInWeek(selectedDate);
    final dayFormat = DateFormat('E');
    final monthDayFormat = DateFormat('d');
    final tasksNotifier = ref.watch(tasksNotifierProvider.notifier);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 7-day week selector header
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              final isSelected = day.year == selectedDate.year &&
                  day.month == selectedDate.month &&
                  day.day == selectedDate.day;
              final isToday = AppDateUtils.isToday(day);
              final dayTasks = tasksNotifier.getTasksForDate(day);

              return GestureDetector(
                onTap: () {
                  ref.read(selectedCalendarDateProvider.notifier).state = day;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6495ED)
                        : (isToday ? const Color(0xFF6495ED).withValues(alpha: 0.15) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayFormat.format(day),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthDayFormat.format(day),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Dot indicator for tasks
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dayTasks.isNotEmpty
                              ? (isSelected ? Colors.white : const Color(0xFF6495ED))
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Day Agenda for the currently selected week date
        Row(
          children: [
            Expanded(
              child: Text(
                '${AppDateUtils.formatDisplayDate(selectedDate)} (${AppDateUtils.relativeDateLabel(selectedDate)})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6495ED)),
              onPressed: () {
                QuickAddSheet.show(context, initialDate: selectedDate);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        Builder(
          builder: (ctx) {
            final dayTasks = tasksNotifier.getTasksForDate(selectedDate);
            if (dayTasks.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.event_available_rounded, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No tasks for this day', style: TextStyle(color: Colors.grey[500])),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => QuickAddSheet.show(context, initialDate: selectedDate),
                        child: const Text('Add Task'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayTasks.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final task = dayTasks[index];
                return TaskCard(
                  key: ValueKey('${task.id}_${task.date}'),
                  task: task,
                );
              },
            );
          },
        ),
      ],
    );
  }
}