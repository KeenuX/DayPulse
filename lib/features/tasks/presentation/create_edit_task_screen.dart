import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';
import 'package:daypulse/features/tasks/models/reminder_offset.dart';
import 'package:daypulse/features/tasks/models/repeat_rule.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/models/task_priority.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class CreateEditTaskScreen extends ConsumerStatefulWidget {
  final String? taskId;

  const CreateEditTaskScreen({super.key, this.taskId});

  @override
  ConsumerState<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends ConsumerState<CreateEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _newSubtaskController;

  final List<String> _subtaskTitles = [];

  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int? _durationMinutes;
  TaskPriority _priority = TaskPriority.medium;
  String? _categoryId;

  // Recurrence configuration
  RepeatRule _repeatRule = RepeatRule.none;
  RecurrenceEndType _repeatEndType = RecurrenceEndType.never;
  DateTime? _repeatEndDate;
  int _repeatEndCount = 10;
  int _repeatInterval = 1;
  List<int> _repeatDaysOfWeek = [];

  ReminderOffset _reminderOffset = ReminderOffset.tenMinutes;
  bool _reminderEnabled = true;

  TaskModel? _existingTask;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _notesController = TextEditingController();
    _newSubtaskController = TextEditingController();
    _selectedDate = AppDateUtils.normalizeDate(DateTime.now());
    _repeatEndDate = _selectedDate.add(const Duration(days: 30));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit && widget.taskId != null) {
      final tasks = ref.read(tasksNotifierProvider).value ?? [];
      try {
        _existingTask = tasks.firstWhere((t) => t.id == widget.taskId);
        _titleController.text = _existingTask!.title;
        _descriptionController.text = _existingTask!.description ?? '';
        _notesController.text = _existingTask!.notes ?? '';
        _selectedDate = _existingTask!.scheduledDate;
        _startTime = _existingTask!.startTimeOfDay;
        _endTime = _existingTask!.endTimeOfDay;
        _durationMinutes = _existingTask!.durationMinutes;
        _priority = _existingTask!.priority;
        _categoryId = _existingTask!.categoryId;
        _repeatRule = _existingTask!.repeatRule;
        _repeatEndType = _existingTask!.repeatEndType;
        _repeatEndDate = _existingTask!.repeatEndDate != null
            ? AppDateUtils.parseIsoDate(_existingTask!.repeatEndDate!)
            : _selectedDate.add(const Duration(days: 30));
        _repeatEndCount = _existingTask!.repeatEndCount ?? 10;
        _repeatInterval = _existingTask!.repeatInterval;
        _repeatDaysOfWeek = _existingTask!.repeatDaysOfWeek != null ? List.from(_existingTask!.repeatDaysOfWeek!) : [];

        _reminderEnabled = _existingTask!.reminderEnabled;
        _reminderOffset = ReminderOffset.fromString(_existingTask!.reminderTime);

        // Load existing subtasks
        final existingSubtasks = tasks.where((t) => t.parentId == widget.taskId).toList();
        _subtaskTitles.clear();
        for (final s in existingSubtasks) {
          _subtaskTitles.add(s.title);
        }
      } catch (_) {}
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  void _calculateDuration() {
    if (_startTime != null && _endTime != null) {
      final startMins = _startTime!.hour * 60 + _startTime!.minute;
      final endMins = _endTime!.hour * 60 + _endTime!.minute;
      if (endMins > startMins) {
        setState(() {
          _durationMinutes = endMins - startMins;
        });
      }
    }
  }

  void _addSubtask() {
    final text = _newSubtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtaskTitles.add(text);
      _newSubtaskController.clear();
    });
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = _existingTask != null;
    final now = DateTime.now();
    final taskId = _existingTask?.id ?? const Uuid().v4();

    // Auto-capture pending subtask from input field if user didn't press +
    final pendingSubtask = _newSubtaskController.text.trim();
    if (pendingSubtask.isNotEmpty && !_subtaskTitles.contains(pendingSubtask)) {
      _subtaskTitles.add(pendingSubtask);
    }

    final task = TaskModel(
      id: taskId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      categoryId: _categoryId,
      date: AppDateUtils.toIsoDate(_selectedDate),
      startTime: _startTime != null ? AppDateUtils.timeOfDayToString(_startTime!) : null,
      endTime: _endTime != null ? AppDateUtils.timeOfDayToString(_endTime!) : null,
      durationMinutes: _durationMinutes,
      priority: _priority,
      completed: _existingTask?.completed ?? false,
      completedAt: _existingTask?.completedAt,
      reminderEnabled: _reminderEnabled,
      reminderTime: _reminderEnabled ? (_reminderOffset.minutesBefore?.toString() ?? '10') : null,
      repeatRule: _repeatRule,
      repeatEndType: _repeatEndType,
      repeatEndDate: (_repeatRule.isRecurring && _repeatEndType == RecurrenceEndType.untilDate && _repeatEndDate != null)
          ? AppDateUtils.toIsoDate(_repeatEndDate!)
          : null,
      repeatEndCount: (_repeatRule.isRecurring && _repeatEndType == RecurrenceEndType.afterOccurrences)
          ? _repeatEndCount
          : null,
      repeatInterval: _repeatInterval > 0 ? _repeatInterval : 1,
      repeatDaysOfWeek: (_repeatRule == RepeatRule.weekly && _repeatDaysOfWeek.isNotEmpty) ? _repeatDaysOfWeek : null,
      createdAt: _existingTask?.createdAt ?? now,
      updatedAt: now,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (isEdit) {
      await ref.read(tasksNotifierProvider.notifier).updateTask(task);
      final existingTasks = ref.read(tasksNotifierProvider).value ?? [];
      final currentDbSubtaskTitles = existingTasks.where((t) => t.parentId == taskId).map((t) => t.title).toSet();

      for (final title in _subtaskTitles) {
        if (!currentDbSubtaskTitles.contains(title)) {
          await ref.read(tasksNotifierProvider.notifier).addSubtask(
                parentId: taskId,
                title: title,
              );
        }
      }
    } else {
      if (_subtaskTitles.isEmpty) {
        await ref.read(tasksNotifierProvider.notifier).addTask(task);
      } else {
        await ref.read(tasksNotifierProvider.notifier).addTaskWithSubtasks(task, _subtaskTitles);
      }
    }

    if (mounted) {
      context.pop();
    }
  }

  String _getRecurrenceSummary() {
    if (_repeatRule == RepeatRule.none) return 'Does not repeat';

    String freqStr;
    switch (_repeatRule) {
      case RepeatRule.daily:
        freqStr = _repeatInterval == 1 ? 'Repeats daily' : 'Repeats every $_repeatInterval days';
        break;
      case RepeatRule.weekdays:
        freqStr = 'Repeats every weekday (Mon-Fri)';
        break;
      case RepeatRule.weekly:
        freqStr = _repeatInterval == 1 ? 'Repeats weekly' : 'Repeats every $_repeatInterval weeks';
        break;
      case RepeatRule.monthly:
        freqStr = _repeatInterval == 1 ? 'Repeats monthly' : 'Repeats every $_repeatInterval months';
        break;
      case RepeatRule.custom:
        freqStr = 'Repeats every $_repeatInterval days';
        break;
      case RepeatRule.none:
        return 'Does not repeat';
    }

    String endStr;
    switch (_repeatEndType) {
      case RecurrenceEndType.never:
        endStr = 'forever';
        break;
      case RecurrenceEndType.afterOccurrences:
        endStr = 'for $_repeatEndCount occurrences';
        break;
      case RecurrenceEndType.untilDate:
        endStr = _repeatEndDate != null ? 'until ${AppDateUtils.formatDisplayDate(_repeatEndDate!)}' : 'forever';
        break;
    }

    return '$freqStr, $endStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = ref.watch(categoriesNotifierProvider).value ?? [];
    final isEdit = widget.taskId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Task' : 'New Task'),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Title Input
            TextFormField(
              controller: _titleController,
              autofocus: !isEdit,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'What do you want to do?',
                border: InputBorder.none,
                filled: false,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Description Input
            TextFormField(
              controller: _descriptionController,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add description (optional)',
                border: InputBorder.none,
                filled: false,
              ),
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Category Horizontal Selector
            Text('Category', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('None'),
                    selected: _categoryId == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _categoryId = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((cat) {
                    final isSelected = _categoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                        label: Text(cat.name),
                        selected: isSelected,
                        selectedColor: cat.color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _categoryId = selected ? cat.id : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Subtasks Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtasks', style: theme.textTheme.titleMedium),
                if (_subtaskTitles.isNotEmpty)
                  Text('${_subtaskTitles.length} items', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (_subtaskTitles.isNotEmpty) ...[
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _subtaskTitles.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _subtaskTitles.removeAt(oldIndex);
                            _subtaskTitles.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          return ListTile(
                            key: ValueKey('subtask_$index'),
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.radio_button_unchecked, size: 18, color: Colors.grey),
                            title: Text(_subtaskTitles[index], style: const TextStyle(fontSize: 14)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _subtaskTitles.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                      const Divider(),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newSubtaskController,
                            decoration: const InputDecoration(
                              hintText: 'Add a subtask...',
                              border: InputBorder.none,
                              filled: false,
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addSubtask(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                          onPressed: _addSubtask,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Schedule (Date, Time, Duration)
            Text('Schedule', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary, size: 20),
                      ),
                      title: const Text('Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      trailing: Text(
                        AppDateUtils.formatDisplayDate(_selectedDate),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                    const Divider(),

                    // Start Time & End Time
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.access_time_rounded, size: 20, color: Colors.grey[500]),
                            title: const Text('Start Time', style: TextStyle(fontSize: 13)),
                            subtitle: Text(
                              _startTime != null ? AppDateUtils.formatTimeOfDay(_startTime!) : 'None',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _startTime != null ? theme.colorScheme.primary : Colors.grey,
                              ),
                            ),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _startTime ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _startTime = picked;
                                  _reminderEnabled = true;
                                  if (_reminderOffset == ReminderOffset.none) {
                                    _reminderOffset = ReminderOffset.atTime;
                                  }
                                  _calculateDuration();
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.access_time_filled_rounded, size: 20, color: Colors.grey[500]),
                            title: const Text('End Time', style: TextStyle(fontSize: 13)),
                            subtitle: Text(
                              _endTime != null ? AppDateUtils.formatTimeOfDay(_endTime!) : 'None',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _endTime != null ? theme.colorScheme.primary : Colors.grey,
                              ),
                            ),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _endTime ?? (_startTime ?? TimeOfDay.now()),
                              );
                              if (picked != null) {
                                setState(() {
                                  _endTime = picked;
                                  _calculateDuration();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Duration
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.timer_outlined, size: 20, color: Colors.grey[500]),
                      title: const Text('Estimated Duration', style: TextStyle(fontSize: 14)),
                      trailing: DropdownButton<int>(
                        value: _durationMinutes,
                        hint: const Text('Select'),
                        underline: const SizedBox.shrink(),
                        items: [15, 30, 45, 60, 90, 120, 180, 240].map((mins) {
                          return DropdownMenuItem<int>(
                            value: mins,
                            child: Text(
                              mins < 60 ? '$mins min' : '${mins ~/ 60}h ${mins % 60 > 0 ? '${mins % 60}m' : ''}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _durationMinutes = val),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Priority Section
            Text('Priority', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: TaskPriority.values.map((priority) {
                final isSelected = _priority == priority;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _priority = priority),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? priority.color.withValues(alpha: 0.15)
                              : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? priority.color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.flag_rounded, color: priority.color, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              priority.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? priority.color : (isDark ? Colors.grey[300] : Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Repeat / Recurrence Section (Requirement 1)
            Row(
              children: [
                Text('Repeat', style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                if (_repeatRule.isRecurring)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B86E5).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Recurring',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5B86E5)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Frequency Dropdown
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B86E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.repeat_rounded, color: Color(0xFF5B86E5), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Frequency',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        DropdownButton<RepeatRule>(
                          value: _repeatRule,
                          underline: const SizedBox.shrink(),
                          items: RepeatRule.values.map((rule) {
                            return DropdownMenuItem(
                              value: rule,
                              child: Text(
                                rule.label,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _repeatRule = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    if (_repeatRule.isRecurring) ...[
                      const Divider(height: 24),

                      // Interval (Every X days / weeks / months)
                      if (_repeatRule != RepeatRule.weekdays) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _repeatRule == RepeatRule.daily || _repeatRule == RepeatRule.custom
                                  ? 'Every (days)'
                                  : (_repeatRule == RepeatRule.weekly ? 'Every (weeks)' : 'Every (months)'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                                  onPressed: _repeatInterval > 1
                                      ? () => setState(() => _repeatInterval--)
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_repeatInterval',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                                  onPressed: () => setState(() => _repeatInterval++),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // End Condition Selector
                      const Text(
                        'Ends',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _EndOptionChip(
                            label: 'Never',
                            isSelected: _repeatEndType == RecurrenceEndType.never,
                            onTap: () => setState(() => _repeatEndType = RecurrenceEndType.never),
                          ),
                          const SizedBox(width: 8),
                          _EndOptionChip(
                            label: 'On Date',
                            isSelected: _repeatEndType == RecurrenceEndType.untilDate,
                            onTap: () => setState(() => _repeatEndType = RecurrenceEndType.untilDate),
                          ),
                          const SizedBox(width: 8),
                          _EndOptionChip(
                            label: 'After Count',
                            isSelected: _repeatEndType == RecurrenceEndType.afterOccurrences,
                            onTap: () => setState(() => _repeatEndType = RecurrenceEndType.afterOccurrences),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // End details
                      if (_repeatEndType == RecurrenceEndType.untilDate)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('End Date', style: TextStyle(fontSize: 13)),
                          trailing: TextButton.icon(
                            icon: const Icon(Icons.calendar_today_rounded, size: 16),
                            label: Text(
                              _repeatEndDate != null ? AppDateUtils.formatDisplayDate(_repeatEndDate!) : 'Select Date',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _repeatEndDate ?? _selectedDate.add(const Duration(days: 30)),
                                firstDate: _selectedDate,
                                lastDate: _selectedDate.add(const Duration(days: 365 * 3)),
                              );
                              if (picked != null) {
                                setState(() => _repeatEndDate = picked);
                              }
                            },
                          ),
                        ),

                      if (_repeatEndType == RecurrenceEndType.afterOccurrences)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Occurrences', style: TextStyle(fontSize: 13)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                                  onPressed: _repeatEndCount > 1
                                      ? () => setState(() => _repeatEndCount--)
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_repeatEndCount',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                                  onPressed: () => setState(() => _repeatEndCount++),
                                ),
                              ],
                            ),
                          ],
                        ),

                      const SizedBox(height: 8),
                      // Summary box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF5B86E5)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getRecurrenceSummary(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
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
            const SizedBox(height: 24),

            // Reminders Section
            Text('Reminders', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Reminder', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        _reminderEnabled ? 'Notification before scheduled time' : 'No notifications',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      value: _reminderEnabled,
                      onChanged: (val) => setState(() => _reminderEnabled = val),
                    ),
                    if (_reminderEnabled) ...[
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Reminder Timing', style: TextStyle(fontSize: 14)),
                        trailing: DropdownButton<ReminderOffset>(
                          value: _reminderOffset,
                          underline: const SizedBox.shrink(),
                          items: ReminderOffset.values.map((offset) {
                            return DropdownMenuItem(
                              value: offset,
                              child: Text(offset.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _reminderOffset = val);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notes / Checklists Section
            Text('Notes (Markdown Supported)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add extra details, reference links...',
              ),
            ),
            const SizedBox(height: 40),

            // Save Task Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveTask,
                child: Text(
                  isEdit ? 'Update Task' : 'Create Task',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _EndOptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _EndOptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF5B86E5)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }
}