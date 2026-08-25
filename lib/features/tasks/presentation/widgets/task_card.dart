import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:daypulse/core/routing/app_routes.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/core/utilities/duration_formatter.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';
import 'package:daypulse/features/tasks/models/repeat_rule.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/models/task_priority.dart';
import 'package:daypulse/features/tasks/presentation/widgets/reschedule_modal.dart';
import 'package:daypulse/features/tasks/presentation/widgets/task_options_sheet.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class TaskCard extends ConsumerStatefulWidget {
  final TaskModel task;
  final bool showDate;
  final VoidCallback? onDismissed;

  const TaskCard({
    super.key,
    required this.task,
    this.showDate = false,
    this.onDismissed,
  });

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  bool _isExpanded = false;
  bool _showActions = false;
  final _quickSubtaskController = TextEditingController();
  bool _isAddingSubtask = false;

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _showActions = false;
      _isExpanded = false;
      _isAddingSubtask = false;
    }
  }

  @override
  void dispose() {
    _quickSubtaskController.dispose();
    super.dispose();
  }

  void _submitQuickSubtask() async {
    final text = _quickSubtaskController.text.trim();
    if (text.isEmpty) return;

    await ref.read(tasksNotifierProvider.notifier).addSubtask(
          parentId: widget.task.id,
          title: text,
        );
    _quickSubtaskController.clear();
    setState(() {
      _isAddingSubtask = false;
      _isExpanded = true;
    });
  }

  void _togglePriority() {
    TaskPriority newPriority;
    if (widget.task.priority == TaskPriority.high) {
      newPriority = TaskPriority.medium;
    } else if (widget.task.priority == TaskPriority.medium) {
      newPriority = TaskPriority.low;
    } else {
      newPriority = TaskPriority.high;
    }
    ref.read(tasksNotifierProvider.notifier).updateTask(
          widget.task.copyWith(priority: newPriority),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final category = ref.watch(categoryByIdProvider(widget.task.categoryId));
    final subtasks = ref.watch(subtasksForParentOnDateProvider((
      parentId: widget.task.id,
      dateIso: widget.task.date,
    )));

    final isCompleted = widget.task.completed;
    final isOverdue = widget.task.isOverdue;

    final completedSubtasksCount = subtasks.where((s) => s.completed).length;
    final totalSubtasksCount = subtasks.length;
    final hasSubtasks = subtasks.isNotEmpty;

    return Dismissible(
      key: Key('task_${widget.task.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.info : AppColors.success,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.replay_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isCompleted ? 'Mark Incomplete' : 'Complete',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Toggle Complete
          await ref.read(tasksNotifierProvider.notifier).toggleTaskCompletion(
                widget.task.id,
                !isCompleted,
              );
          return false;
        }
        return false;
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isCompleted ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                // 1. Background Docked Action Buttons (Matching Screenshot 2)
                Positioned.fill(
                  child: Container(
                    color: isDark ? const Color(0xFF131A29) : const Color(0xFFE2E8F0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Star Action
                        InkWell(
                          onTap: () {
                            _togglePriority();
                            setState(() => _showActions = false);
                          },
                          child: Container(
                            width: 58,
                            height: double.infinity,
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF2FE),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.task.priority == TaskPriority.high ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: widget.task.priority.color,
                                  size: 22,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Star',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Date Action
                        InkWell(
                          onTap: () {
                            RescheduleModal.show(context, task: widget.task);
                            setState(() => _showActions = false);
                          },
                          child: Container(
                            width: 58,
                            height: double.infinity,
                            color: const Color(0xFF5B86E5),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                                SizedBox(height: 3),
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Delete Action
                        InkWell(
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Task?'),
                                content: Text(
                                  hasSubtasks
                                      ? 'Delete "${widget.task.title}" and its $totalSubtasksCount subtasks?'
                                      : 'Delete "${widget.task.title}"?',
                                ),
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
                              setState(() => _showActions = false);
                              await ref.read(tasksNotifierProvider.notifier).deleteTask(widget.task.id, occurrenceDate: widget.task.date);
                              widget.onDismissed?.call();
                            }
                          },
                          child: Container(
                            width: 58,
                            height: double.infinity,
                            color: const Color(0xFFEF4444),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                SizedBox(height: 3),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Sliding Foreground Content Surface
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! < -100) {
                        // Swiped left -> open actions
                        setState(() => _showActions = true);
                      } else if (details.primaryVelocity! > 100) {
                        // Swiped right -> close actions
                        setState(() => _showActions = false);
                      }
                    }
                  },
                  child: AnimatedSlide(
                    offset: _showActions ? const Offset(-0.48, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        boxShadow: _showActions
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(-2, 0),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              if (_showActions) {
                                setState(() => _showActions = false);
                              } else {
                                context.push('${AppRoutes.taskDetail}/${widget.task.id}');
                              }
                            },
                            onLongPress: () {
                              TaskOptionsSheet.show(context, widget.task);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Interactive Checkbox
                                  GestureDetector(
                                    onTap: () {
                                      ref.read(tasksNotifierProvider.notifier).toggleTaskCompletion(
                                            widget.task.id,
                                            !isCompleted,
                                            occurrenceDate: widget.task.date,
                                          );
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 24,
                                      height: 24,
                                      margin: const EdgeInsets.only(top: 2, right: 12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isCompleted
                                            ? AppColors.primary
                                            : (isDark ? const Color(0xFF1E293B) : Colors.transparent),
                                        border: Border.all(
                                          color: isCompleted
                                              ? AppColors.primary
                                              : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                                          width: 2,
                                        ),
                                      ),
                                      child: isCompleted
                                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                                          : null,
                                    ),
                                  ),

                                  // Task Content (Always Full Width - Never Squished)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title & Priority
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                widget.task.title,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  decoration: isCompleted
                                                      ? TextDecoration.lineThrough
                                                      : TextDecoration.none,
                                                  decorationColor: isDark ? Colors.grey[500] : Colors.grey[600],
                                                  color: isCompleted
                                                      ? (isDark ? Colors.grey[400] : Colors.grey[600])
                                                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _PriorityBadge(priority: widget.task.priority),
                                          ],
                                        ),

                                        if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.task.description!,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],

                                        const SizedBox(height: 10),

                                        // Metadata Badges (Category, Subtasks, Time, Duration, Reminder, Overdue)
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            // Category Badge
                                            if (category != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: category.color.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(category.icon, size: 12, color: category.color),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      category.name,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: category.color,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            // Subtasks Progress Badge
                                            if (hasSubtasks)
                                              GestureDetector(
                                                onTap: () => setState(() => _isExpanded = !_isExpanded),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                  decoration: BoxDecoration(
                                                    color: completedSubtasksCount == totalSubtasksCount
                                                        ? AppColors.success.withValues(alpha: 0.12)
                                                        : AppColors.primary.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.checklist_rounded,
                                                        size: 13,
                                                        color: completedSubtasksCount == totalSubtasksCount
                                                            ? AppColors.success
                                                            : AppColors.primary,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '$completedSubtasksCount/$totalSubtasksCount subtasks',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: completedSubtasksCount == totalSubtasksCount
                                                            ? AppColors.success
                                                            : AppColors.primary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Icon(
                                                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                                        size: 14,
                                                        color: completedSubtasksCount == totalSubtasksCount
                                                            ? AppColors.success
                                                            : AppColors.primary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                            // Date Badge
                                            if (widget.showDate)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today_rounded,
                                                      size: 11,
                                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      AppDateUtils.relativeDateLabel(widget.task.scheduledDate),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            // Time Badge
                                            if (widget.task.startTime != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.access_time_rounded,
                                                      size: 11,
                                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      widget.task.endTime != null
                                                          ? '${AppDateUtils.formatTimeStringTo12Hour(widget.task.startTime)} - ${AppDateUtils.formatTimeStringTo12Hour(widget.task.endTime)}'
                                                          : AppDateUtils.formatTimeStringTo12Hour(widget.task.startTime),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            // Duration Badge
                                            if (widget.task.durationMinutes != null && widget.task.durationMinutes! > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.timer_outlined,
                                                      size: 11,
                                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      DurationFormatter.formatMinutes(widget.task.durationMinutes),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            // Reminder Icon
                                            if (widget.task.reminderEnabled)
                                              Icon(
                                                Icons.notifications_active_rounded,
                                                size: 14,
                                                color: isDark ? Colors.amber[400] : Colors.amber[700],
                                              ),

                                            // Repeat Icon
                                            if (widget.task.repeatRule != RepeatRule.none)
                                              Icon(
                                                Icons.repeat_rounded,
                                                size: 14,
                                                color: isDark ? Colors.cyan[400] : Colors.cyan[700],
                                              ),

                                           ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action Slide Toggle Icon (Flag Icon - Matching Screenshot 2)
                                  IconButton(
                                    icon: Icon(
                                      widget.task.priority == TaskPriority.high
                                          ? Icons.flag_rounded
                                          : Icons.outlined_flag_rounded,
                                      size: 20,
                                      color: _showActions ? AppColors.primary : widget.task.priority.color,
                                    ),
                                    onPressed: () {
                                      setState(() => _showActions = !_showActions);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Expandable Subtasks Checklist Section (Compact & Sleek)
                          if (_isExpanded && (hasSubtasks || _isAddingSubtask)) ...[
                            const Divider(height: 1),
                            Container(
                              margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  ...subtasks.map((subtask) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              ref.read(tasksNotifierProvider.notifier).toggleTaskCompletion(
                                                    subtask.id,
                                                    !subtask.completed,
                                                    occurrenceDate: widget.task.date,
                                              );
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 150),
                                              width: 16,
                                              height: 16,
                                              margin: const EdgeInsets.only(right: 8),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: subtask.completed
                                                    ? AppColors.primary
                                                    : (isDark ? const Color(0xFF1E293B) : Colors.transparent),
                                                border: Border.all(
                                                  color: subtask.completed
                                                      ? AppColors.primary
                                                      : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: subtask.completed
                                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 10)
                                                  : null,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              subtask.title,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                decoration: subtask.completed ? TextDecoration.lineThrough : null,
                                                color: subtask.completed
                                                    ? (isDark ? Colors.grey[500] : Colors.grey[400])
                                                    : (isDark ? Colors.grey[200] : const Color(0xFF334155)),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              ref.read(tasksNotifierProvider.notifier).deleteTask(subtask.id);
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(4.0),
                                              child: Icon(Icons.close_rounded, size: 13, color: Colors.grey),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),

                                  // Compact inline subtask input field
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 30,
                                            child: TextField(
                                              controller: _quickSubtaskController,
                                              style: const TextStyle(fontSize: 12),
                                              decoration: InputDecoration(
                                                hintText: 'Add subtask...',
                                                hintStyle: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                                ),
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide.none,
                                                ),
                                                filled: true,
                                                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                              ),
                                              onSubmitted: (_) => _submitQuickSubtask(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: _submitQuickSubtask,
                                          child: Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.add_rounded, color: AppColors.primary, size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    if (priority == TaskPriority.low) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: priority.color,
        ),
      ),
    );
  }
}