import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class RescheduleModal extends ConsumerWidget {
  final TaskModel task;

  const RescheduleModal({super.key, required this.task});

  static Future<void> show(BuildContext context, {required TaskModel task}) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => RescheduleModal(task: task),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reschedule Task',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            task.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Option 1: Later Today (+2 Hours)
          _RescheduleOptionTile(
            icon: Icons.access_time_rounded,
            title: 'Later Today',
            subtitle: 'In 2 hours',
            onTap: () async {
              final laterTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 2)));
              await ref.read(tasksNotifierProvider.notifier).rescheduleTask(
                    task.id,
                    AppDateUtils.normalizeDate(now),
                    newTime: laterTime,
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),

          // Option 2: Tomorrow
          _RescheduleOptionTile(
            icon: Icons.wb_sunny_outlined,
            title: 'Tomorrow',
            subtitle: AppDateUtils.formatShortDate(now.add(const Duration(days: 1))),
            onTap: () async {
              final tomorrow = AppDateUtils.normalizeDate(now.add(const Duration(days: 1)));
              await ref.read(tasksNotifierProvider.notifier).rescheduleTask(
                    task.id,
                    tomorrow,
                    newTime: task.startTimeOfDay,
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),

          // Option 3: Next Week (In 7 Days)
          _RescheduleOptionTile(
            icon: Icons.next_week_outlined,
            title: 'Next Week',
            subtitle: AppDateUtils.formatShortDate(now.add(const Duration(days: 7))),
            onTap: () async {
              final nextWeek = AppDateUtils.normalizeDate(now.add(const Duration(days: 7)));
              await ref.read(tasksNotifierProvider.notifier).rescheduleTask(
                    task.id,
                    nextWeek,
                    newTime: task.startTimeOfDay,
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),

          // Option 4: Pick Custom Date & Time
          _RescheduleOptionTile(
            icon: Icons.calendar_month_rounded,
            title: 'Pick Custom Date & Time',
            subtitle: 'Select exact date on calendar',
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: task.scheduledDate.isBefore(now) ? now : task.scheduledDate,
                firstDate: now.subtract(const Duration(days: 365)),
                lastDate: now.add(const Duration(days: 365 * 5)),
              );

              if (pickedDate != null && context.mounted) {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: task.startTimeOfDay ?? TimeOfDay.now(),
                );

                await ref.read(tasksNotifierProvider.notifier).rescheduleTask(
                      task.id,
                      pickedDate,
                      newTime: pickedTime ?? task.startTimeOfDay,
                    );

                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RescheduleOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RescheduleOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}