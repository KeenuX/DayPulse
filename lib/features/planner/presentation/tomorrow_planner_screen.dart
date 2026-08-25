import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/tasks/presentation/widgets/quick_add_sheet.dart';
import 'package:daypulse/features/tasks/presentation/widgets/task_card.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class TomorrowPlannerScreen extends ConsumerWidget {
  const TomorrowPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowIso = AppDateUtils.toIsoDate(tomorrow);

    final allTasks = ref.watch(tasksNotifierProvider).value ?? [];
    final notifier = ref.watch(tasksNotifierProvider.notifier);
    final tomorrowTasks = notifier.getTasksForDate(tomorrow);
    final todayTasks = notifier.getTasksForDate(DateTime.now());
    final unfinishedTodayTasks = todayTasks.where((t) => !t.completed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomorrow Planner'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B86E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            onPressed: () {
              QuickAddSheet.show(context, initialDate: tomorrow);
            },
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text(
              'Add Task for Tomorrow',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFF312E81), const Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDateUtils.formatDisplayDate(tomorrow),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set up tomorrow for success',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${tomorrowTasks.length} task${tomorrowTasks.length == 1 ? '' : 's'} currently planned for tomorrow.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Unfinished tasks from today (Quick Move section)
          if (unfinishedTodayTasks.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.pending_actions_rounded, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unfinished Tasks Today (${unfinishedTodayTasks.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    for (final task in unfinishedTodayTasks) {
                      await ref.read(tasksNotifierProvider.notifier).rescheduleTask(
                            task.id,
                            tomorrow,
                            newTime: task.startTimeOfDay,
                          );
                    }
                  },
                  child: const Text('Move All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unfinishedTodayTasks.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final task = unfinishedTodayTasks[index];
                return Card(
                  child: ListTile(
                    title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: task.startTime != null
                        ? Text(AppDateUtils.formatTimeStringTo12Hour(task.startTime))
                        : null,
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () {
                        ref.read(tasksNotifierProvider.notifier).rescheduleTask(
                              task.id,
                              tomorrow,
                              newTime: task.startTimeOfDay,
                            );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      label: const Text('Move', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Tomorrow's Agenda List
          Text(
            'Tomorrow\'s Schedule',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (tomorrowTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.event_note_rounded, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text('No tasks planned for tomorrow yet.'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        QuickAddSheet.show(context, initialDate: tomorrow);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Task'),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tomorrowTasks.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                return TaskCard(
                  key: ValueKey('${tomorrowTasks[index].id}_${tomorrowTasks[index].date}'),
                  task: tomorrowTasks[index],
                );
              },
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}