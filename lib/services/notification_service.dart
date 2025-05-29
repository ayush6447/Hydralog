import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request notification permission for Android 13+
    await _requestNotificationPermission();
    tzdata.initializeTimeZones();


    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  static Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied ||
        await Permission.notification.isPermanentlyDenied) {
      await Permission.notification.request();
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'hydration_channel',
      'Hydration Reminders',
      channelDescription: 'Reminds user to drink water',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  // Example: schedule random reminders (between 8 AM to 10 PM)
  static Future<void> scheduleRandomHydrationReminders(int count) async {
    final now = DateTime.now();
    final random = Random();

    for (int i = 0; i < count; i++) {
      final int hour = 8 + random.nextInt(14); // between 8 and 21
      final int minute = random.nextInt(60);
      final scheduledTime = tz.TZDateTime.local(now.year, now.month, now.day, hour, minute);

      await _notificationsPlugin.zonedSchedule(
        i,
        'Hydration Reminder 💧',
        'Time to drink some water!',
        scheduledTime.toUtc().subtract(Duration(hours: now.timeZoneOffset.inHours)),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_channel',
            'Hydration Reminders',
            channelDescription: 'Reminds user to drink water',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> scheduleRandomNotifications() async {
    await scheduleRandomHydrationReminders(5); // or however many you want
  }
  static Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      0,
      '💧 Time to Hydrate!',
      'This is a test reminder to drink water.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration_channel',
          'Hydration Reminders',
          channelDescription: 'Reminders to drink water throughout the day',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }


}
