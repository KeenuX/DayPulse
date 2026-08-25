import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/features/categories/models/category_model.dart';
import 'package:daypulse/features/categories/providers/categories_provider.dart';

class CategoryEditorSheet extends ConsumerStatefulWidget {
  final CategoryModel? initialCategory;

  const CategoryEditorSheet({super.key, this.initialCategory});

  static Future<CategoryModel?> show(BuildContext context, {CategoryModel? category}) {
    return showModalBottomSheet<CategoryModel>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CategoryEditorSheet(initialCategory: category),
    );
  }

  @override
  ConsumerState<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<CategoryEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int _selectedColorValue;
  late int _selectedIconCode;

  final List<IconData> _availableIcons = [
    Icons.menu_book_rounded,
    Icons.code_rounded,
    Icons.work_rounded,
    Icons.fitness_center_rounded,
    Icons.home_rounded,
    Icons.rocket_launch_rounded,
    Icons.push_pin_rounded,
    Icons.music_note_rounded,
    Icons.brush_rounded,
    Icons.local_cafe_rounded,
    Icons.sports_esports_rounded,
    Icons.shopping_bag_rounded,
    Icons.health_and_safety_rounded,
    Icons.attach_money_rounded,
    Icons.travel_explore_rounded,
    Icons.school_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCategory?.name ?? '');
    _selectedColorValue = widget.initialCategory?.colorValue ?? AppColors.categoryPalette.first.toARGB32();
    _selectedIconCode = widget.initialCategory?.iconCode ?? Icons.folder_rounded.codePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.initialCategory != null;
    final category = CategoryModel(
      id: widget.initialCategory?.id ?? 'cat_${const Uuid().v4().substring(0, 8)}',
      name: _nameController.text.trim(),
      iconCode: _selectedIconCode,
      colorValue: _selectedColorValue,
      createdAt: widget.initialCategory?.createdAt ?? DateTime.now(),
    );

    if (isEdit) {
      await ref.read(categoriesNotifierProvider.notifier).updateCategory(category);
    } else {
      await ref.read(categoriesNotifierProvider.notifier).addCategory(category);
    }

    if (mounted) {
      Navigator.of(context).pop(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.initialCategory != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Edit Category' : 'Create Category',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              // Category Name
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Design, Reading, Language',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Color Selector
              Text('Color', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: AppColors.categoryPalette.map((color) {
                  final isSelected = _selectedColorValue == color.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorValue = color.toARGB32()),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Icon Selector
              Text('Icon', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: _availableIcons.map((icon) {
                  final isSelected = _selectedIconCode == icon.codePoint;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconCode = icon.codePoint),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColorValue).withValues(alpha: 0.2)
                            : (theme.brightness == Brightness.dark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Color(_selectedColorValue) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? Color(_selectedColorValue)
                            : (theme.brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[700]),
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isEdit ? 'Save Changes' : 'Create Category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}