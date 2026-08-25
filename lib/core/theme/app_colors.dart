import 'package:flutter/material.dart';

class AppColors {
  // Brand / Soft Pastel Blue colors
  static const Color primary = Color(0xFF4F75FF); // Vibrant Soft Blue
  static const Color primaryLight = Color(0xFF7A9AFF);
  static const Color primaryDark = Color(0xFF3858D6);
  static const Color secondary = Color(0xFF38BDF8); // Sky Blue
  static const Color accent = Color(0xFF6366F1); // Indigo
  static const Color bannerGradientStart = Color(0xFF6B93F6);
  static const Color bannerGradientEnd = Color(0xFF8FB1FF);

  // Status & Priority Colors
  static const Color priorityHigh = Color(0xFFEF4444); // Red
  static const Color priorityMedium = Color(0xFFF59E0B); // Amber
  static const Color priorityLow = Color(0xFF10B981); // Emerald

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Light Theme Surfaces (Clean Soft Blue-Grey)
  static const Color lightBackground = Color(0xFFF4F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F4F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);

  // Dark Theme Surfaces (Sleek Slate / Dark Obsidian)
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF131A29);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF2D3748);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  // Category Default Palette
  static const List<Color> categoryPalette = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEF4444), // Rose
    Color(0xFF3B82F6), // Blue
    Color(0xFF14B8A6), // Teal
    Color(0xFF64748B), // Slate
  ];
}