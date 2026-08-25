import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/features/categories/models/category_model.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';
import 'package:daypulse/features/categories/presentation/category_editor_sheet.dart';
import 'package:daypulse/features/categories/presentation/widgets/delete_category_dialog.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Category',
            onPressed: () => CategoryEditorSheet.show(context),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No categories found', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => CategoryEditorSheet.show(context),
                    child: const Text('Create Category'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: categories.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (ctx, index) {
              final category = categories[index];
              return _CategoryListItem(category: category);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading categories: $e')),
      ),
    );
  }
}

class _CategoryListItem extends ConsumerWidget {
  final CategoryModel category;

  const _CategoryListItem({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(category.icon, color: category.color, size: 24),
        ),
        title: Text(
          category.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit',
              onPressed: () => CategoryEditorSheet.show(context, category: category),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 20, color: theme.colorScheme.error),
              tooltip: 'Delete',
              onPressed: () async {
                final taskCount = await ref
                    .read(categoriesNotifierProvider.notifier)
                    .getTaskCountForCategory(category.id);

                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => DeleteCategoryDialog(
                      category: category,
                      taskCount: taskCount,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}