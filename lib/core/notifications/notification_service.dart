import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String channelId = 'task_reminders_channel_v3';
  static const String channelName = 'Task & Schedule Reminders';
  static const String channelDesc = 'High priority alerts for scheduled tasks and upcoming events';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Initialize timezones with fallback
    try {
      tz.initializeTimeZones();
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
        try {
          final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
          tz.setLocalLocation(tz.getLocation(currentTimeZone));
        } catch (tzError) {
          debugPrint('Local timezone detection fallback to UTC: $tzError');
          tz.setLocalLocation(tz.UTC);
        }
      }
    } catch (e) {
      debugPrint('Timezone initialization error: $e');
    }

    // 2. Platform settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped with payload: ${response.payload}');
        },
      );

      // 3. Android High-Priority Notification Channel
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        await androidPlugin?.createNotificationChannel(channel);
        await requestPermissions();
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Notification plugin init error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final notifGranted = await androidPlugin?.requestNotificationsPermission() ?? false;
        final exactGranted = await androidPlugin?.requestExactAlarmsPermission() ?? false;
        debugPrint('Notification permission: $notifGranted, Exact alarm: $exactGranted');
        return notifGranted || exactGranted;
      } else if (!kIsWeb && Platform.isIOS) {
        final iosPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  int _getSafeNotificationId(String taskId) {
    return (taskId.hashCode.abs() % 2147483647);
  }

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
  }) async {
    if (!_isInitialized) await initialize();
    if (scheduledDateTime.isBefore(DateTime.now())) {
      debugPrint('Skipping past reminder for $title at $scheduledDateTime');
      return;
    }

    final int notificationId = _getSafeNotificationId(taskId);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      ticker: 'Task Reminder',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tz.TZDateTime tzScheduled = tz.TZDateTime.from(scheduledDateTime, tz.local);

    try {
      // First attempt exact schedule (works with SCHEDULE_EXACT_ALARM)
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduled,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: taskId,
      );
      debugPrint('Successfully scheduled exact notification $notificationId for $scheduledDateTime');
    } catch (e) {
      debugPrint('Exact schedule failed ($e), falling back to inexact schedule');
      try {
        await _notificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          tzScheduled,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: taskId,
        );
        debugPrint('Successfully scheduled inexact notification $notificationId for $scheduledDateTime');
      } catch (fallbackError) {
        debugPrint('Failed to schedule notification completely: $fallbackError');
      }
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    if (!_isInitialized) await initialize();
    try {
      await _notificationsPlugin.cancel(_getSafeNotificationId(taskId));
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  Future<void> cancelAllReminders() async {
    if (!_isInitialized) await initialize();
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    try {
      await _notificationsPlugin.show(
        (DateTime.now().millisecondsSinceEpoch.abs() % 2147483647),
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Failed to show instant notification: $e');
    }
  }
}