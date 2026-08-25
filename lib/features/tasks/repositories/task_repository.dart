import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:daypulse/core/database/tables.dart';
import 'package:daypulse/features/tasks/models/task_model.dart';
import 'package:daypulse/features/tasks/models/task_occurrence_model.dart';

class TaskRepository {
  final Database _db;

  TaskRepository(this._db);

  Future<List<TaskModel>> getAllTasks() async {
    final maps = await _db.query(
      DatabaseTables.tasks,
      orderBy: 'date DESC, start_time ASC',
    );
    return maps.map((m) => TaskModel.fromMap(m)).toList();
  }

  Future<List<TaskModel>> getTasksForDate(String dateIso) async {
    final maps = await _db.query(
      DatabaseTables.tasks,
      where: 'date = ?',
      whereArgs: [dateIso],
      orderBy: 'start_time ASC, priority DESC, created_at ASC',
    );
    return maps.map((m) => TaskModel.fromMap(m)).toList();
  }

  Future<List<TaskModel>> getTasksForDateRange(String startDateIso, String endDateIso) async {
    final maps = await _db.query(
      DatabaseTables.tasks,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDateIso, endDateIso],
      orderBy: 'date ASC, start_time ASC',
    );
    return maps.map((m) => TaskModel.fromMap(m)).toList();
  }

  Future<List<TaskModel>> getOverdueTasks(String todayIso) async {
    // Tasks before today that are not completed
    final maps = await _db.query(
      DatabaseTables.tasks,
      where: 'date < ? AND completed = 0',
      whereArgs: [todayIso],
      orderBy: 'date DESC, start_time ASC',
    );
    return maps.map((m) => TaskModel.fromMap(m)).toList();
  }

  Future<TaskModel?> getTaskById(String id) async {
    final maps = await _db.query(
      DatabaseTables.tasks,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TaskModel.fromMap(maps.first);
  }

  Future<void> insertTask(TaskModel task) async {
    await _db.insert(
      DatabaseTables.tasks,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(TaskModel task) async {
    await _db.update(
      DatabaseTables.tasks,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<List<TaskModel>> getSubtasks(String parentId) async {
    final maps = await _db.query(
      DatabaseTables.tasks,
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => TaskModel.fromMap(m)).toList();
  }

  Future<void> deleteTask(String id) async {
    // Delete parent task and any child subtasks
    await _db.delete(
      DatabaseTables.tasks,
      where: 'id = ? OR parent_id = ?',
      whereArgs: [id, id],
    );
  }

  Future<void> toggleTaskCompletion(String id, bool completed) async {
    final now = completed ? DateTime.now().toIso8601String() : null;
    await _db.update(
      DatabaseTables.tasks,
      {
        'completed': completed ? 1 : 0,
        'completed_at': now,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Task Occurrences (Recurring completion tracking) ---

  Future<List<TaskOccurrenceModel>> getAllOccurrences() async {
    final maps = await _db.query(DatabaseTables.taskOccurrences);
    return maps.map((m) => TaskOccurrenceModel.fromMap(m)).toList();
  }

  Future<List<TaskOccurrenceModel>> getOccurrencesForDate(String dateIso) async {
    final maps = await _db.query(
      DatabaseTables.taskOccurrences,
      where: 'date = ?',
      whereArgs: [dateIso],
    );
    return maps.map((m) => TaskOccurrenceModel.fromMap(m)).toList();
  }

  Future<List<TaskOccurrenceModel>> getOccurrencesForTask(String taskId) async {
    final maps = await _db.query(
      DatabaseTables.taskOccurrences,
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    return maps.map((m) => TaskOccurrenceModel.fromMap(m)).toList();
  }

  Future<void> setOccurrenceCompletion(String taskId, String dateIso, bool completed) async {
    final occId = '${taskId}_$dateIso';
    final now = DateTime.now();
    final completedAt = completed ? now.toIso8601String() : null;

    await _db.insert(
      DatabaseTables.taskOccurrences,
      {
        'id': occId,
        'task_id': taskId,
        'date': dateIso,
        'completed': completed ? 1 : 0,
        'completed_at': completedAt,
        'is_skipped': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setOccurrenceSkipped(String taskId, String dateIso, bool isSkipped) async {
    final occId = '${taskId}_$dateIso';
    final now = DateTime.now();

    await _db.insert(
      DatabaseTables.taskOccurrences,
      {
        'id': occId,
        'task_id': taskId,
        'date': dateIso,
        'completed': 0,
        'completed_at': null,
        'is_skipped': isSkipped ? 1 : 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteOccurrencesForTask(String taskId) async {
    await _db.delete(
      DatabaseTables.taskOccurrences,
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> rescheduleTask(String id, String newDateIso, {String? newStartTime}) async {
    final updates = <String, dynamic>{
      'date': newDateIso,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (newStartTime != null) {
      updates['start_time'] = newStartTime;
    }
    await _db.update(
      DatabaseTables.tasks,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> batchInsertTasks(List<TaskModel> tasks) async {
    final batch = _db.batch();
    for (final task in tasks) {
      batch.insert(
        DatabaseTables.tasks,
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearAllData() async {
    await _db.transaction((txn) async {
      await txn.delete(DatabaseTables.tasks);
      await txn.delete(DatabaseTables.categories);
    });
  }

  Future<String> exportDataAsJson() async {
    final tasksMaps = await _db.query(DatabaseTables.tasks);
    final categoriesMaps = await _db.query(DatabaseTables.categories);

    final exportObject = {
      'app': 'DayPulse',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'categories': categoriesMaps,
      'tasks': tasksMaps,
    };

    return const JsonEncoder.withIndent('  ').convert(exportObject);
  }

  Future<int> importDataFromJson(String jsonString, {bool overwrite = false}) async {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid JSON format for DayPulse backup.');
    }

    final categoriesList = (decoded['categories'] as List<dynamic>?) ?? [];
    final tasksList = (decoded['tasks'] as List<dynamic>?) ?? [];

    await _db.transaction((txn) async {
      if (overwrite) {
        await txn.delete(DatabaseTables.tasks);
        await txn.delete(DatabaseTables.categories);
      }

      for (final item in categoriesList) {
        if (item is Map<String, dynamic>) {
          await txn.insert(
            DatabaseTables.categories,
            item,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      for (final item in tasksList) {
        if (item is Map<String, dynamic>) {
          await txn.insert(
            DatabaseTables.tasks,
            item,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    return tasksList.length;
  }
}