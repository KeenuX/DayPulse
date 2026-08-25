import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:daypulse/core/theme/app_colors.dart';
import 'package:daypulse/features/calendar/providers/calendar_provider.dart';
import 'package:daypulse/features/tasks/presentation/widgets/quick_add_sheet.dart';

class NavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationShell({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMineTab = navigationShell.currentIndex == 3;

    return Scaffold(
      body: navigationShell,
      floatingActionButton: isMineTab
          ? null
          : FloatingActionButton(
              heroTag: 'app_nav_fab',
              backgroundColor: const Color(0xFF6495ED),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              onPressed: () {
                if (navigationShell.currentIndex == 2) {
                  final selectedDate = ref.read(selectedCalendarDateProvider);
                  QuickAddSheet.show(context, initialDate: selectedDate);
                } else {
                  QuickAddSheet.show(context);
                }
              },
              child: const Icon(Icons.add_rounded, size: 28),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.menu_rounded),
            selectedIcon: Icon(Icons.menu_rounded, color: AppColors.primary),
            label: 'Today',
          ),
          const NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded, color: AppColors.primary),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 22),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${DateTime.now().day}',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            selectedIcon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 22, color: AppColors.primary),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${DateTime.now().day}',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            label: 'Calendar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}