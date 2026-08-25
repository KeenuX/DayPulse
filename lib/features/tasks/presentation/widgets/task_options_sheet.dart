import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:daypulse/core/routing/app_routes.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class TaskOptionsSheet extends ConsumerWidget {
  final TaskModel task;

  const TaskOptionsSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, TaskModel task) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TaskOptionsSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final category = ref.watch(categoryByIdProvider(task.categoryId));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Task Header Info
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B86E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (category != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category.icon, size: 12, color: category.color),
                      const SizedBox(width: 4),
                      Text(
                        category.name,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: category.color),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // 1. Edit Task (Keep)
          _ActionTile(
            icon: Icons.edit_outlined,
            iconColor: const Color(0xFF3B82F6),
            title: 'Edit Task',
            subtitle: 'Change title, description, time, subtasks & details',
            onTap: () {
              Navigator.of(context).pop();
              context.push('${AppRoutes.editTask}/${task.id}');
            },
          ),

          // 2. Add Subtask (Keep)
          _ActionTile(
            icon: Icons.add_task_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Add Subtask',
            subtitle: 'Break down task into smaller pieces',
            onTap: () {
              Navigator.of(context).pop();
              _showAddSubtaskDialog(context, ref);
            },
          ),

          // 3. Mark as Completed / Incomplete (Keep)
          _ActionTile(
            icon: task.completed ? Icons.replay_rounded : Icons.check_circle_outline_rounded,
            iconColor: task.completed ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
            title: task.completed ? 'Mark as Incomplete' : 'Mark as Completed',
            subtitle: task.completed ? 'Reopen task and its subtasks' : 'Complete task and subtasks',
            onTap: () {
              Navigator.of(context).pop();
              ref.read(tasksNotifierProvider.notifier).toggleTaskCompletion(task.id, !task.completed);
            },
          ),

          // 4. Delete Task (Keep & Fixed Context)
          _ActionTile(
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFEF4444),
            title: 'Delete Task',
            subtitle: 'Permanently remove this task',
            isDestructive: true,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Task?'),
                  content: Text('Permanently delete "${task.title}" and its subtasks?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(tasksNotifierProvider.notifier).deleteTask(task.id);
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddSubtaskDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subtask'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter subtask title...',
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              ref.read(tasksNotifierProvider.notifier).addSubtask(parentId: task.id, title: val.trim());
              Navigator.of(ctx).pop();
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(tasksNotifierProvider.notifier).addSubtask(parentId: task.id, title: controller.text.trim());
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? const Color(0xFFEF4444)
                          : (isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
