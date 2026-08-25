import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/features/categories/models/category_model.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';

class DeleteCategoryDialog extends ConsumerStatefulWidget {
  final CategoryModel category;
  final int taskCount;

  const DeleteCategoryDialog({
    super.key,
    required this.category,
    required this.taskCount,
  });

  @override
  ConsumerState<DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends ConsumerState<DeleteCategoryDialog> {
  String? _selectedReassignCategoryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final otherCategories = (categoriesAsync.value ?? [])
        .where((c) => c.id != widget.category.id)
        .toList();

    return AlertDialog(
      title: Text('Delete "${widget.category.name}"?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.taskCount > 0) ...[
              Text(
                'This category currently has ${widget.taskCount} task(s). What would you like to do with them?',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedReassignCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Move tasks to...',
                  prefixIcon: Icon(Icons.swap_horiz_rounded),
                ),
                hint: const Text('Move to "Other" / General'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Uncategorized / None'),
                  ),
                  ...otherCategories.map(
                    (cat) => DropdownMenuItem<String>(
                      value: cat.id,
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 18, color: cat.color),
                          const SizedBox(width: 8),
                          Text(cat.name),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedReassignCategoryId = val;
                  });
                },
              ),
            ] else
              Text(
                'Are you sure you want to delete this category? This action cannot be undone.',
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            await ref.read(categoriesNotifierProvider.notifier).deleteCategory(
                  widget.category.id,
                  reassignToCategoryId: _selectedReassignCategoryId,
                );
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('Delete Category'),
        ),
      ],
    );
  }
}