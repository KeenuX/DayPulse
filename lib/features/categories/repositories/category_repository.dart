import 'package:sqflite/sqflite.dart';
import 'package:daypulse/core/database/tables.dart';
import 'package:daypulse/features/categories/models/category_model.dart';

class CategoryRepository {
  final Database _db;

  CategoryRepository(this._db);

  Future<List<CategoryModel>> getAllCategories() async {
    final maps = await _db.query(
      DatabaseTables.categories,
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final maps = await _db.query(
      DatabaseTables.categories,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CategoryModel.fromMap(maps.first);
  }

  Future<void> insertCategory(CategoryModel category) async {
    await _db.insert(
      DatabaseTables.categories,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _db.update(
      DatabaseTables.categories,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> getTaskCountForCategory(String categoryId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseTables.tasks} WHERE category_id = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteCategory(String categoryId, {String? reassignToCategoryId}) async {
    await _db.transaction((txn) async {
      if (reassignToCategoryId != null) {
        await txn.update(
          DatabaseTables.tasks,
          {'category_id': reassignToCategoryId},
          where: 'category_id = ?',
          whereArgs: [categoryId],
        );
      } else {
        await txn.update(
          DatabaseTables.tasks,
          {'category_id': null},
          where: 'category_id = ?',
          whereArgs: [categoryId],
        );
      }

      await txn.delete(
        DatabaseTables.categories,
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    });
  }
}