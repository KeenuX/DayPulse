import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypulse/core/database/tables.dart';

class AppDatabase {
  static const String _dbName = 'daypulse.db';
  static const int _dbVersion = 3;

  static Database? _database;

  static Future<Database> get instance async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // If running on desktop (Windows/Linux/macOS) in debug or tests, initialize FFI
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = _dbName;
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, _dbName);
    }

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute(DatabaseTables.createCategoriesTable);
    await db.execute(DatabaseTables.createTasksTable);
    await db.execute(DatabaseTables.createTaskOccurrencesTable);
    await db.execute(DatabaseTables.createIndexTasksDate);
    await db.execute(DatabaseTables.createIndexTasksCategory);
    await db.execute(DatabaseTables.createIndexTasksCompleted);
    await db.execute(DatabaseTables.createIndexTasksParentId);
    await db.execute(DatabaseTables.createIndexOccurrencesTaskDate);
    await db.execute(DatabaseTables.createIndexOccurrencesDate);

    // Seed default categories
    await _seedDefaultCategories(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE ${DatabaseTables.tasks} ADD COLUMN parent_id TEXT;');
        await db.execute(DatabaseTables.createIndexTasksParentId);
      } catch (e) {
        debugPrint('Database migration v2 error: $e');
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute(DatabaseTables.createTaskOccurrencesTable);
        await db.execute(DatabaseTables.createIndexOccurrencesTaskDate);
        await db.execute(DatabaseTables.createIndexOccurrencesDate);
        await db.execute('ALTER TABLE ${DatabaseTables.tasks} ADD COLUMN repeat_end_type TEXT;');
        await db.execute('ALTER TABLE ${DatabaseTables.tasks} ADD COLUMN repeat_end_date TEXT;');
        await db.execute('ALTER TABLE ${DatabaseTables.tasks} ADD COLUMN repeat_end_count INTEGER;');
        await db.execute('ALTER TABLE ${DatabaseTables.tasks} ADD COLUMN repeat_interval INTEGER DEFAULT 1;');
        await db.execute('ALTER TABLE ${DatabaseTables.tasks} ADD COLUMN repeat_days_of_week TEXT;');
      } catch (e) {
        debugPrint('Database migration v3 error: $e');
      }
    }
  }

  static Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaultCategories = [
      {
        'id': 'cat_study',
        'name': 'Study',
        'icon_code': Icons.menu_book_rounded.codePoint,
        'color_value': 0xFF4F46E5,
        'created_at': now,
      },
      {
        'id': 'cat_coding',
        'name': 'Coding',
        'icon_code': Icons.code_rounded.codePoint,
        'color_value': 0xFF10B981,
        'created_at': now,
      },
      {
        'id': 'cat_work',
        'name': 'Work',
        'icon_code': Icons.work_rounded.codePoint,
        'color_value': 0xFF6366F1,
        'created_at': now,
      },
      {
        'id': 'cat_fitness',
        'name': 'Fitness',
        'icon_code': Icons.fitness_center_rounded.codePoint,
        'color_value': 0xFFF59E0B,
        'created_at': now,
      },
      {
        'id': 'cat_personal',
        'name': 'Personal',
        'icon_code': Icons.home_rounded.codePoint,
        'color_value': 0xFFEC4899,
        'created_at': now,
      },
      {
        'id': 'cat_projects',
        'name': 'Projects',
        'icon_code': Icons.rocket_launch_rounded.codePoint,
        'color_value': 0xFF8B5CF6,
        'created_at': now,
      },
      {
        'id': 'cat_other',
        'name': 'Other',
        'icon_code': Icons.push_pin_rounded.codePoint,
        'color_value': 0xFF64748B,
        'created_at': now,
      },
    ];

    final batch = db.batch();
    for (final cat in defaultCategories) {
      batch.insert(DatabaseTables.categories, cat, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }
}