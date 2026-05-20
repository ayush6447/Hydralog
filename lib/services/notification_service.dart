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

  // Waking hours window: 7 AM to 10 PM
  static const int _startHour = 7;
  static const int _endHour = 22;
  static const int _notificationCount = 12;

  /// Whether initialization completed successfully.
  static bool _initialized = false;

  /// Initialize the notification subsystem. Returns true on success.
  static Future<bool> initialize() async {
    try {
      // ── 1. Request runtime permission (Android 13+) ──────────────
      final permStatus = await _requestNotificationPermission();
      debugPrint('[NotificationService] Permission status: $permStatus');
      if (permStatus.isDenied || permStatus.isPermanentlyDenied) {
        debugPrint('[NotificationService] ⚠ Notification permission denied');
        // Continue anyway — user may grant later in settings
      }

      // ── 2. Time zones ────────────────────────────────────────────
      tzdata.initializeTimeZones();
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.toString();
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('[NotificationService] Timezone: $timeZoneName');
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
        debugPrint('[NotificationService] Timezone fallback → UTC');
      }

      // ── 3. Android notification channel ──────────────────────────
      const androidChannel = AndroidNotificationChannel(
        'hydration_channel',
        'Hydration Reminders',
        description: 'Reminders to drink water throughout the day',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      const instantChannel = AndroidNotificationChannel(
        'instant_channel',
        'Instant Notifications',
        description: 'Used for instant app testing',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
        await androidPlugin.createNotificationChannel(instantChannel);
        debugPrint('[NotificationService] Android channels created ✓');
      }

      // ── 4. Plugin initialization ────────────────────────────────
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);

      final didInit = await _notificationsPlugin.initialize(initSettings);
      debugPrint('[NotificationService] Plugin initialized: $didInit');

      _initialized = true;
      return true;
    } catch (e, st) {
      debugPrint('[NotificationService] ❌ Initialization FAILED: $e');
      debugPrint('$st');
      return false;
    }
  }

  static Future<PermissionStatus> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      return await Permission.notification.request();
    }
    return status;
  }

  /// Returns current notification permission status for diagnostic display.
  static Future<String> getPermissionStatus() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return 'Granted ✓';
    if (status.isDenied) return 'Denied (can be requested)';
    if (status.isPermanentlyDenied) return 'Permanently denied (open Settings)';
    if (status.isRestricted) return 'Restricted';
    return status.toString();
  }

  /// Schedule 12 daily hydration reminders spread across waking hours (7 AM – 10 PM).
  static Future<void> scheduleDailyReminders() async {
    if (!_initialized) {
      debugPrint('[NotificationService] ⚠ Skipping schedule — not initialized');
      return;
    }

    // Cancel previous scheduled reminders only (IDs 0–11)
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

      // If already past today, schedule for tomorrow
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
              channelDescription:
                  'Reminders to drink water throughout the day',
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
        scheduledCount++;
        debugPrint(
            '[NotificationService] Scheduled #$i → $scheduledTime');
      } catch (e) {
        debugPrint('[NotificationService] ❌ Failed to schedule #$i: $e');
      }
    }

    debugPrint(
        '[NotificationService] ✅ Scheduled $scheduledCount/$_notificationCount reminders');
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
    debugPrint('[NotificationService] All notifications cancelled');
  }

  /// List all pending scheduled notifications (useful for debugging).
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Sends a test notification instantly for debugging purposes.
  static Future<void> sendInstantNotification() async {
    // Ensure plugin is initialized even if scheduled init failed
    if (!_initialized) {
      debugPrint(
          '[NotificationService] ⚠ Not initialized, attempting init now…');
      await initialize();
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_channel',
        'Instant Notifications',
        channelDescription: 'Used for instant app testing',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      999,
      'FlowTrack ⚡',
      'Hydration test notification received successfully! Keep up the flow.',
      details,
    );
    debugPrint('[NotificationService] ✅ Instant notification sent');
  }
}
