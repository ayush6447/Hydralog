import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request notification permission (Android 13+)
    await _requestNotificationPermission();

    // Initialize timezone data
    tzdata.initializeTimeZones();

    // Set local timezone to India (Asia/Kolkata)
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);
  }

  static Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied ||
        await Permission.notification.isPermanentlyDenied) {
      await Permission.notification.request();
    }
  }


  /// Schedule 8-9 random daily hydration reminders at random times (00:00 - 23:59)
  static Future<void> scheduleDailyRandomReminders() async {
    final now = tz.TZDateTime.now(tz.local);
    final random = Random();

    // Random count between 8 and 9
    final int notificationCount = 8 + random.nextInt(2); // 8 or 9

    for (int i = 0; i < notificationCount; i++) {
      // Random hour between 0 and 23
      final int hour = random.nextInt(24);
      // Random minute between 0 and 59
      final int minute = random.nextInt(60);

      final scheduledTime =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      print('⏰ Scheduling daily notification $i for: $scheduledTime');

      await _notificationsPlugin.zonedSchedule(
        i,
        '💧 Time to Hydrate!',
        'Remember to drink water regularly.',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_channel',
            'Hydration Reminders',
            channelDescription: 'Reminders to drink water throughout the day',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily at same time
      );
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

}

