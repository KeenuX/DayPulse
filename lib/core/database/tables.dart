class DatabaseTables {
  static const String categories = 'categories';
  static const String tasks = 'tasks';
  static const String taskOccurrences = 'task_occurrences';

  static const String createCategoriesTable = '''
    CREATE TABLE $categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      icon_code INTEGER NOT NULL,
      color_value INTEGER NOT NULL,
      created_at TEXT NOT NULL
    );
  ''';

  static const String createTasksTable = '''
    CREATE TABLE $tasks (
      id TEXT PRIMARY KEY,
      parent_id TEXT,
      title TEXT NOT NULL,
      description TEXT,
      category_id TEXT,
      date TEXT NOT NULL,
      start_time TEXT,
      end_time TEXT,
      duration_minutes INTEGER,
      priority TEXT NOT NULL,
      completed INTEGER NOT NULL DEFAULT 0,
      completed_at TEXT,
      reminder_enabled INTEGER NOT NULL DEFAULT 0,
      reminder_time TEXT,
      repeat_rule TEXT,
      repeat_end_type TEXT,
      repeat_end_date TEXT,
      repeat_end_count INTEGER,
      repeat_interval INTEGER DEFAULT 1,
      repeat_days_of_week TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      notes TEXT,
      FOREIGN KEY (category_id) REFERENCES $categories(id) ON DELETE SET NULL,
      FOREIGN KEY (parent_id) REFERENCES $tasks(id) ON DELETE CASCADE
    );
  ''';

  static const String createTaskOccurrencesTable = '''
    CREATE TABLE $taskOccurrences (
      id TEXT PRIMARY KEY,
      task_id TEXT NOT NULL,
      date TEXT NOT NULL,
      completed INTEGER NOT NULL DEFAULT 0,
      completed_at TEXT,
      is_skipped INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (task_id) REFERENCES $tasks(id) ON DELETE CASCADE
    );
  ''';

  static const String createIndexTasksDate = '''
    CREATE INDEX idx_tasks_date ON $tasks(date);
  ''';

  static const String createIndexTasksCategory = '''
    CREATE INDEX idx_tasks_category ON $tasks(category_id);
  ''';

  static const String createIndexTasksCompleted = '''
    CREATE INDEX idx_tasks_completed ON $tasks(completed);
  ''';

  static const String createIndexTasksParentId = '''
    CREATE INDEX idx_tasks_parent_id ON $tasks(parent_id);
  ''';

  static const String createIndexOccurrencesTaskDate = '''
    CREATE INDEX idx_task_occurrences_task_date ON $taskOccurrences(task_id, date);
  ''';

  static const String createIndexOccurrencesDate = '''
    CREATE INDEX idx_task_occurrences_date ON $taskOccurrences(date);
  ''';
}