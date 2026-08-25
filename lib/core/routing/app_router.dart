import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:daypulse/features/calendar/presentation/calendar_screen.dart';
import 'package:daypulse/features/categories/presentation/categories_screen.dart';
import 'package:daypulse/features/onboarding/presentation/onboarding_screen.dart';
import 'package:daypulse/features/planner/presentation/tomorrow_planner_screen.dart';
import 'package:daypulse/features/progress/presentation/progress_screen.dart';
import 'package:daypulse/features/settings/presentation/settings_screen.dart';
import 'package:daypulse/features/tasks/presentation/create_edit_task_screen.dart';
import 'package:daypulse/features/tasks/presentation/task_detail_screen.dart';
import 'package:daypulse/features/tasks/presentation/tasks_screen.dart';
import 'package:daypulse/features/today/presentation/today_screen.dart';
import 'package:daypulse/core/theme/theme_provider.dart';
import 'package:daypulse/core/routing/app_routes.dart';
import 'package:daypulse/core/routing/navigation_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final hasCompletedOnboarding = prefs.hasCompletedOnboarding;

  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final todayNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'today');
  final tasksNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'tasks');
  final progressNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'progress');
  final settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: hasCompletedOnboarding ? AppRoutes.today : AppRoutes.onboarding,
    routes: [
      // Stateful Nested Shell Route for Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Today
          StatefulShellBranch(
            navigatorKey: todayNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.today,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TodayScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Tasks
          StatefulShellBranch(
            navigatorKey: tasksNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.tasks,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TasksScreen(),
                ),
              ),
            ],
          ),

          // Branch 2: Calendar
          StatefulShellBranch(
            navigatorKey: progressNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CalendarScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Mine (Progress & Profile)
          StatefulShellBranch(
            navigatorKey: settingsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProgressScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Top-Level Routes (Full screen pages with back navigation)
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${AppRoutes.taskDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TaskDetailScreen(taskId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.createTask,
        builder: (context, state) => const CreateEditTaskScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${AppRoutes.editTask}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CreateEditTaskScreen(taskId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.categories,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.planTomorrow,
        builder: (context, state) => const TomorrowPlannerScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});