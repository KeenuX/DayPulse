import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:daypulse/core/routing/app_routes.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/progress/providers/progress_provider.dart';
import 'package:daypulse/features/progress/presentation/widgets/annual_heatmap_card.dart';
import 'package:daypulse/features/progress/presentation/widgets/completed_tasks_donut_card.dart';
import 'package:daypulse/features/progress/presentation/widgets/daily_completed_card.dart';
import 'package:daypulse/features/progress/presentation/widgets/focus_metrics_card.dart';
import 'package:daypulse/features/progress/presentation/widgets/next_7_days_task_item.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final progressData = ref.watch(progressAnalyticsProvider);
    final allTasks = ref.watch(tasksNotifierProvider).value ?? [];
    final tasksNotifier = ref.watch(tasksNotifierProvider.notifier);
    final occurrences = tasksNotifier.occurrences;

    // 1. Completed top-level tasks (Regular completed + Completed recurring occurrences)
    final regularCompleted = allTasks.where((t) => t.completed && t.isTopLevel && !t.isRecurring).length;
    final recurringTopLevelIds = allTasks.where((t) => t.isTopLevel && t.isRecurring).map((t) => t.id).toSet();
    final recurringCompletedOccurrences = occurrences
        .where((occ) => occ.completed && !occ.isSkipped && recurringTopLevelIds.contains(occ.taskId))
        .length;
    final totalCompletedCount = regularCompleted + recurringCompletedOccurrences;

    // 2. Pending top-level tasks (Regular pending + Today's pending recurring tasks)
    final regularPending = allTasks.where((t) => !t.completed && t.isTopLevel && !t.isRecurring).length;
    final now = DateTime.now();
    final today = AppDateUtils.normalizeDate(now);
    final todayTasks = tasksNotifier.getTasksForDate(today);
    final todayPendingRecurring = todayTasks.where((t) => t.isTopLevel && t.isRecurring && !t.completed).length;
    final totalPendingCount = regularPending + todayPendingRecurring;

    // 3. Next 7 days tasks
    final List<TaskModel> next7DaysTasks = [];
    for (int i = 0; i <= 7; i++) {
      final targetDate = today.add(Duration(days: i));
      final dayTasks = tasksNotifier.getTasksForDate(targetDate);
      next7DaysTasks.addAll(dayTasks.where((t) => t.isTopLevel && !t.completed));
    }

    final streak = progressData?.streakData.currentStreak ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Me'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Profile Header (Screenshot 3)
          InkWell(
            onTap: () => context.push(AppRoutes.settings),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kept to your plan for ${streak > 0 ? streak : 1} day${streak > 1 ? 's' : ''}!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Local & Private · Tap for Settings',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Productivity Hub Banner (100% Free & Offline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B93F6), Color(0xFF8FB1FF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B93F6).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Productivity Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✨', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        '100% Free',
                        style: TextStyle(
                          color: Color(0xFF4F75FF),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. 2-Column Summary Cards Row (Screenshot 3)
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Completed Tasks',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$totalCompletedCount',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Pending Tasks',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.help_outline_rounded,
                              size: 14,
                              color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$totalPendingCount',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Annual Heatmap Section (Screenshot 3)
          AnnualHeatmapCard(tasks: allTasks),
          const SizedBox(height: 16),

          // 5. Completed Tasks Section with Donut Ring (Screenshot 3 & 4)
          CompletedTasksDonutCard(
            allTasks: allTasks,
          ),
          const SizedBox(height: 16),

          // 6. Daily Completed Section (Screenshot 4 & 5)
          DailyCompletedCard(
            weeklyMetrics: progressData?.weeklyMetrics ?? [],
            mostProductiveDay: progressData?.mostProductiveDay ?? '--',
            allTasks: allTasks,
          ),
          const SizedBox(height: 16),

          // 7. Focus Section (Screenshot 4 & 5)
          FocusMetricsCard(
            totalFocusMinutes: allTasks
                .where((t) => t.completed && t.durationMinutes != null)
                .fold<int>(0, (sum, t) => sum + (t.durationMinutes ?? 0)),
          ),
          const SizedBox(height: 16),

          // 8. Tasks in Next 7 Days Section (Screenshot 5)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tasks in Next 7 Days',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (next7DaysTasks.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No upcoming tasks in the next 7 days.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: next7DaysTasks.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                      itemBuilder: (ctx, index) {
                        final task = next7DaysTasks[index];
                        return Next7DaysTaskItem(
                          key: ValueKey('next7_${task.id}_${task.date}'),
                          task: task,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}