# DayPulse — Comprehensive Implementation & Changelog Record (`WHAT_YOU_DID.md`)

This document provides a complete, exhaustive record of all architectural updates, feature implementations, bug fixes, visual redesigns, and stability hardening performed on the **DayPulse** Flutter application in `m:/AllMain/Prog/XYZ/`.

---

## Table of Contents
1. [Core Architecture & Database Upgrades](#1-core-architecture--database-upgrades)
2. [Hierarchical Subtasks & Task Creator Panel](#2-hierarchical-subtasks--task-creator-panel)
3. [Custom Category Management & Palette Engine](#3-custom-category-management--palette-engine)
4. [App Branding & Adaptive Icon Pipeline](#4-app-branding--adaptive-icon-pipeline)
5. [Navigation & Single Global Floating Action Button (FAB)](#5-navigation--single-global-floating-action-button-fab)
6. ["Me" Analytics Dashboard & Annual Heatmap (53 Weeks)](#6-me-analytics-dashboard--annual-heatmap-53-weeks)
7. [Zero-Bloat Recurring Tasks Engine](#7-zero-bloat-recurring-tasks-engine)
8. [Streak System Audit & Hardening](#8-streak-system-audit--hardening)
9. [Focus Table & Dynamic Weekly Analytics](#9-focus-table--dynamic-weekly-analytics)
10. [Calendar Section Remake & 7-Column Grid](#10-calendar-section-remake--7-column-grid)
11. [Slide Action Gesture Fix & Element State Decoupling](#11-slide-action-gesture-fix--element-state-decoupling)
12. [Task Start Notification & High-Priority Alert Engine](#12-task-start-notification--high-priority-alert-engine)
13. [Security, Memory Leak & Crash Prevention Audit](#13-security-memory-leak--crash-prevention-audit)
14. [Automated Testing & Production Builds](#14-automated-testing--production-builds)

---

## 1. Core Architecture & Database Upgrades
- **Database Versioning (`AppDatabase.dart`)**:
  - Upgraded schema version to **v3** with automatic SQLite migrations for existing user installs.
  - Added new table schema `task_occurrences` (`id`, `task_id`, `date`, `completed`, `completed_at`, `is_skipped`, `created_at`, `updated_at`) with composite index on `(task_id, date)` for high-performance lookup.
  - Added recurrence columns to `tasks` table: `repeat_end_type`, `repeat_end_date`, `repeat_end_count`, `repeat_interval`, and `repeat_days_of_week`.
- **Repository Architecture**:
  - Maintained repository pattern in `TaskRepository` and `CategoryRepository` with strictly parameterized SQL statements (`whereArgs`) to prevent SQL injection vulnerabilities.

---

## 2. Hierarchical Subtasks & Task Creator Panel
- **New Task Subtask Creation Fix**:
  - Fixed an issue where subtasks entered during task creation were not saved to SQLite.
  - Added `addTaskWithSubtasks(TaskModel parent, List<String> subtaskTitles)` in `TasksNotifier` to atomically insert the parent task and all associated child subtasks.
  - Implemented auto-capture in `_saveTask` and `_submitTask` so any pending text typed in the subtask field is captured automatically even if the user didn't tap the `+` button before submitting.
- **Top-Level vs. Subtask Separation**:
  - Refactored task lists, query filters, pending task counts, and streak metrics to filter on `task.isTopLevel` (where `parentId == null`), ensuring subtasks do not inflate top-level pending counts on the **Me** or **Today** screens.
- **Hierarchical Completion Sync**:
  - Checking off all child subtasks marks the parent task completed.
  - Unchecking any child subtask re-opens the parent task.

---

## 3. Custom Category Management & Palette Engine
- **In-App Category Creation Sheet (`category_editor_sheet.dart`)**:
  - Added bottom sheet for creating and editing categories directly within the app.
  - Includes a curated grid of 16 modern category icons and 12 curated hex color swatches.
  - Integrated `+ Add Category` option directly into the category dropdown menu in `QuickAddSheet` and `CreateEditTaskScreen`.
- **Category Deletion Modal (`delete_category_dialog.dart`)**:
  - Fully working delete confirmation dialog allowing users to delete a category and reassign all associated tasks to "General" (uncategorized).
  - Wired into both the category management sheet and the calendar/task filter views.

---

## 4. App Branding & Adaptive Icon Pipeline
- **Vector-Clean App Icons**:
  - Processed and rescaled app launcher icons with optimal Android safe-zone padding (66% viewport rule) to prevent icon clipping across launchers.
  - Generated full Android mipmap asset suite (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) for standard and adaptive round icons (`ic_launcher.png`, `ic_launcher_round.png`).
- **Branding Consistency**:
  - Updated app display name to **DayPulse** in `AndroidManifest.xml` and `main.dart`.
  - Renamed the fourth navigation tab from "Mine" to "**Me**".

---

## 5. Navigation & Single Global Floating Action Button (FAB)
- **Eliminated Duplicate Add Buttons**:
  - Removed duplicate inner `Positioned` FAB from `MonthGridView` and screen subviews.
  - Standardized on a single, global Floating Action Button managed by `NavigationShell` using `FloatingActionButtonLocation.endFloat` (bottom right).
  - Configured the global FAB to automatically supply the currently selected calendar date when pressed on the **Calendar** tab.
  - Automatically hid the FAB when the user navigates to the **Me** analytics tab.

---

## 6. "Me" Analytics Dashboard & Annual Heatmap (53 Weeks)
- **Annual Heatmap 53-Week Grid (`annual_heatmap_card.dart`)**:
  - Expanded annual contribution grid to 53 full calendar weeks starting from the Sunday on or before Jan 1.
  - Added dynamic 12-month text headers (`Jan` - `Dec`) aligned with month start weeks.
  - Integrated auto-scroll to the current week upon loading.
  - Added interactive day inspector and touch tooltips showing date and completed task count.
- **Daily Completed Category Breakdown (`daily_completed_card.dart`)**:
  - Added hover and tap inspection for every weekday bar (Sun through Sat).
  - Displays dynamic category breakdown percentages and task counts with proportional category color bars.
- **General / Uncategorized Tasks in Charts (`completed_tasks_donut_card.dart`)**:
  - Tasks without a category (`categoryId == null`) are tracked under "General" with a slate palette (`#64748B`).
  - Included in donut chart segments, breakdown lists, and range filters (`In 7 days`, `In 30 days`, `In 90 days`, `All time`).
- **Pie Graph Optimization**:
  - Replaced synchronous multi-year date loops with instantaneous in-memory lookups for regular tasks and recurring occurrences, eliminating performance lag.

---

## 7. Zero-Bloat Recurring Tasks Engine
- **Dynamic Occurrence Synthesis (`tasks_provider.dart` & `task_model.dart`)**:
  - Recurring tasks are stored as single template rows on `TaskModel` rather than pre-generating hundreds of future tasks in SQLite.
  - `getTasksForDate(DateTime)` dynamically evaluates `task.isOccurringOnDate(date)` and attaches completion state on demand across **Today**, **Tomorrow Planner**, **Calendar**, and **Analytics**.
- **Supported Recurrence Rules (`repeat_rule.dart`)**:
  - `No Repeat`
  - `Daily` (every N days)
  - `Weekdays` (Monday through Friday)
  - `Weekly` (custom weekday selection e.g. Mon, Wed, Fri)
  - `Monthly` (same day of month)
  - `Custom` (every N days/weeks/months)
- **End Conditions (`RecurrenceEndType`)**:
  - `Never` (indefinite repetition)
  - `On Date` (cutoff date picker)
  - `After Occurrences` (counter e.g. 5, 10, 30 occurrences)
- **Per-Occurrence Tracking (`task_occurrences` table)**:
  - Completing or skipping an occurrence on a specific date updates only that date's record without altering other days.

---

## 8. Streak System Audit & Hardening
- **Streak Calculation Engine (`productivity_calculator.dart`)**:
  - **Single Day Increment**: Multiple task completions on the same day only yield a single streak point for that calendar date (preventing streak inflation).
  - **Accurate Recurring Task Integration**: Recurring tasks occurring on historical dates are included in daily requirement percentages.
  - **Missed Day Resets**: Missing a required day (where tasks were planned and completed < threshold) breaks the active streak.
  - **Rest Day Handling**: Days with zero planned tasks do not break active streaks.
  - **Historical Persistence**: Streaks are calculated from persisted database tasks and occurrences across app restarts.

---

## 9. Focus Table & Dynamic Weekly Analytics
- **Dynamic Weekly Focus Calculation (`focus_metrics_card.dart`)**:
  - Replaced static total focus time with dynamic weekday calculations for the selected week offset.
  - Added interactive vertical focus bars and day inspector cards displaying exact focus duration (`2h 30m focus (3 done)`).
  - Integrates duration minutes from both regular tasks and completed recurring occurrences.

---

## 10. Calendar Section Remake & 7-Column Grid
- **Modern Calendar UI (`month_grid_view.dart`)**:
  - Header: `◀ August 2026 ▶` with smooth month navigation, Filter button with active filter badge, View Mode switcher (Month, Week, Day), and More options (Jump to Today, Date Picker).
  - Weekday Header: `Sun  Mon  Tue  Wed  Thu  Fri  Sat`.
  - 7-Column Calendar Grid: Previous/next month trailing days in muted gray; selected day styled as a solid brand blue circular badge (`#6495ED`) with bold white text; task indicator dots below dates with scheduled tasks.
  - Selected Day Task List: Clean cards with left category color strip, title, checkbox, subtasks expander, and priority flag on the right.
  - 3D Desk Calendar illustration empty state when no tasks are scheduled for the selected day.

---

## 11. Slide Action Gesture Fix & Element State Decoupling
- **Resolved Slide Offset Ghosting Bug**:
  - Added `didUpdateWidget` in `TaskCard` and `_CalendarTaskItem` to reset `_showActions = false` whenever the widget is reused for a different task ID or date.
  - Reset `_showActions = false` immediately before executing Delete, Star, or Reschedule actions.
  - Keyed every `TaskCard` across all screens with unique `ValueKey('${task.id}_${task.date}')` to prevent Flutter element tree state reuse.

---

## 12. Task Start Notification & High-Priority Alert Engine
- **Notification Service Upgrades (`notification_service.dart`)**:
  - Registered Android notification channel `task_reminders_channel_v3` with `Importance.max`, audio alarm flags, vibration, and public lockscreen visibility.
  - Added runtime permission triggers for `POST_NOTIFICATIONS` and `SCHEDULE_EXACT_ALARM` on Android 13/14+.
  - Handled timezone initialization with fallback to `tz.UTC` on devices with custom timezone strings.
  - Added graceful fallback to `AndroidScheduleMode.inexactAllowWhileIdle` if exact alarm permissions are restricted by device battery saver.
- **Automatic Reminder Scheduling**:
  - Tasks created with a start time in `QuickAddSheet` or `CreateEditTaskScreen` automatically enable and schedule notifications.
  - Supports exact start alerts ("It's time to start [Task Title]!") and heads-up offsets (5m, 10m, 30m, 1h).
  - Recurring tasks automatically calculate and schedule notifications for upcoming occurrences across the next **14 days**.

---

## 13. Security, Memory Leak & Crash Prevention Audit
- **Lifecycle & Controller Disposal**:
  - Audited all stateful and consumer widgets (`TodayScreen`, `TasksScreen`, `TaskDetailScreen`, `CreateEditTaskScreen`, `CategoryEditorSheet`, `AnnualHeatmapCard`, `FocusMetricsCard`, etc.) to ensure all `TextEditingController`, `AnimationController`, and `ScrollController` instances are disposed in `dispose()`.
- **SQL Injection Prevention**:
  - Verified all SQLite operations across `TaskRepository` and `CategoryRepository` use parameterized queries (`whereArgs`).
- **Crash Prevention on MIUI / HyperOS**:
  - Wrapped timezone detection and background notification initialization in try-catch guards to eliminate startup crashes.

---

## 14. Automated Testing & Production Builds
- **Unit Test Suite (`test/unit_tests_test.dart`)**:
  - **23/23 Automated Unit Tests Passing**:
    - Natural Language Parser (3 tests)
    - Productivity Calculator & Streaks (2 tests)
    - Duration Formatter (1 test)
    - Model Serialization (2 tests)
    - Hierarchical Subtasks (7 tests)
    - Recurring Tasks & Streak Audit (8 tests)
- **Production APK**:
  - Built release APK with split ABI (`app-arm64-v8a-release.apk`).
  - Deployed and verified on physical Android device (`8LAIB6RCLJFMJNY9`).
