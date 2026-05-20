import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _startHour = 7;   // 7 AM
  static const int _endHour = 22;    // 10 PM
  static const int _notificationCount = 12;
  static bool _initialized = false;

  static Future<bool> initialize() async {
    try {
      // 1. Request permission (Android 13+ / iOS)
      final permStatus = await _requestNotificationPermission();
      debugPrint('[Notifications] Permission: $permStatus');

      // 2. Timezone — use flutter_timezone for accurate device locale
      tzdata.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('[Notifications] Timezone: $timeZoneName');
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
        debugPrint('[Notifications] Timezone fallback → UTC');
      }

      // 3. Create Android notification channels BEFORE plugin init
      //    (channels must exist before any notification is shown)
      const hydrationChannel = AndroidNotificationChannel(
        'hydration_channel',
        'Hydration Reminders',
        description: 'Daily reminders to drink water',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      const instantChannel = AndroidNotificationChannel(
        'instant_channel',
        'Instant Notifications',
        description: 'Test and goal notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(hydrationChannel);
        await androidPlugin.createNotificationChannel(instantChannel);

        // Bug fix: Check SCHEDULE_EXACT_ALARM permission on Android 12+
        // Without this, zonedSchedule silently fails on most Samsung devices
        final exactAlarmGranted =
            await androidPlugin.requestExactAlarmsPermission();
        debugPrint('[Notifications] Exact alarm permission: $exactAlarmGranted');
      }

      // 4. Initialise the plugin
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _notificationsPlugin.initialize(initSettings);
      debugPrint('[Notifications] Plugin initialized ✓');

      _initialized = true;
      return true;
    } catch (e, st) {
      debugPrint('[Notifications] ❌ Init FAILED: $e\n$st');
      return false;
    }
  }

  static Future<PermissionStatus> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) return await Permission.notification.request();
    return status;
  }

  /// Cancel all stale reminders, then schedule fresh ones for the next 24h.
  /// Call this once at startup (after initialize()) and once per day at midnight.
  static Future<void> scheduleDailyReminders() async {
    if (!_initialized) {
      debugPrint('[Notifications] ⚠ Not initialized — skipping schedule');
      return;
    }

    // Cancel previous reminders (IDs 0–_notificationCount-1)
    for (int i = 0; i < _notificationCount; i++) {
      await _notificationsPlugin.cancel(i);
    }

    final now = tz.TZDateTime.now(tz.local);
    final random = Random();
    final int totalMinutes = (_endHour - _startHour) * 60;
    final int windowPerSlot = totalMinutes ~/ _notificationCount;

    int scheduledCount = 0;

    for (int i = 0; i < _notificationCount; i++) {
      final int slotStart = _startHour * 60 + i * windowPerSlot;
      final int randomOffset = random.nextInt(windowPerSlot);
      final int totalMinute = slotStart + randomOffset;

      final int hour = totalMinute ~/ 60;
      final int minute = totalMinute % 60;

      var scheduledTime =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      // If the slot already passed today, push to tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      try {
        await _notificationsPlugin.zonedSchedule(
          i,
          'FlowTrack 💧',
          _randomMessage(random),
          scheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'hydration_channel',
              'Hydration Reminders',
              channelDescription: 'Daily reminders to drink water',
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
          // Bug fix: matchDateTimeComponents was MISSING — without this,
          // the notification fires once and never repeats.
          // We don't use DateTimeComponents.time here because we reschedule
          // each day at startup with new random times instead, which is
          // more flexible than a fixed daily time.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
        );
        scheduledCount++;
        debugPrint('[Notifications] Scheduled #$i → $scheduledTime');
      } catch (e) {
        debugPrint('[Notifications] ❌ Failed #$i: $e');
      }
    }

    debugPrint(
        '[Notifications] ✅ $scheduledCount/$_notificationCount reminders scheduled');
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

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('[Notifications] All cancelled');
  }

  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  static Future<String> getPermissionStatus() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return 'Granted ✓';
    if (status.isDenied) return 'Denied (can be requested)';
    if (status.isPermanentlyDenied) return 'Permanently denied — open Settings';
    if (status.isRestricted) return 'Restricted';
    return status.toString();
  }

  static Future<void> sendInstantNotification() async {
    if (!_initialized) await initialize();
    await _notificationsPlugin.show(
      999,
      'FlowTrack ⚡',
      'Hydration test notification received! Keep up the flow.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_channel',
          'Instant Notifications',
          channelDescription: 'Test and goal notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    debugPrint('[Notifications] ✅ Instant notification sent');
  }
}
