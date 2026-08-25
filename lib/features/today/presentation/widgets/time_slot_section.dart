import 'package:flutter/material.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/presentation/widgets/task_card.dart';
import 'package:daypulse/features/today/models/time_block.dart';

class TimeSlotSection extends StatelessWidget {
  final TimeBlockType timeBlock;
  final List<TaskModel> tasks;

  const TimeSlotSection({
    super.key,
    required this.timeBlock,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Icon(
                  timeBlock.icon,
                  size: 18,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
                const SizedBox(width: 8),
                Text(
                  timeBlock.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '· ${tasks.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Task Cards in this Time Slot
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final task = tasks[index];
              return TaskCard(key: ValueKey('${task.id}_${task.date}'), task: task);
            },
          ),
        ],
      ),
    );
  }
}