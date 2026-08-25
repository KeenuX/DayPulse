import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import 'package:daypulse/core/routing/app_routes.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/core/utilities/natural_language_parser.dart';
import 'package:daypulse/features/categories/presentation/category_editor_sheet.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';
import 'package:daypulse/features/tasks/models/repeat_rule.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/models/task_priority.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const QuickAddSheet({super.key, this.initialDate, this.initialTime});

  static Future<void> show(BuildContext context, {DateTime? initialDate, TimeOfDay? initialTime}) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickAddSheet(initialDate: initialDate, initialTime: initialTime),
    );
  }

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _subtaskController = TextEditingController();

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  late AnimationController _pulseController;

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  TaskPriority _selectedPriority = TaskPriority.medium;
  String? _selectedCategoryId;
  bool _enableReminder = false;
  RepeatRule _selectedRepeatRule = RepeatRule.none;
  RecurrenceEndType _repeatEndType = RecurrenceEndType.never;
  int _repeatEndCount = 30;
  DateTime? _repeatEndDate;

  final List<String> _subtasks = [];
  bool _showSubtasksInput = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? AppDateUtils.normalizeDate(DateTime.now());
    _selectedTime = widget.initialTime;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (err) => setState(() => _isListening = false),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _speechEnabled = false;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speechToText.stop();
    _textController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      if (!_speechEnabled) {
        _speechEnabled = await _speechToText.initialize(
          onError: (err) => setState(() => _isListening = false),
          onStatus: (st) {
            if (st == 'done' || st == 'notListening') {
              setState(() => _isListening = false);
            }
          },
        );
      }

      if (_speechEnabled) {
        setState(() => _isListening = true);
        await _speechToText.listen(
          onResult: _onSpeechResult,
          listenOptions: SpeechListenOptions(
            listenMode: ListenMode.confirmation,
            pauseFor: const Duration(seconds: 4),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission required or voice recognition unavailable.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _textController.text = result.recognizedWords;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
    _onTextChanged(result.recognizedWords);
  }

  void _onTextChanged(String text) {
    setState(() {}); // Updates send button state dynamically
    if (text.trim().isEmpty) return;
    final parsed = NaturalLanguageParser.parse(text);

    setState(() {
      if (parsed.startTime != null && widget.initialTime == null) {
        _selectedTime = parsed.startTime;
      }
      if (parsed.priority != TaskPriority.medium) {
        _selectedPriority = parsed.priority;
      }
      if (!AppDateUtils.isToday(parsed.date) && widget.initialDate == null) {
        _selectedDate = parsed.date;
      }
    });
  }

  void _addSubtaskItem() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(text);
      _subtaskController.clear();
    });
  }

  void _openCreateCategorySheet() async {
    final newCategory = await CategoryEditorSheet.show(context);
    if (newCategory != null && mounted) {
      setState(() => _selectedCategoryId = newCategory.id);
    }
  }

  void _submit() async {
    final rawText = _textController.text.trim();
    if (rawText.isEmpty) return;

    if (_isListening) {
      await _speechToText.stop();
    }

    final parsed = NaturalLanguageParser.parse(rawText);
    final finalTitle = parsed.title.isNotEmpty ? parsed.title : rawText;
    final parentTaskId = const Uuid().v4();

    // Auto-capture any subtask in the text field that wasn't added with the + button yet
    final pendingSubtask = _subtaskController.text.trim();
    if (pendingSubtask.isNotEmpty && !_subtasks.contains(pendingSubtask)) {
      _subtasks.add(pendingSubtask);
    }

    final newTask = TaskModel(
      id: parentTaskId,
      title: finalTitle,
      categoryId: _selectedCategoryId,
      date: AppDateUtils.toIsoDate(_selectedDate),
      startTime: _selectedTime != null ? AppDateUtils.timeOfDayToString(_selectedTime!) : null,
      durationMinutes: parsed.durationMinutes ?? 30,
      priority: _selectedPriority,
      completed: false,
      reminderEnabled: _enableReminder || _selectedTime != null,
      reminderTime: _enableReminder ? '10' : (_selectedTime != null ? '0' : null),
      repeatRule: _selectedRepeatRule,
      repeatEndType: _repeatEndType,
      repeatEndDate: (_selectedRepeatRule.isRecurring && _repeatEndType == RecurrenceEndType.untilDate && _repeatEndDate != null)
          ? AppDateUtils.toIsoDate(_repeatEndDate!)
          : null,
      repeatEndCount: (_selectedRepeatRule.isRecurring && _repeatEndType == RecurrenceEndType.afterOccurrences)
          ? _repeatEndCount
          : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(tasksNotifierProvider.notifier).addTaskWithSubtasks(newTask, _subtasks);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final categories = categoriesAsync.value ?? [];

    final selectedCategory = categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    final hasValidTitle = _textController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Category Tabs Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryFilterTab(
                  label: 'All',
                  isSelected: _selectedCategoryId == null,
                  onTap: () => setState(() => _selectedCategoryId = null),
                ),
                const SizedBox(width: 8),
                ...categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryFilterTab(
                      label: cat.name,
                      isSelected: _selectedCategoryId == cat.id,
                      color: cat.color,
                      onTap: () => setState(() => _selectedCategoryId = cat.id),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CategoryFilterTab(
                    label: '+ Add Category',
                    isSelected: false,
                    onTap: _openCreateCategorySheet,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.categories);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Main Input Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: _isListening
                  ? Border.all(color: const Color(0xFFEF4444), width: 1.5)
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    autofocus: true,
                    maxLines: 2,
                    minLines: 1,
                    onChanged: _onTextChanged,
                    onSubmitted: (_) => _submit(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? 'Listening... Speak your task now'
                          : 'Dentist appointment next Tuesday',
                      hintStyle: TextStyle(
                        color: _isListening ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                        fontSize: 15,
                        fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Interactive Voice / Mic Button
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = _isListening ? 1.0 + (_pulseController.value * 0.2) : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? const Color(0xFFEF4444)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            boxShadow: _isListening
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            color: _isListening ? Colors.white : const Color(0xFF64748B),
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Subtasks Section in Quick Add (if open or has subtasks)
          if (_showSubtasksInput || _subtasks.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (_subtasks.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _subtasks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final title = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.subdirectory_arrow_right_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _subtasks.removeAt(index)),
                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add subtask (e.g. Mathematics, Java)...',
                      hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    ),
                    onSubmitted: (_) => _addSubtaskItem(),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _addSubtaskItem,
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Bottom Action Strip with Pinned Send Button
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 1. Category Pill
                      PopupMenuButton<String?>(
                        tooltip: 'Select Category',
                        initialValue: _selectedCategoryId,
                        onSelected: (id) {
                          if (id == '__new_category__') {
                            _openCreateCategorySheet();
                          } else {
                            setState(() => _selectedCategoryId = id);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selectedCategory != null) ...[
                                Icon(selectedCategory.icon, size: 14, color: selectedCategory.color),
                                const SizedBox(width: 6),
                                Text(
                                  selectedCategory.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selectedCategory.color,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'No Category',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem<String?>(
                            value: null,
                            child: Text('No Category'),
                          ),
                          ...categories.map((c) => PopupMenuItem<String?>(
                                value: c.id,
                                child: Row(
                                  children: [
                                    Icon(c.icon, size: 16, color: c.color),
                                    const SizedBox(width: 8),
                                    Text(c.name),
                                  ],
                                ),
                              )),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String?>(
                            value: '__new_category__',
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  '+ Add Category',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),

                      // 2. Calendar Date Icon with Day Number
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 22, color: AppColors.primary),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${_selectedDate.day}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 3. Time / Schedule Icon
                      IconButton(
                        icon: Icon(
                          Icons.access_time_rounded,
                          size: 22,
                          color: _selectedTime != null ? AppColors.primary : const Color(0xFF64748B),
                        ),
                        tooltip: 'Set Time',
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedTime = picked);
                          }
                        },
                      ),

                      // 4. Subtasks Toggle Button
                      IconButton(
                        icon: Icon(
                          Icons.checklist_rounded,
                          size: 22,
                          color: (_showSubtasksInput || _subtasks.isNotEmpty) ? AppColors.primary : const Color(0xFF64748B),
                        ),
                        tooltip: 'Add Subtasks',
                        onPressed: () {
                          setState(() => _showSubtasksInput = !_showSubtasksInput);
                        },
                      ),

                      // 5. Priority Picker
                      PopupMenuButton<TaskPriority>(
                        tooltip: 'Priority',
                        initialValue: _selectedPriority,
                        onSelected: (p) => setState(() => _selectedPriority = p),
                        icon: Icon(
                          Icons.flag_rounded,
                          size: 22,
                          color: _selectedPriority != TaskPriority.low ? _selectedPriority.color : const Color(0xFF64748B),
                        ),
                        itemBuilder: (ctx) => TaskPriority.values.map((p) {
                          return PopupMenuItem(
                            value: p,
                            child: Row(
                              children: [
                                Icon(Icons.flag_rounded, size: 16, color: p.color),
                                const SizedBox(width: 8),
                                Text(p.label),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      // 6. Reminder Toggle
                      IconButton(
                        icon: Icon(
                          _enableReminder ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                          size: 22,
                          color: _enableReminder ? Colors.amber[700] : const Color(0xFF64748B),
                        ),
                        tooltip: 'Toggle Reminder',
                        onPressed: () {
                          setState(() => _enableReminder = !_enableReminder);
                        },
                      ),

                      // 7. Repeat Selector
                      PopupMenuButton<RepeatRule>(
                        tooltip: 'Repeat',
                        initialValue: _selectedRepeatRule,
                        onSelected: (r) {
                          setState(() => _selectedRepeatRule = r);
                        },
                        icon: Icon(
                          Icons.repeat_rounded,
                          size: 22,
                          color: _selectedRepeatRule.isRecurring ? const Color(0xFF5B86E5) : const Color(0xFF64748B),
                        ),
                        itemBuilder: (ctx) => RepeatRule.values.map((rule) {
                          return PopupMenuItem(
                            value: rule,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.repeat_rounded,
                                  size: 16,
                                  color: rule == _selectedRepeatRule ? const Color(0xFF5B86E5) : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(rule.label),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 7. Dynamic Send Button (Always Visible & Pinned)
              GestureDetector(
                onTap: hasValidTitle ? _submit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasValidTitle ? const Color(0xFF4F75FF) : const Color(0xFFA0ABC0).withValues(alpha: 0.6),
                    boxShadow: hasValidTitle
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4F75FF).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.navigation_rounded,
                      color: hasValidTitle ? Colors.white : Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _CategoryFilterTab({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? const Color(0xFF1E293B))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}