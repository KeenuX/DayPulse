import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:daypulse/core/routing/app_routes.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/features/tasks/presentation/widgets/quick_add_sheet.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';
import 'package:daypulse/features/today/models/time_block.dart';
import 'package:daypulse/features/today/providers/today_controller.dart';
import 'package:daypulse/features/today/presentation/widgets/overdue_banner.dart';
import 'package:daypulse/features/today/presentation/widgets/time_slot_section.dart';
import 'package:daypulse/features/today/presentation/widgets/today_header_card.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final todayTasks = ref.watch(todayTasksProvider);
    final timeBlockTasks = ref.watch(todayTimeBlockTasksProvider);
    final tasksAsync = ref.watch(tasksNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text('DayPulse', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.next_plan_outlined),
            tooltip: 'Plan Tomorrow',
            onPressed: () {
              context.push(AppRoutes.planTomorrow);
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Calendar Schedule',
            onPressed: () {
              context.go(AppRoutes.calendar);
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (_) {
          return RefreshIndicator(
            onRefresh: () => ref.read(tasksNotifierProvider.notifier).loadTasks(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Today Command Center Header Card
                const TodayHeaderCard(),
                const SizedBox(height: 16),

                // 2. Overdue Tasks Banner (if any exist)
                const OverdueBanner(),

                // 3. Time Bucket Task Sections
                if (todayTasks.isNotEmpty) ...[
                  // Morning Section
                  TimeSlotSection(
                    timeBlock: TimeBlockType.morning,
                    tasks: timeBlockTasks[TimeBlockType.morning] ?? [],
                  ),

                  // Afternoon Section
                  TimeSlotSection(
                    timeBlock: TimeBlockType.afternoon,
                    tasks: timeBlockTasks[TimeBlockType.afternoon] ?? [],
                  ),

                  // Evening Section
                  TimeSlotSection(
                    timeBlock: TimeBlockType.evening,
                    tasks: timeBlockTasks[TimeBlockType.evening] ?? [],
                  ),

                  // Anytime / Unscheduled Section
                  TimeSlotSection(
                    timeBlock: TimeBlockType.unscheduled,
                    tasks: timeBlockTasks[TimeBlockType.unscheduled] ?? [],
                  ),
                ] else ...[
                  // Empty State for Today
                  _buildEmptyState(context, theme, isDark),
                ],

                const SizedBox(height: 80), // Padding for FAB / Bottom nav
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Your Schedule is Clear Today',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy your free time, or start planning high-impact tasks for maximum focus.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => QuickAddSheet.show(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Task'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.planTomorrow),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Plan Tomorrow'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}