import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypulse/core/database/database_provider.dart';
import 'package:daypulse/features/categories/models/category_model.dart';
import 'package:daypulse/features/categories/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (db) => CategoryRepository(db),
    loading: () => throw UnimplementedError('Database is loading'),
    error: (e, st) => throw Exception('Database error: $e'),
  );
});

final categoriesNotifierProvider = StateNotifierProvider<CategoriesNotifier, AsyncValue<List<CategoryModel>>>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (db) => CategoriesNotifier(CategoryRepository(db)),
    loading: () => CategoriesNotifier(null, initialLoading: true),
    error: (e, st) => CategoriesNotifier(null, initialError: e),
  );
});

class CategoriesNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final CategoryRepository? _repository;

  CategoriesNotifier(this._repository, {bool initialLoading = false, Object? initialError})
      : super(initialLoading
            ? const AsyncValue.loading()
            : initialError != null
                ? AsyncValue.error(initialError, StackTrace.current)
                : const AsyncValue.loading()) {
    if (_repository != null) {
      loadCategories();
    }
  }

  Future<void> loadCategories() async {
    if (_repository == null) return;
    state = const AsyncValue.loading();
    try {
      final categories = await _repository.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    if (_repository == null) return;
    try {
      await _repository.insertCategory(category);
      await loadCategories();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    if (_repository == null) return;
    try {
      await _repository.updateCategory(category);
      await loadCategories();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCategory(String categoryId, {String? reassignToCategoryId}) async {
    if (_repository == null) return;
    try {
      await _repository.deleteCategory(categoryId, reassignToCategoryId: reassignToCategoryId);
      await loadCategories();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<int> getTaskCountForCategory(String categoryId) async {
    if (_repository == null) return 0;
    return await _repository.getTaskCountForCategory(categoryId);
  }
}

final categoryByIdProvider = Provider.family<CategoryModel?, String?>((ref, categoryId) {
  if (categoryId == null) return null;
  final categoriesAsync = ref.watch(categoriesNotifierProvider);
  return categoriesAsync.when(
    data: (categories) {
      try {
        return categories.firstWhere((c) => c.id == categoryId);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});