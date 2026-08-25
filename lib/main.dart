import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypulse/core/database/app_database.dart';
import 'package:daypulse/core/notifications/notification_service.dart';
import 'package:daypulse/core/preferences/preferences_service.dart';
import 'package:daypulse/core/routing/app_router.dart';
import 'package:daypulse/core/theme/app_theme.dart';
import 'package:daypulse/core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop FFI initialization for SQLite
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();
  final prefsService = PreferencesService(sharedPrefs);

  // Initialize Database
  await AppDatabase.instance;

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefsService),
      ],
      child: const DayPulseApp(),
    ),
  );
}

class DayPulseApp extends ConsumerWidget {
  const DayPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'DayPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}