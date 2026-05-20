import 'dart:io';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import '../models/health_data.dart';

class HealthService {
  static final Health _health = Health();
  static bool _configured = false; // Bug 4 fix: configure only once

  // Bug 2 fix: correct types per platform
  static const _androidTypes = [
    HealthDataType.TOTAL_CALORIES_BURNED, // was ACTIVE_ENERGY_BURNED — wrong on Android
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_SESSION, // Samsung writes SLEEP_SESSION, not just SLEEP_ASLEEP
  ];

  static const _iosTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
  ];

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    if (Platform.isAndroid) {
      _health.configure();
    }
    _configured = true;
  }

  /// Request permissions from HealthKit (iOS) or Health Connect (Android)
  static Future<bool> requestPermissions() async {
    await _ensureConfigured();
    final types = Platform.isIOS ? _iosTypes : _androidTypes;
    final permissions = types.map((_) => HealthDataAccess.READ).toList();
    try {
      bool? hasPerms = await _health.hasPermissions(types, permissions: permissions);
      if (hasPerms == true) return true;
      return await _health.requestAuthorization(types, permissions: permissions);
    } catch (e) {
      print('Health permission error: $e');
      return false;
    }
  }

  /// Fetch today's health data from the device
  static Future<HealthData> fetchToday() async {
    await _ensureConfigured();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    try {
      int steps = 0;
      double calories = 0;
      double sleepHours = 0;

      if (Platform.isIOS) {
        // ── iOS: use getHealthDataFromTypes for everything ───────────
        final points = await _health.getHealthDataFromTypes(
          startTime: todayStart,
          endTime: now,
          types: _iosTypes,
        );
        final deduped = _health.removeDuplicates(points);
        for (final p in deduped) {
          final val = (p.value as NumericHealthValue).numericValue.toDouble();
          switch (p.type) {
            case HealthDataType.STEPS:
              steps += val.toInt();
              break;
            case HealthDataType.ACTIVE_ENERGY_BURNED:
              calories += val;
              break;
            case HealthDataType.SLEEP_ASLEEP:
              sleepHours += val / 60; // iOS returns minutes
              break;
            default:
              break;
          }
        }
      } else {
        // ── Android/Samsung: Bug 1 fix: use getTotalStepsInInterval ──
        // This returns a single authoritative total, same number Samsung Health shows.
        // getHealthDataFromTypes returns raw entries from EVERY source
        // (Samsung Health + Google Fit + sensor) and sums them = 2-3x inflated.
        try {
          final stepTotal = await _health.getTotalStepsInInterval(todayStart, now);
          steps = stepTotal ?? 0;
        } catch (_) {
          steps = 0;
        }

        // Bug 5 fix: sleep window = yesterday 6 PM → today noon
        // Night sleep starts yesterday, not at midnight today.
        final sleepStart = DateTime(now.year, now.month, now.day - 1, 18, 0);
        final sleepEnd = DateTime(now.year, now.month, now.day, 12, 0);

        final points = await _health.getHealthDataFromTypes(
          startTime: todayStart,
          endTime: now,
          types: [HealthDataType.TOTAL_CALORIES_BURNED],
        );
        final sleepPoints = await _health.getHealthDataFromTypes(
          startTime: sleepStart,
          endTime: sleepEnd,
          types: [HealthDataType.SLEEP_ASLEEP, HealthDataType.SLEEP_SESSION],
        );

        final deduped = _health.removeDuplicates(points);
        final sleepDeduped = _health.removeDuplicates(sleepPoints);

        for (final p in deduped) {
          final val = (p.value as NumericHealthValue).numericValue.toDouble();
          if (p.type == HealthDataType.TOTAL_CALORIES_BURNED) {
            calories += val;
          }
        }

        // Bug 2 fix: Health Connect returns sleep in minutes
        for (final p in sleepDeduped) {
          final val = (p.value as NumericHealthValue).numericValue.toDouble();
          if (p.type == HealthDataType.SLEEP_ASLEEP ||
              p.type == HealthDataType.SLEEP_SESSION) {
            sleepHours += val / 60; // minutes → hours
          }
        }
      }

      double screenTime = 0;
      if (Platform.isAndroid) {
        screenTime = await _fetchAndroidScreenTime();
      }

      return HealthData(
        steps: steps,
        caloriesBurned: calories,
        sleepHours: sleepHours,
        screenTimeHours: screenTime,
        deviceSource: Platform.isIOS ? 'iphone' : 'samsung',
      );
    } catch (e) {
      print('Health fetch error: $e');
      return const HealthData();
    }
  }

  /// Fetch screen time on Android via UsageStatsManager
  static Future<double> _fetchAndroidScreenTime() async {
    const channel = MethodChannel('com.example.hydralog/usage_stats');
    try {
      final minutes = await channel.invokeMethod<int>('getScreenTimeToday');
      return (minutes ?? 0) / 60.0;
    } catch (_) {
      return 0;
    }
  }

  static String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());
}
