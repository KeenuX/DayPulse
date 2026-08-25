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

  static const String channelId = 'daypulse_reminders_channel_v4';
  static const String channelName = 'Task & Schedule Alarms';
  static const String channelDesc = 'High-priority sound and vibration alerts for scheduled tasks';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Initialize timezones with multi-tier fallback
    try {
      tz.initializeTimeZones();
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
        try {
          final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
          debugPrint('Detected system timezone string: $currentTimeZone');
          tz.setLocalLocation(tz.getLocation(currentTimeZone));
        } catch (tzError) {
          debugPrint('Timezone lookup for string failed ($tzError). Resolving by offset...');
          final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
          if (offsetMinutes == 330) {
            tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
          } else {
            // Match any location or fallback to UTC
            try {
              final loc = tz.timeZoneDatabase.locations.values.firstWhere(
                (l) => l.currentTimeZone.offset == offsetMinutes * 60 * 1000,
                orElse: () => tz.getLocation('UTC'),
              );
              tz.setLocalLocation(loc);
            } catch (_) {
              tz.setLocalLocation(tz.UTC);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Timezone initialization error: $e');
    }

    // 2. Android and iOS settings with valid PNG drawable icon
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

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
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // 3. Android High-Priority Alarm Channel
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
          enableLights: true,
        );

        await androidPlugin?.createNotificationChannel(channel);
        await requestPermissions();
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully with channel $channelId');
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
        debugPrint('Notification permission granted: $notifGranted, Exact alarm: $exactGranted');
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
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_notification',
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      ticker: 'Task Reminder',
      fullScreenIntent: false,
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

    // Explicit wall-clock scheduled time in local location
    final tz.TZDateTime tzScheduled = tz.TZDateTime(
      tz.local,
      scheduledDateTime.year,
      scheduledDateTime.month,
      scheduledDateTime.day,
      scheduledDateTime.hour,
      scheduledDateTime.minute,
      scheduledDateTime.second,
    );

    try {
      // 1. Try alarmClock mode for highest priority wakeup on Android
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduled,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: taskId,
      );
      debugPrint('Scheduled alarmClock notification $notificationId for $tzScheduled');
    } catch (e) {
      debugPrint('alarmClock mode failed ($e), trying exactAllowWhileIdle...');
      try {
        // 2. Try exactAllowWhileIdle mode
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
        debugPrint('Scheduled exactAllowWhileIdle notification $notificationId for $tzScheduled');
      } catch (e2) {
        debugPrint('exactAllowWhileIdle failed ($e2), falling back to inexactAllowWhileIdle...');
        try {
          // 3. Fallback to inexactAllowWhileIdle
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
          debugPrint('Scheduled inexact notification $notificationId for $tzScheduled');
        } catch (finalErr) {
          debugPrint('Fatal failure to schedule notification: $finalErr');
        }
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
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_notification',
      visibility: NotificationVisibility.public,
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
      debugPrint('Instant notification displayed successfully');
    } catch (e) {
      debugPrint('Failed to show instant notification: $e');
    }
  }
}