import 'dart:io';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import '../models/health_data.dart';

class HealthService {
  static final Health _health = Health();

  static const _androidTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
  ];

  static const _iosTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
  ];

  /// Request permissions from HealthKit (iOS) or Health Connect (Android)
  static Future<bool> requestPermissions() async {
    final types = Platform.isIOS ? _iosTypes : _androidTypes;
    final permissions = types.map((_) => HealthDataAccess.READ).toList();
    try {
      return await _health.requestAuthorization(types,
          permissions: permissions);
    } catch (_) {
      return false;
    }
  }

  /// Fetch today's health data from the device
  static Future<HealthData> fetchToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = now;

    try {
      final types = Platform.isIOS ? _iosTypes : _androidTypes;
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );

      int steps = 0;
      double calories = 0;
      double sleepHours = 0;

      for (final p in points) {
        final val = (p.value as NumericHealthValue).numericValue.toDouble();
        switch (p.type) {
          case HealthDataType.STEPS:
            steps += val.toInt();
            break;
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            calories += val;
            break;
          case HealthDataType.SLEEP_ASLEEP:
            sleepHours += val / 60; // minutes → hours
            break;
          default:
            break;
        }
      }

      // Deduplicate steps (health package can return duplicates)
      final deduped = _health.removeDuplicates(points);
      steps = 0;
      calories = 0;
      sleepHours = 0;
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
            sleepHours += val / 60;
            break;
          default:
            break;
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
    } catch (_) {
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

  static String get todayKey =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());
}
