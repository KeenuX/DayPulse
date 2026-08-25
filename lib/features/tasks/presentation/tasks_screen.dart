import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/features/tasks/models/task_filter.dart';
import 'package:daypulse/features/tasks/providers/task_filter_provider.dart';
import 'package:daypulse/features/tasks/providers/tasks_provider.dart';
import 'package:daypulse/features/tasks/presentation/widgets/quick_add_sheet.dart';
import 'package:daypulse/features/tasks/presentation/widgets/task_card.dart';
import 'package:daypulse/features/tasks/presentation/widgets/task_filter_bar.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredTasks = ref.watch(filteredTasksProvider);
    final currentFilter = ref.watch(taskFilterProvider);
    final tasksAsync = ref.watch(tasksNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(tasksNotifierProvider.notifier).loadTasks(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks, descriptions, notes...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(taskFilterProvider.notifier).update(
                                    (s) => s.copyWith(searchQuery: ''),
                                  );
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (query) {
                    ref.read(taskFilterProvider.notifier).update(
                          (s) => s.copyWith(searchQuery: query),
                        );
                  },
                ),
                const SizedBox(height: 12),

                // Filter & Sort Bar
                const TaskFilterBar(),
              ],
            ),
          ),
          const Divider(height: 1),

          // Task List
          Expanded(
            child: tasksAsync.when(
              data: (_) {
                if (filteredTasks.isEmpty) {
                  return _buildEmptyState(theme, isDark, currentFilter);
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(tasksNotifierProvider.notifier).loadTasks(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filteredTasks.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final task = filteredTasks[index];
                      return TaskCard(
                        key: ValueKey('${task.id}_${task.date}'),
                        task: task,
                        showDate: true,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark, TaskFilter filter) {
    String message = 'No tasks found';
    String subtext = 'Create a task to get organized!';
    IconData icon = Icons.task_alt_rounded;

    if (filter.status == TaskStatusFilter.overdue) {
      message = 'No overdue tasks';
      subtext = 'You are completely caught up!';
      icon = Icons.celebration_rounded;
    } else if (filter.status == TaskStatusFilter.completed) {
      message = 'No completed tasks yet';
      subtext = 'Complete tasks to see them archived here.';
      icon = Icons.done_all_rounded;
    } else if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      message = 'No matching tasks';
      subtext = 'Try refining your search query or filters.';
      icon = Icons.search_off_rounded;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              subtext,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => QuickAddSheet.show(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}