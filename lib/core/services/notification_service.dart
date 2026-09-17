import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );

      // Request permission on Android 13+ (API 33+)
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        await androidImpl?.requestExactAlarmsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Initialization error (safe fallback): $e');
    }
  }

  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'fitness_streaks_achievements',
        'Streaks & Achievements',
        channelDescription:
            'Notifications for daily fitness streaks and milestone achievements',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('[NotificationService] Show notification error (safe fallback): $e');
    }
  }

  /// Automatically schedules a recurring notification sent to clients every day at 12:00 PM.
  /// Works even when the app is killed or not running in the background.
  Future<void> scheduleDailyDietReminder() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'fitness_daily_diet_reminders',
        'Daily Diet Reminders',
        channelDescription:
            'Automatic 12:00 PM reminder to complete daily fitness diet goals',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      // Compute target 12:00 PM today or tomorrow
      final now = DateTime.now();
      var scheduledDateTime = DateTime(now.year, now.month, now.day, 12, 0, 0);
      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }
      final durationUntil12pm = scheduledDateTime.difference(now);

      final tzNow = tz.TZDateTime.now(tz.local);
      final scheduledDate = tzNow.add(durationUntil12pm);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        1200, // Fixed ID for daily 12 PM diet notification
        '🥗 Daily Diet Reminder',
        'Do not forget to complete your daily fitness diet goals!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('[NotificationService] Daily 12 PM diet reminder scheduled for: $scheduledDate');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling daily diet reminder: $e');
    }
  }
}
