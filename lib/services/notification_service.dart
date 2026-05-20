import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Waking hours window: 7 AM to 10 PM
  static const int _startHour = 7;
  static const int _endHour = 22;
  static const int _notificationCount = 12;

  static Future<void> initialize() async {
    await _requestNotificationPermission();

    tzdata.initializeTimeZones();

    // Use flutter_timezone for reliable IANA timezone name (e.g. "Asia/Kolkata")
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = timeZoneInfo.toString();
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
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

  /// Schedule 12 daily hydration reminders spread across waking hours (7 AM - 10 PM).
  /// These run until the daily goal is completed, at which point [cancelAllNotifications] should be called.
  static Future<void> scheduleDailyReminders() async {
    // Cancel any existing ones first
    await _notificationsPlugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final random = Random();

    final int totalMinutes = (_endHour - _startHour) * 60;
    final int windowPerSlot = totalMinutes ~/ _notificationCount;

    for (int i = 0; i < _notificationCount; i++) {
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
        'Hydration Reminder',
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
      );
    }
  }

  static String _randomMessage(Random random) {
    const messages = [
      'A glass of water now keeps fatigue away. You got this.',
      'Your body is working hard for you. Return the favour with some water.',
      'Small sips add up to big results. Take one now.',
      'Staying hydrated sharpens your focus. Pour yourself a glass.',
      'Water fuels every cell in your body. Keep the engine running.',
      'Dehydration slows you down. A quick drink puts you back on track.',
      'Think of water as liquid motivation. Time for a refill.',
      'The best investment in yourself today costs nothing. Drink water.',
      'Champions stay hydrated. You are no exception.',
      'Progress is built one glass at a time. Add another.',
      'Your mind works better when hydrated. Give it what it needs.',
      'Consistency wins. Another glass, another step toward your goal.',
      'Great things start with simple habits. Drink up.',
      'You are closer to your goal than you think. Keep sipping.',
      'Water is the simplest upgrade you can give yourself right now.',
    ];
    return messages[random.nextInt(messages.length)];
  }

  /// Call this when the user reaches their daily water goal to stop further reminders.
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
