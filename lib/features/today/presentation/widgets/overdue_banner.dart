import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/core/utilities/date_utils.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/presentation/widgets/reschedule_modal.dart';
import 'package:daypulse/features/tasks/providers/task_filter_provider.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';

class OverdueBanner extends ConsumerStatefulWidget {
  const OverdueBanner({super.key});

  @override
  ConsumerState<OverdueBanner> createState() => _OverdueBannerState();
}

class _OverdueBannerState extends ConsumerState<OverdueBanner> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final overdueTasks = ref.watch(overdueTasksProvider);

    if (overdueTasks.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1215) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          // Header Bar
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${overdueTasks.length} Overdue Task${overdueTasks.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      for (final t in overdueTasks) {
                        await ref.read(tasksNotifierProvider.notifier).moveOverdueTaskToToday(t.id);
                      }
                    },
                    child: const Text(
                      'Move All to Today',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible List of Overdue Items
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0x33EF4444)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: overdueTasks.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final task = overdueTasks[index];
                return _OverdueTaskItem(task: task);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _OverdueTaskItem extends ConsumerWidget {
  final TaskModel task;

  const _OverdueTaskItem({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Text(
                '${AppDateUtils.relativeDateLabel(task.scheduledDate)}'
                '${task.startTime != null ? ' · ${AppDateUtils.formatTimeStringTo12Hour(task.startTime)}' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Action Buttons: Complete, Move to Today, Reschedule, Delete
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            runSpacing: 4,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  ref.read(tasksNotifierProvider.notifier).toggleTaskCompletion(task.id, true);
                },
                icon: const Icon(Icons.check, size: 14, color: AppColors.success),
                label: const Text('Complete', style: TextStyle(fontSize: 12, color: AppColors.success)),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  ref.read(tasksNotifierProvider.notifier).moveOverdueTaskToToday(task.id);
                },
                icon: const Icon(Icons.today_rounded, size: 14),
                label: const Text('Move to Today', style: TextStyle(fontSize: 12)),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  RescheduleModal.show(context, task: task);
                },
                icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                label: const Text('Reschedule', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}