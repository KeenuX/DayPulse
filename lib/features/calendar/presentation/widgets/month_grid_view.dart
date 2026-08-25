import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:daypulse/core/routing/app_routes.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/categories/models/category_model.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/models/task_priority.dart';
import 'package:daypulse/features/tasks/presentation/widgets/quick_add_sheet.dart';
import 'package:daypulse/features/tasks/presentation/widgets/reschedule_modal.dart';
import 'package:daypulse/features/tasks/presentation/widgets/task_options_sheet.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';
import 'package:daypulse/features/calendar/providers/calendar_provider.dart';

class MonthGridView extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final List<TaskModel> allTasks;

  const MonthGridView({
    super.key,
    required this.selectedDate,
    required this.allTasks,
  });

  @override
  ConsumerState<MonthGridView> createState() => _MonthGridViewState();
}

class _MonthGridViewState extends ConsumerState<MonthGridView> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
  }

  void _showFilterBottomSheet(BuildContext context) {
    final categories = ref.read(categoriesNotifierProvider).value ?? [];
    final currentFilter = ref.read(calendarFilterProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filter = ref.watch(calendarFilterProvider);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Calendar Tasks',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (filter.hasActiveFilter)
                        TextButton(
                          onPressed: () {
                            ref.read(calendarFilterProvider.notifier).state = const CalendarFilterState();
                            setModalState(() {});
                          },
                          child: const Text('Reset All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Categories Filter
                  const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: filter.categoryId == null,
                          onSelected: (_) {
                            ref.read(calendarFilterProvider.notifier).state = filter.copyWith(clearCategory: true);
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(width: 8),
                        ...categories.map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                avatar: Icon(c.icon, size: 14, color: filter.categoryId == c.id ? Colors.white : c.color),
                                label: Text(c.name),
                                selected: filter.categoryId == c.id,
                                onSelected: (sel) {
                                  ref.read(calendarFilterProvider.notifier).state =
                                      filter.copyWith(categoryId: sel ? c.id : null, clearCategory: !sel);
                                  setModalState(() {});
                                },
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Priority Filter
                  const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: filter.priority == null,
                        onSelected: (_) {
                          ref.read(calendarFilterProvider.notifier).state = filter.copyWith(clearPriority: true);
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      ...TaskPriority.values.map((p) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: Icon(Icons.flag_rounded, size: 14, color: p.color),
                              label: Text(p.label),
                              selected: filter.priority == p,
                              onSelected: (sel) {
                                ref.read(calendarFilterProvider.notifier).state =
                                    filter.copyWith(priority: sel ? p : null, clearPriority: !sel);
                                setModalState(() {});
                              },
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status Filter
                  const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: filter.isCompleted == null,
                        onSelected: (_) {
                          ref.read(calendarFilterProvider.notifier).state = filter.copyWith(clearCompleted: true);
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pending Only'),
                        selected: filter.isCompleted == false,
                        onSelected: (sel) {
                          ref.read(calendarFilterProvider.notifier).state =
                              filter.copyWith(isCompleted: sel ? false : null, clearCompleted: !sel);
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Completed Only'),
                        selected: filter.isCompleted == true,
                        onSelected: (sel) {
                          ref.read(calendarFilterProvider.notifier).state =
                              filter.copyWith(isCompleted: sel ? true : null, clearCompleted: !sel);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Apply Filter'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tasksNotifier = ref.watch(tasksNotifierProvider.notifier);
    final filter = ref.watch(calendarFilterProvider);
    final selectedDayTasks = ref.watch(calendarTasksForSelectedDateProvider);

    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final startOffset = firstDayOfMonth.weekday % 7; // Sunday = 0

    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    final daysInPrevMonth = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
    final totalGridCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 1. Month Navigation Header Row (Matching Screenshot)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                    });
                  },
                ),
                const Spacer(),

                // Filter Icon Button with Active Badge
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.filter_alt_outlined,
                        size: 22,
                        color: filter.hasActiveFilter ? const Color(0xFF5B86E5) : const Color(0xFF64748B),
                      ),
                      tooltip: 'Filter Tasks',
                      onPressed: () => _showFilterBottomSheet(context),
                    ),
                    if (filter.hasActiveFilter)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF5B86E5),
                          ),
                        ),
                      ),
                  ],
                ),

                // View Mode Switcher Dropdown
                PopupMenuButton<CalendarViewMode>(
                  icon: const Icon(Icons.calendar_view_week_rounded, size: 22, color: Color(0xFF64748B)),
                  tooltip: 'Switch View',
                  onSelected: (mode) {
                    ref.read(calendarViewModeProvider.notifier).state = mode;
                  },
                  itemBuilder: (ctx) => CalendarViewMode.values.map((mode) {
                    return PopupMenuItem(
                      value: mode,
                      child: Row(
                        children: [
                          Icon(
                            mode == CalendarViewMode.month
                                ? Icons.calendar_view_month_rounded
                                : mode == CalendarViewMode.week
                                    ? Icons.calendar_view_week_rounded
                                    : Icons.view_day_rounded,
                            size: 18,
                            color: mode == CalendarViewMode.month ? const Color(0xFF5B86E5) : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text('${mode.label} View'),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                // More Options Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 22, color: Color(0xFF64748B)),
                  tooltip: 'More',
                  onSelected: (val) async {
                    if (val == 'today') {
                      final now = DateTime.now();
                      ref.read(selectedCalendarDateProvider.notifier).state = AppDateUtils.normalizeDate(now);
                      setState(() {
                        _currentMonth = DateTime(now.year, now.month, 1);
                      });
                    } else if (val == 'pick_date') {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: widget.selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        ref.read(selectedCalendarDateProvider.notifier).state = picked;
                        setState(() {
                          _currentMonth = DateTime(picked.year, picked.month, 1);
                        });
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'today',
                      child: Row(
                        children: [
                          Icon(Icons.today_rounded, size: 18, color: Color(0xFF5B86E5)),
                          SizedBox(width: 8),
                          Text('Jump to Today'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'pick_date',
                      child: Row(
                        children: [
                          Icon(Icons.event_rounded, size: 18, color: Color(0xFF64748B)),
                          SizedBox(width: 8),
                          Text('Pick Date...'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Weekday Names Row (Sun Mon Tue Wed Thu Fri Sat)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) {
                return SizedBox(
                  width: 38,
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // 3. Calendar Grid Matrix
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 4,
                childAspectRatio: 1.08,
              ),
              itemCount: totalGridCells,
              itemBuilder: (ctx, index) {
                DateTime cellDate;
                bool isCurrentMonth = true;

                if (index < startOffset) {
                  final dayNum = daysInPrevMonth - startOffset + index + 1;
                  cellDate = DateTime(prevMonth.year, prevMonth.month, dayNum);
                  isCurrentMonth = false;
                } else if (index >= startOffset + daysInMonth) {
                  final dayNum = index - (startOffset + daysInMonth) + 1;
                  cellDate = DateTime(_currentMonth.year, _currentMonth.month + 1, dayNum);
                  isCurrentMonth = false;
                } else {
                  final dayNum = index - startOffset + 1;
                  cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
                }

                final isSelected = cellDate.year == widget.selectedDate.year &&
                    cellDate.month == widget.selectedDate.month &&
                    cellDate.day == widget.selectedDate.day;
                final isToday = AppDateUtils.isToday(cellDate);
                final dayTasks = tasksNotifier.getTasksForDate(cellDate);
                final hasTasks = dayTasks.where((t) => t.isTopLevel).isNotEmpty;

                return InkWell(
                  onTap: () {
                    ref.read(selectedCalendarDateProvider.notifier).state = cellDate;
                    if (!isCurrentMonth) {
                      setState(() {
                        _currentMonth = DateTime(cellDate.year, cellDate.month, 1);
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6495ED)
                            : (isToday && isCurrentMonth
                                ? const Color(0xFF6495ED).withValues(alpha: 0.15)
                                : Colors.transparent),
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6495ED).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${cellDate.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || (isToday && isCurrentMonth)
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (!isCurrentMonth
                                      ? (isDark ? Colors.grey[700] : const Color(0xFFCBD5E1))
                                      : (isDark ? Colors.white : const Color(0xFF1E293B))),
                            ),
                          ),
                          if (hasTasks) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : const Color(0xFF6495ED),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 4. Selected Day Tasks Section (Matching Screenshot)
            if (selectedDayTasks.isEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    // Desk Calendar 3D Illustration Card
                    Container(
                      width: 140,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                6,
                                (i) => Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Icon(
                                Icons.calendar_month_rounded,
                                size: 40,
                                color: const Color(0xFF6495ED).withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Click "+" to create a new task.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Plan your day on the calendar view clearly!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedDayTasks.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final task = selectedDayTasks[index];
                  return _CalendarTaskItem(
                    key: ValueKey('${task.id}_${task.date}'),
                    task: task,
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ],
        );
  }
}

class _CalendarTaskItem extends ConsumerStatefulWidget {
  final TaskModel task;

  const _CalendarTaskItem({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<_CalendarTaskItem> createState() => _CalendarTaskItemState();
}

class _CalendarTaskItemState extends ConsumerState<_CalendarTaskItem> {
  bool _showActions = false;
  bool _isExpanded = false;
  final _quickSubtaskController = TextEditingController();

  @override
  void didUpdateWidget(_CalendarTaskItem oldWidget) {
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

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              children: [
                // 1. Background Docked Action Buttons
                Positioned.fill(
                  child: Container(
                    color: isDark ? const Color(0xFF131A29) : const Color(0xFFE2E8F0),
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

                        // Date / Reschedule Action
                        InkWell(
                          onTap: () {
                            setState(() => _showActions = false);
                            RescheduleModal.show(context, task: widget.task);
                          },
                          child: Container(
                            width: 58,
                            height: double.infinity,
                            color: const Color(0xFF6495ED),
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
                                content: Text('Delete "${widget.task.title}" and its subtasks?'),
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

                // 2. Sliding Foreground Surface matching user screenshot
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
                    offset: _showActions ? const Offset(-0.48, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F7FC),
                      ),
                      child: InkWell(
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
                        child: Row(
                          children: [
                            // Left Accent Vertical Strip (Matching Screenshot)
                            Container(
                              width: 5,
                              height: 54,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Checkbox
                            GestureDetector(
                              onTap: () {
                                ref.read(tasksNotifierProvider.notifier).toggleTaskCompletion(
                                      widget.task.id,
                                      !isCompleted,
                                      occurrenceDate: widget.task.date,
                                    );
                              },
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCompleted
                                        ? const Color(0xFF6495ED)
                                        : (isDark ? Colors.grey[600]! : const Color(0xFFCBD5E1)),
                                    width: 1.8,
                                  ),
                                  color: isCompleted ? const Color(0xFF6495ED) : Colors.transparent,
                                ),
                                child: isCompleted
                                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Title & Details
                            Expanded(
                              child: Text(
                                widget.task.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? (isDark ? Colors.grey[500] : Colors.grey[400])
                                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),

                            // Subtasks toggle icon if any
                            if (subtasks.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: const Color(0xFF64748B),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() => _isExpanded = !_isExpanded);
                                },
                              ),
                            const SizedBox(width: 8),

                            // Priority Flag Icon on Far Right (Matching Screenshot)
                            IconButton(
                              icon: Icon(
                                Icons.outlined_flag_rounded,
                                size: 20,
                                color: widget.task.priority != TaskPriority.low
                                    ? widget.task.priority.color
                                    : const Color(0xFFCBD5E1),
                              ),
                              padding: const EdgeInsets.only(right: 14),
                              constraints: const BoxConstraints(),
                              onPressed: _togglePriority,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Subtasks Expansion Section
        if (_isExpanded && subtasks.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 24, right: 8, bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131A29) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ...subtasks.map((subtask) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              ref.read(tasksNotifierProvider.notifier).toggleTaskCompletion(
                                    subtask.id,
                                    !subtask.completed,
                                    occurrenceDate: subtask.date,
                                  );
                            },
                            child: Icon(
                              subtask.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: subtask.completed ? const Color(0xFF6495ED) : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subtask.title,
                              style: TextStyle(
                                fontSize: 13,
                                decoration: subtask.completed ? TextDecoration.lineThrough : null,
                                color: subtask.completed ? Colors.grey : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quickSubtaskController,
                        decoration: const InputDecoration(
                          hintText: 'Add subtask...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onSubmitted: (_) => _submitSubtask(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded, size: 20, color: Color(0xFF6495ED)),
                      onPressed: _submitSubtask,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}