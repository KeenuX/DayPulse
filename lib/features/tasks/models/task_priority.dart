import 'package:flutter/material.dart';
import 'package:daypulse/core/theme/app_colors.dart';

enum TaskPriority {
  low('low', 'Low', AppColors.priorityLow, 1),
  medium('medium', 'Medium', AppColors.priorityMedium, 2),
  high('high', 'High', AppColors.priorityHigh, 3);

  final String value;
  final String label;
  final Color color;
  final int weight;

  const TaskPriority(this.value, this.label, this.color, this.weight);

  static TaskPriority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }
}