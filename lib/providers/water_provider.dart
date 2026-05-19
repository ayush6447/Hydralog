import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class WaterProvider extends ChangeNotifier {
  int _currentIntake = 0;
  int _goal = 2450; // default, overridden by profile
  Map<String, int> _historyMap = {};
  UserProfile _profile = const UserProfile(
    name: '',
    age: 25,
    height: 170.0,
    weight: 70.0,
  );
  bool _isLoaded = false;

  int get currentIntake => _currentIntake;
  int get goal => _goal;
  Map<String, int> get historyMap => Map.unmodifiable(_historyMap);
  UserProfile get profile => _profile;
  bool get isLoaded => _isLoaded;

  double get progressRatio => (_currentIntake / _goal).clamp(0.0, 1.0);

  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // --- Bug fix: reset intake if it's a new day ---
    final String? lastDate = prefs.getString('last_date');
    final String today = todayKey;
    int savedIntake = prefs.getInt('intake') ?? 0;
    if (lastDate != today) {
      savedIntake = 0;
      await prefs.setString('last_date', today);
      await prefs.setInt('intake', 0);
    }

    // --- Bug fix: history stored as single JSON string, not two parallel lists ---
    final String? historyJson = prefs.getString('history_json');
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as Map<String, dynamic>;
      _historyMap = decoded.map((k, v) => MapEntry(k, v as int));
    } else {
      // Migrate from old format if present
      final List<String>? keys = prefs.getStringList('history_keys');
      final List<String>? values = prefs.getStringList('history_values');
      if (keys != null && values != null && keys.length == values.length) {
        _historyMap = {
          for (int i = 0; i < keys.length; i++)
            keys[i]: int.tryParse(values[i]) ?? 0
        };
        // Save in new format and remove old keys
        await prefs.setString('history_json', jsonEncode(_historyMap));
        await prefs.remove('history_keys');
        await prefs.remove('history_values');
      }
    }

    final name = prefs.getString('name') ?? '';
    final age = prefs.getInt('age') ?? 25;
    final height = prefs.getDouble('height') ?? 170.0;
    final weight = prefs.getDouble('weight') ?? 70.0;
    _profile = UserProfile(name: name, age: age, height: height, weight: weight);
    _goal = prefs.getInt('goal') ?? _profile.recommendedGoalMl;
    _currentIntake = savedIntake;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('intake', _currentIntake);
    await prefs.setInt('goal', _goal);
    await prefs.setString('last_date', todayKey);
    await prefs.setString('history_json', jsonEncode(_historyMap));
    await prefs.setString('name', _profile.name);
    await prefs.setInt('age', _profile.age);
    await prefs.setDouble('height', _profile.height);
    await prefs.setDouble('weight', _profile.weight);
  }

  void addWater(int amount) {
    _currentIntake += amount;
    _historyMap[todayKey] = (_historyMap[todayKey] ?? 0) + amount;
    notifyListeners();
    _saveData();
  }

  void removeWater(int amount) {
    _currentIntake = (_currentIntake - amount).clamp(0, _goal * 2);
    final current = _historyMap[todayKey] ?? 0;
    _historyMap[todayKey] = (current - amount).clamp(0, _goal * 2);
    notifyListeners();
    _saveData();
  }

  void setGoal(int goalMl) {
    _goal = goalMl;
    notifyListeners();
    _saveData();
  }

  void updateProfile(UserProfile newProfile, {bool autoUpdateGoal = false}) {
    _profile = newProfile;
    if (autoUpdateGoal) {
      _goal = newProfile.recommendedGoalMl;
    }
    notifyListeners();
    _saveData();
  }

  Future<void> resetData() async {
    _currentIntake = 0;
    _historyMap.clear();
    notifyListeners();
    _saveData();
  }

  int intakeForDate(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return _historyMap[key] ?? 0;
  }

  /// Returns number of consecutive days the goal was met up to today
  int get currentStreak {
    int streak = 0;
    DateTime day = DateTime.now();
    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(day);
      final intake = _historyMap[key] ?? 0;
      if (intake >= _goal) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}
