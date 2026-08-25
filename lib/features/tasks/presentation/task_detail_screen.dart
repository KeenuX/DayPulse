import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:daypulse/core/routing/app_routes.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/core/utilities/duration_formatter.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';
import 'package:daypulse/features/tasks/presentation/widgets/reschedule_modal.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _subtaskInputController = TextEditingController();

  @override
  void dispose() {
    _subtaskInputController.dispose();
    super.dispose();
  }

  void _addSubtask(String parentId) async {
    final text = _subtaskInputController.text.trim();
    if (text.isEmpty) return;

    await ref.read(tasksNotifierProvider.notifier).addSubtask(
          parentId: parentId,
          title: text,
        );
    _subtaskInputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tasksAsync = ref.watch(tasksNotifierProvider);
    final subtasks = ref.watch(subtasksForParentProvider(widget.taskId));

    final task = tasksAsync.when(
      data: (tasks) {
        try {
          return tasks.firstWhere((t) => t.id == widget.taskId);
        } catch (_) {
          return null;
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );

    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Task not found')),
      );
    }

    final category = ref.watch(categoryByIdProvider(task.categoryId));
    final completedSubtasksCount = subtasks.where((s) => s.completed).length;
    final totalSubtasksCount = subtasks.length;
    final subtaskProgress = totalSubtasksCount > 0 ? (completedSubtasksCount / totalSubtasksCount) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              context.push('${AppRoutes.editTask}/${task.id}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Reschedule',
            onPressed: () {
              RescheduleModal.show(context, task: task);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
            tooltip: 'Delete',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Task?'),
                  content: Text(
                    subtasks.isNotEmpty
                        ? 'Are you sure you want to delete "${task.title}" and its ${subtasks.length} subtasks?'
                        : 'Are you sure you want to delete "${task.title}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await ref.read(tasksNotifierProvider.notifier).deleteTask(task.id);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) context.pop();
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: task.completed ? AppColors.info : AppColors.success,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () async {
            await ref.read(tasksNotifierProvider.notifier).toggleTaskCompletion(task.id, !task.completed);
          },
          icon: Icon(task.completed ? Icons.replay_rounded : Icons.check_circle_rounded),
          label: Text(
            task.completed ? 'Mark as Incomplete' : 'Mark as Completed',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Completion Status Banner
          if (task.completed)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Task Completed',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                        if (task.completedAt != null)
                          Text(
                            'Completed on ${DateFormat('MMM d, yyyy · h:mm a').format(task.completedAt!)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (task.isOverdue)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overdue Task',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                        Text(
                          'Scheduled time has passed without completion.',
                          style: TextStyle(fontSize: 12, color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(tasksNotifierProvider.notifier).moveOverdueTaskToToday(task.id),
                    child: const Text('Move to Today', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Title
          Text(
            task.title,
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 12),

          // Description
          if (task.description != null && task.description!.isNotEmpty) ...[
            Text(
              task.description!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Dedicated Subtasks Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.checklist_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Subtasks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      if (totalSubtasksCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: completedSubtasksCount == totalSubtasksCount
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$completedSubtasksCount / $totalSubtasksCount completed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: completedSubtasksCount == totalSubtasksCount
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Subtask progress bar
                  if (totalSubtasksCount > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: subtaskProgress,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completedSubtasksCount == totalSubtasksCount ? AppColors.success : AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    const SizedBox(height: 10),
                  ],

                  // List of subtasks
                  if (subtasks.isNotEmpty) ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: subtasks.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final subtask = subtasks[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  ref.read(tasksNotifierProvider.notifier).toggleTaskCompletion(
                                        subtask.id,
                                        !subtask.completed,
                                      );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: subtask.completed
                                        ? AppColors.primary
                                        : (isDark ? const Color(0xFF1E293B) : Colors.transparent),
                                    border: Border.all(
                                      color: subtask.completed
                                          ? AppColors.primary
                                          : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                                      width: 1.8,
                                    ),
                                  ),
                                  child: subtask.completed
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                      : null,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  subtask.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    decoration: subtask.completed ? TextDecoration.lineThrough : null,
                                    color: subtask.completed
                                        ? (isDark ? Colors.grey[500] : Colors.grey[400])
                                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                onPressed: () {
                                  ref.read(tasksNotifierProvider.notifier).deleteTask(subtask.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Fast inline + Add Subtask input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskInputController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Add a subtask...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          ),
                          onSubmitted: (_) => _addSubtask(task.id),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _addSubtask(task.id),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Key Attributes Grid
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Category
                  _DetailRow(
                    icon: category?.icon ?? Icons.folder_outlined,
                    iconColor: category?.color ?? Colors.grey,
                    label: 'Category',
                    value: category?.name ?? 'General',
                  ),
                  const Divider(height: 24),

                  // Priority
                  _DetailRow(
                    icon: Icons.flag_rounded,
                    iconColor: task.priority.color,
                    label: 'Priority',
                    value: task.priority.label,
                  ),
                  const Divider(height: 24),

                  // Date
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    iconColor: theme.colorScheme.primary,
                    label: 'Scheduled Date',
                    value: '${AppDateUtils.formatDisplayDate(task.scheduledDate)} (${AppDateUtils.relativeDateLabel(task.scheduledDate)})',
                  ),
                  const Divider(height: 24),

                  // Time & Duration
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    iconColor: theme.colorScheme.primary,
                    label: 'Time & Duration',
                    value: task.startTime != null
                        ? '${AppDateUtils.formatTimeStringTo12Hour(task.startTime)}'
                            '${task.endTime != null ? ' - ${AppDateUtils.formatTimeStringTo12Hour(task.endTime)}' : ''}'
                            '${task.durationMinutes != null ? ' (${DurationFormatter.formatMinutes(task.durationMinutes)})' : ''}'
                        : 'Unscheduled / Anytime',
                  ),
                  const Divider(height: 24),

                  // Repeat
                  _DetailRow(
                    icon: Icons.repeat_rounded,
                    iconColor: Colors.cyan[600]!,
                    label: 'Repeat Rule',
                    value: task.repeatRule.label,
                  ),
                  const Divider(height: 24),

                  // Reminder
                  _DetailRow(
                    icon: Icons.notifications_active_outlined,
                    iconColor: Colors.amber[700]!,
                    label: 'Reminder',
                    value: task.reminderEnabled
                        ? (task.reminderTime != null
                            ? '${task.reminderTime} min before'
                            : 'At task time')
                        : 'Disabled',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Notes Section
          if (task.notes != null && task.notes!.isNotEmpty) ...[
            Text('Notes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  task.notes!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}