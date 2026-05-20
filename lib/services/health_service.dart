import 'dart:io';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import '../models/health_data.dart';

class HealthService {
  static final Health _health = Health();
  static bool _configured = false;

  static const _androidTypes = [
    HealthDataType.STEPS,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
  ];

  static const _iosTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
  ];

  static void _ensureConfigured() {
    if (Platform.isAndroid && !_configured) {
      _health.configure();
      _configured = true;
    }
  }

  /// Request permissions from HealthKit (iOS) or Health Connect (Android)
  static Future<bool> requestPermissions() async {
    final types = Platform.isIOS ? _iosTypes : _androidTypes;
    final permissions = types.map((_) => HealthDataAccess.READ).toList();
    try {
      _ensureConfigured();
      bool? hasPerms = await _health.hasPermissions(types, permissions: permissions);
      if (hasPerms == true) return true;
      
      return await _health.requestAuthorization(types, permissions: permissions);
    } catch (e) {
      print("Health permission error: $e");
      return false;
    }
  }

  /// Fetch today's health data from the device
  static Future<HealthData> fetchToday() async {
    final now = DateTime.now();
    // For steps & calories: today midnight to now
    final startToday = DateTime(now.year, now.month, now.day);
    // For sleep: yesterday 12 PM to today 12 PM (a full 24 hours to capture split sessions)
    final startSleep = startToday.subtract(const Duration(hours: 12));

    try {
      _ensureConfigured();

      final types = Platform.isIOS ? _iosTypes : _androidTypes;
      final points = await _health.getHealthDataFromTypes(
        startTime: startSleep, // use wider window to catch sleep
        endTime: now,
        types: types,
      );

      print('DEBUG: Fetched ${points.length} points from Health Connect');
      
      int steps = 0;
      double calories = 0;
      double sleepHours = 0;
      Map<String, int> stepsBySource = {};

      final deduped = _health.removeDuplicates(points);

      for (final p in deduped) {
        if (p.type == HealthDataType.STEPS) {
          if (p.dateFrom.isAfter(startToday) || p.dateFrom.isAtSameMomentAs(startToday)) {
            final val = (p.value as NumericHealthValue).numericValue.toInt();
            stepsBySource[p.sourceName] = (stepsBySource[p.sourceName] ?? 0) + val;
          }
        }
        else if (p.type == HealthDataType.TOTAL_CALORIES_BURNED || 
                 p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          if (p.dateFrom.isAfter(startToday) || p.dateFrom.isAtSameMomentAs(startToday)) {
            final val = (p.value as NumericHealthValue).numericValue.toDouble();
            calories += val;
          }
        }
        else if (p.type == HealthDataType.SLEEP_SESSION || p.type == HealthDataType.SLEEP_ASLEEP) {
          final val = (p.value as NumericHealthValue).numericValue.toDouble();
          sleepHours += val / 60.0;
        }
      }

      // To avoid double-counting overlapping intervals from different apps (Samsung Health vs Google Fit)
      // and bypassing Health Connect's aggregation lag, we just take the highest count from any single source.
      if (stepsBySource.isNotEmpty) {
        steps = stepsBySource.values.reduce((a, b) => a > b ? a : b);
      }

      print('DEBUG_HEALTH: Steps by source = $stepsBySource');
      print('DEBUG_HEALTH: Final Steps = $steps');
      print('DEBUG_HEALTH: Final Calories = $calories');
      print('DEBUG_HEALTH: Final Sleep Hours = $sleepHours');

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
