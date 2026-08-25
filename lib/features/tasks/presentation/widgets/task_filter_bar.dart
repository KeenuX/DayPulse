import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';
import 'package:daypulse/features/tasks/models/task_filter.dart';
import 'package:daypulse/features/tasks/models/task_priority.dart';
import 'package:daypulse/features/tasks/models/task_sort.dart';
import 'package:daypulse/features/tasks/providers/task_filter_provider.dart';

class TaskFilterBar extends ConsumerWidget {
  const TaskFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final sort = ref.watch(taskSortProvider);
    final categories = ref.watch(categoriesNotifierProvider).value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Status Filter Tabs (All, Active, Completed, Overdue)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TaskStatusFilter.values.map((status) {
              final isSelected = filter.status == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status.label),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(taskFilterProvider.notifier).update((state) => state.copyWith(status: status));
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // 2. Category, Priority Filter & Sort Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Category Filter Dropdown
              PopupMenuButton<String?>(
                tooltip: 'Filter Category',
                initialValue: filter.categoryId,
                onSelected: (catId) {
                  ref.read(taskFilterProvider.notifier).update(
                        (state) => state.copyWith(
                          categoryId: catId,
                          clearCategory: catId == null,
                        ),
                      );
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem<String?>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...categories.map((cat) {
                    return PopupMenuItem<String?>(
                      value: cat.id,
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 16, color: cat.color),
                          const SizedBox(width: 8),
                          Text(cat.name),
                        ],
                      ),
                    );
                  }),
                ],
                child: Chip(
                  avatar: const Icon(Icons.folder_outlined, size: 14),
                  label: Text(
                    filter.categoryId != null
                        ? (categories.firstWhere((c) => c.id == filter.categoryId, orElse: () => categories.first).name)
                        : 'All Categories',
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: filter.categoryId != null ? const Icon(Icons.close, size: 14) : null,
                  onDeleted: filter.categoryId != null
                      ? () {
                          ref.read(taskFilterProvider.notifier).update((s) => s.copyWith(clearCategory: true));
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 8),

              // Priority Filter Dropdown
              PopupMenuButton<TaskPriority?>(
                tooltip: 'Filter Priority',
                initialValue: filter.priority,
                onSelected: (pri) {
                  ref.read(taskFilterProvider.notifier).update(
                        (state) => state.copyWith(
                          priority: pri,
                          clearPriority: pri == null,
                        ),
                      );
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem<TaskPriority?>(
                    value: null,
                    child: Text('All Priorities'),
                  ),
                  ...TaskPriority.values.map((p) {
                    return PopupMenuItem<TaskPriority?>(
                      value: p,
                      child: Row(
                        children: [
                          Icon(Icons.flag_rounded, size: 16, color: p.color),
                          const SizedBox(width: 8),
                          Text(p.label),
                        ],
                      ),
                    );
                  }),
                ],
                child: Chip(
                  avatar: const Icon(Icons.flag_outlined, size: 14),
                  label: Text(
                    filter.priority != null ? filter.priority!.label : 'All Priorities',
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: filter.priority != null ? const Icon(Icons.close, size: 14) : null,
                  onDeleted: filter.priority != null
                      ? () {
                          ref.read(taskFilterProvider.notifier).update((s) => s.copyWith(clearPriority: true));
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 8),

              // Sort Dropdown
              PopupMenuButton<TaskSortOption>(
                tooltip: 'Sort Tasks',
                initialValue: sort,
                onSelected: (newSort) {
                  ref.read(taskSortProvider.notifier).state = newSort;
                },
                child: Chip(
                  avatar: const Icon(Icons.sort_rounded, size: 14),
                  label: Text('Sort: ${sort.label}', style: const TextStyle(fontSize: 12)),
                ),
                itemBuilder: (ctx) => TaskSortOption.values.map((s) {
                  return PopupMenuItem(
                    value: s,
                    child: Text(s.label),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}