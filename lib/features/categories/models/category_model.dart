import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final int iconCode;
  final int colorValue;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.createdAt,
  });

  static final Map<int, IconData> _iconMap = {
    Icons.menu_book_rounded.codePoint: Icons.menu_book_rounded,
    Icons.code_rounded.codePoint: Icons.code_rounded,
    Icons.work_rounded.codePoint: Icons.work_rounded,
    Icons.fitness_center_rounded.codePoint: Icons.fitness_center_rounded,
    Icons.home_rounded.codePoint: Icons.home_rounded,
    Icons.rocket_launch_rounded.codePoint: Icons.rocket_launch_rounded,
    Icons.push_pin_rounded.codePoint: Icons.push_pin_rounded,
    Icons.music_note_rounded.codePoint: Icons.music_note_rounded,
    Icons.brush_rounded.codePoint: Icons.brush_rounded,
    Icons.local_cafe_rounded.codePoint: Icons.local_cafe_rounded,
    Icons.sports_esports_rounded.codePoint: Icons.sports_esports_rounded,
    Icons.shopping_bag_rounded.codePoint: Icons.shopping_bag_rounded,
    Icons.health_and_safety_rounded.codePoint: Icons.health_and_safety_rounded,
    Icons.attach_money_rounded.codePoint: Icons.attach_money_rounded,
    Icons.travel_explore_rounded.codePoint: Icons.travel_explore_rounded,
    Icons.school_rounded.codePoint: Icons.school_rounded,
    Icons.folder_rounded.codePoint: Icons.folder_rounded,
  };

  IconData get icon => _iconMap[iconCode] ?? Icons.folder_rounded;
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code': iconCode,
      'color_value': colorValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconCode: map['icon_code'] as int,
      colorValue: map['color_value'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    int? iconCode,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}