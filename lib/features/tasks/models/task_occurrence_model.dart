class TaskOccurrenceModel {
  final String id;
  final String taskId;
  final String date; // YYYY-MM-DD
  final bool completed;
  final DateTime? completedAt;
  final bool isSkipped;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskOccurrenceModel({
    required this.id,
    required this.taskId,
    required this.date,
    this.completed = false,
    this.completedAt,
    this.isSkipped = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'date': date,
      'completed': completed ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'is_skipped': isSkipped ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TaskOccurrenceModel.fromMap(Map<String, dynamic> map) {
    return TaskOccurrenceModel(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      date: map['date'] as String,
      completed: (map['completed'] as int) == 1,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      isSkipped: (map['is_skipped'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  TaskOccurrenceModel copyWith({
    String? id,
    String? taskId,
    String? date,
    bool? completed,
    DateTime? completedAt,
    bool? isSkipped,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskOccurrenceModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      isSkipped: isSkipped ?? this.isSkipped,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
