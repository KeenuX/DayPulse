import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/features/tasks/presentation/widgets/quick_add_sheet.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';
import 'package:daypulse/features/calendar/providers/calendar_provider.dart';
import 'package:daypulse/features/calendar/presentation/widgets/day_timeline_view.dart';
import 'package:daypulse/features/calendar/presentation/widgets/month_grid_view.dart';
import 'package:daypulse/features/calendar/presentation/widgets/week_timeline_view.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(calendarViewModeProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final allTasks = ref.watch(tasksNotifierProvider).value ?? [];
    final selectedDateTasks = ref.watch(calendarTasksForSelectedDateProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Content based on View Mode (Default: Month Grid)
            Expanded(
              child: Builder(
                builder: (ctx) {
                  switch (viewMode) {
                    case CalendarViewMode.day:
                      return DayTimelineView(
                        selectedDate: selectedDate,
                        tasks: selectedDateTasks,
                      );
                    case CalendarViewMode.week:
                      return WeekTimelineView(
                        selectedDate: selectedDate,
                        allTasks: allTasks,
                      );
                    case CalendarViewMode.month:
                      return MonthGridView(
                        selectedDate: selectedDate,
                        allTasks: allTasks,
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}