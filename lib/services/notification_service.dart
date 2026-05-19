import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Waking hours window: 7 AM to 10 PM
  static const int _startHour = 7;
  static const int _endHour = 22;

  static Future<void> initialize() async {
    await _requestNotificationPermission();

    tzdata.initializeTimeZones();

    // Use device local timezone instead of hardcoded India timezone
    final String localTimeZoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(localTimeZoneName));
    } catch (_) {
      // Fallback to UTC if timezone name can't be resolved
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(initSettings);
  }

  static Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.notification.request();
    }
  }

  /// Schedule 8 daily hydration reminders spread across waking hours (7 AM – 10 PM)
  static Future<void> scheduleDailyRandomReminders() async {
    final now = tz.TZDateTime.now(tz.local);
    final random = Random();

    const int notificationCount = 8;
    final int totalMinutes = (_endHour - _startHour) * 60;
    final int windowPerSlot = totalMinutes ~/ notificationCount;

    for (int i = 0; i < notificationCount; i++) {
      // Each reminder gets its own time slot to spread them evenly
      final int slotStart = _startHour * 60 + i * windowPerSlot;
      final int randomOffset = random.nextInt(windowPerSlot);
      final int totalMinute = slotStart + randomOffset;

      final int hour = totalMinute ~/ 60;
      final int minute = totalMinute % 60;

      var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      // If already past today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        i,
        '💧 Time to Hydrate!',
        _randomMessage(random),
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
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static String _randomMessage(Random random) {
    const messages = [
      'Your body is 60% water — keep it topped up! 💧',
      'Small sips, big difference. Drink up! 🥤',
      'Hydration check! How\'s your water intake?',
      'Stay focused, stay hydrated. Time for a glass!',
      'Water break! Your future self will thank you.',
      'Feeling tired? Water might be the fix 💧',
      'Don\'t forget to drink water today!',
      'Your plants need water. So do you 🌱',
    ];
    return messages[random.nextInt(messages.length)];
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}

