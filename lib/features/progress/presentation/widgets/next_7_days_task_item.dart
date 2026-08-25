import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

class Next7DaysTaskItem extends ConsumerStatefulWidget {
  final TaskModel task;

  const Next7DaysTaskItem({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<Next7DaysTaskItem> createState() => _Next7DaysTaskItemState();
}

class _Next7DaysTaskItemState extends ConsumerState<Next7DaysTaskItem> {
  bool _showActions = false;
  bool _isExpanded = false;
  final TextEditingController _quickSubtaskController = TextEditingController();

  @override
  void didUpdateWidget(covariant Next7DaysTaskItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id || oldWidget.task.date != widget.task.date) {
      _showActions = false;
      _isExpanded = false;
    }
  }

  @override
  void dispose() {
    _quickSubtaskController.dispose();
    super.dispose();
  }

  void _submitSubtask() async {
    final text = _quickSubtaskController.text.trim();
    if (text.isEmpty) return;
    await ref.read(tasksNotifierProvider.notifier).addSubtask(
          parentId: widget.task.id,
          title: text,
        );
    _quickSubtaskController.clear();
    setState(() => _isExpanded = true);
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

  String _formatDateBadge(DateTime taskDate) {
    final now = DateTime.now();
    final today = AppDateUtils.normalizeDate(now);
    final target = AppDateUtils.normalizeDate(taskDate);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(taskDate);
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
    final accentColor = category?.color ?? const Color(0xFF6495ED);

    final completedSubtasksCount = subtasks.where((s) => s.completed).length;
    final totalSubtasksCount = subtasks.length;

    final dateBadge = _formatDateBadge(widget.task.scheduledDate);
    final timeStr = widget.task.startTime != null
        ? AppDateUtils.formatTimeStringTo12Hour(widget.task.startTime!)
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            // Top Main Row with Swipe Actions
            Stack(
              children: [
                // 1. Background Docked Action Buttons
                Positioned.fill(
                  child: Container(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Star Action
                        InkWell(
                          onTap: () {
                            setState(() => _showActions = false);
                            _togglePriority();
                          },
                          child: Container(
                            width: 52,
                            height: double.infinity,
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF2FE),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.task.priority == TaskPriority.high
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: widget.task.priority.color,
                                  size: 18,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Star',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Date / Reschedule Action
                        InkWell(
                          onTap: () {
                            setState(() => _showActions = false);
                            RescheduleModal.show(context, task: widget.task);
                          },
                          child: Container(
                            width: 52,
                            height: double.infinity,
                            color: const Color(0xFF6495ED),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                                SizedBox(height: 2),
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 9,
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
                                content: Text('Delete "${widget.task.title}" and its subtasks?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
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
                              if (widget.task.isRecurring) {
                                await ref.read(tasksNotifierProvider.notifier).deleteTask(
                                      widget.task.id,
                                      thisOccurrenceOnly: true,
                                      occurrenceDate: widget.task.date,
                                    );
                              } else {
                                await ref.read(tasksNotifierProvider.notifier).deleteTask(widget.task.id);
                              }
                            }
                          },
                          child: Container(
                            width: 52,
                            height: double.infinity,
                            color: AppColors.error,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                                SizedBox(height: 2),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 9,
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

                // 2. Sliding Foreground Surface
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! < -100) {
                        setState(() => _showActions = true);
                      } else if (details.primaryVelocity! > 100) {
                        setState(() => _showActions = false);
                      }
                    }
                  },
                  child: AnimatedSlide(
                    offset: _showActions ? const Offset(-0.46, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      ),
                      child: InkWell(
                        onTap: () {
                          if (_showActions) {
                            setState(() => _showActions = false);
                          } else {
                            setState(() => _isExpanded = !_isExpanded);
                          }
                        },
                        onLongPress: () {
                          TaskOptionsSheet.show(context, widget.task);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              // Left Category Color Dot/Strip
                              Container(
                                width: 4,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Interactive Checkbox
                              GestureDetector(
                                onTap: () {
                                  ref.read(tasksNotifierProvider.notifier).toggleTaskCompletion(
                                        widget.task.id,
                                        !isCompleted,
                                        occurrenceDate: widget.task.date,
                                      );
                                },
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isCompleted
                                          ? const Color(0xFF6495ED)
                                          : (isDark ? Colors.grey[600]! : const Color(0xFFCBD5E1)),
                                      width: 1.5,
                                    ),
                                    color: isCompleted ? const Color(0xFF6495ED) : Colors.transparent,
                                  ),
                                  child: isCompleted
                                      ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Task Title & Small Category Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.task.title,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: isCompleted
                                            ? (isDark ? Colors.white38 : const Color(0xFF94A3B8))
                                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        // Category Name (Small font)
                                        Text(
                                          category?.name ?? 'General',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 6),
                                        Text('•', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                        const SizedBox(width: 6),
                                        // Date & Time badge
                                        Text(
                                          timeStr != null ? '$dateBadge, $timeStr' : dateBadge,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (widget.task.isRecurring) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.repeat_rounded,
                                            size: 12,
                                            color: isDark ? Colors.cyan[400] : Colors.cyan[700],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Priority Flag (if high)
                              if (widget.task.priority == TaskPriority.high)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.outlined_flag_rounded,
                                    size: 15,
                                    color: widget.task.priority.color,
                                  ),
                                ),

                              // Expand / Collapse Down Arrow Symbol
                              InkWell(
                                onTap: () => setState(() => _isExpanded = !_isExpanded),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: AnimatedRotation(
                                    turns: _isExpanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 3. Expandable Detail Section
            if (_isExpanded) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131A29) : const Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description / Notes
                    if (widget.task.description != null && widget.task.description!.trim().isNotEmpty) ...[
                      Text(
                        widget.task.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Duration & Recurrence Meta
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (widget.task.durationMinutes != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                DurationFormatter.formatMinutes(widget.task.durationMinutes!),
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        if (widget.task.isRecurring)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.repeat_rounded, size: 13, color: Colors.cyan[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Repeats ${widget.task.repeatRule.label}',
                                style: TextStyle(fontSize: 11, color: Colors.cyan[700]),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Subtasks section
                    if (totalSubtasksCount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: completedSubtasksCount / totalSubtasksCount,
                                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$completedSubtasksCount/$totalSubtasksCount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...subtasks.map((subtask) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: InkWell(
                            onTap: () {
                              ref.read(tasksNotifierProvider.notifier).toggleTaskCompletion(
                                    subtask.id,
                                    !subtask.completed,
                                    occurrenceDate: widget.task.date,
                                  );
                            },
                            child: Row(
                              children: [
                                Icon(
                                  subtask.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  size: 14,
                                  color: subtask.completed
                                      ? const Color(0xFF10B981)
                                      : (isDark ? Colors.grey[600] : Colors.grey[400]),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    subtask.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtask.completed
                                          ? (isDark ? Colors.white38 : Colors.grey[500])
                                          : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                      decoration: subtask.completed ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    // Inline Subtask Adder
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quickSubtaskController,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Add a subtask...',
                              hintStyle: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[600] : const Color(0xFF94A3B8),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _submitSubtask(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(Icons.add_circle_rounded, color: accentColor, size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _submitSubtask,
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => context.push('${AppRoutes.taskDetail}/${widget.task.id}'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Edit full',
                            style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
