import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_data.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';
import '../services/health_service.dart';

class WaterProvider extends ChangeNotifier {
  int _currentIntake = 0;
  int _goal = 2450;
  Map<String, int> _historyMap = {};
  Map<String, HealthData> _healthMap = {};
  UserProfile _profile = const UserProfile(name: '', age: 25, height: 170, weight: 70);
  bool _isLoaded = false;
  bool _isSyncing = false;
  HealthData _todayHealth = const HealthData();

  StreamSubscription? _waterSub;
  StreamSubscription? _healthSub;

  int get currentIntake => _currentIntake;
  int get goal => _goal;
  Map<String, int> get historyMap => Map.unmodifiable(_historyMap);
  Map<String, HealthData> get healthMap => Map.unmodifiable(_healthMap);
  UserProfile get profile => _profile;
  bool get isLoaded => _isLoaded;
  bool get isSyncing => _isSyncing;
  HealthData get todayHealth => _todayHealth;
  double get progressRatio => (_currentIntake / _goal).clamp(0.0, 1.0);
  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> loadData({bool isSignedIn = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Reset on new day
    final String? lastDate = prefs.getString('last_date');
    final String today = todayKey;
    int savedIntake = prefs.getInt('intake') ?? 0;
    if (lastDate != today) {
      savedIntake = 0;
      await prefs.setString('last_date', today);
      await prefs.setInt('intake', 0);
    }

    // Load history from local cache
    final String? historyJson = prefs.getString('history_json');
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as Map<String, dynamic>;
      _historyMap = decoded.map((k, v) => MapEntry(k, v as int));
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

    // If signed in, sync with Firebase
    if (isSignedIn) {
      await _syncFromFirebase();
      _listenToFirebase();
    }

    // Fetch health data from device
    await refreshHealthData();
  }

  Future<void> _syncFromFirebase() async {
    _isSyncing = true;
    notifyListeners();
    try {
      // Pull profile
      final profileData = await FirebaseService.loadProfile();
      if (profileData != null) {
        _profile = UserProfile(
          name: profileData['name'] ?? _profile.name,
          age: profileData['age'] ?? _profile.age,
          height: (profileData['height'] as num?)?.toDouble() ?? _profile.height,
          weight: (profileData['weight'] as num?)?.toDouble() ?? _profile.weight,
        );
        _goal = profileData['goalMl'] ?? _goal;
      }

      // Pull water history
      final waterHistory = await FirebaseService.loadWaterHistory();
      for (final entry in waterHistory.entries) {
        _historyMap[entry.key] = entry.value;
      }
      // Today's intake from cloud
      if (waterHistory.containsKey(todayKey)) {
        _currentIntake = waterHistory[todayKey]!;
      }

      // Pull health history
      final healthHistory = await FirebaseService.loadHealthHistory();
      _healthMap = healthHistory;

    } catch (_) {}
    _isSyncing = false;
    await _saveLocal();
    notifyListeners();
  }

  void _listenToFirebase() {
    _waterSub?.cancel();
    _healthSub?.cancel();

    _waterSub = FirebaseService.waterStream().listen((data) {
      for (final e in data.entries) {
        _historyMap[e.key] = e.value;
      }
      if (data.containsKey(todayKey)) {
        _currentIntake = data[todayKey]!;
      }
      _saveLocal();
      notifyListeners();
    });

    _healthSub = FirebaseService.healthStream().listen((data) {
      _healthMap = data;
      if (data.containsKey(todayKey)) {
        _todayHealth = data[todayKey]!;
      }
      notifyListeners();
    });
  }

  Future<void> refreshHealthData() async {
    final permitted = await HealthService.requestPermissions();
    if (!permitted) return;
    final data = await HealthService.fetchToday();
    _todayHealth = data;
    _healthMap[todayKey] = data;
    notifyListeners();
    // Save to Firebase
    try {
      await FirebaseService.saveHealthData(todayKey, data);
    } catch (_) {}
  }

  void addWater(int amount) {
    _currentIntake += amount;
    _historyMap[todayKey] = (_historyMap[todayKey] ?? 0) + amount;
    notifyListeners();
    _saveLocal();
    _pushWaterToFirebase();
  }

  void removeWater(int amount) {
    _currentIntake = (_currentIntake - amount).clamp(0, _goal * 2);
    final current = _historyMap[todayKey] ?? 0;
    _historyMap[todayKey] = (current - amount).clamp(0, _goal * 2);
    notifyListeners();
    _saveLocal();
    _pushWaterToFirebase();
  }

  void setGoal(int goalMl) {
    _goal = goalMl;
    notifyListeners();
    _saveLocal();
    FirebaseService.saveProfile(_profile, goalMl).catchError((_) {});
  }

  void updateProfile(UserProfile newProfile, {bool autoUpdateGoal = false}) {
    _profile = newProfile;
    if (autoUpdateGoal) _goal = newProfile.recommendedGoalMl;
    notifyListeners();
    _saveLocal();
    FirebaseService.saveProfile(newProfile, _goal).catchError((_) {});
  }

  Future<void> resetData() async {
    _currentIntake = 0;
    _historyMap.clear();
    _healthMap.clear();
    notifyListeners();
    _saveLocal();
  }

  void _pushWaterToFirebase() {
    FirebaseService.saveWaterIntake(todayKey, _historyMap[todayKey] ?? 0)
        .catchError((_) {});
  }

  Future<void> _saveLocal() async {
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

  int intakeForDate(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return _historyMap[key] ?? 0;
  }

  HealthData healthForDate(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return _healthMap[key] ?? const HealthData();
  }

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

  @override
  void dispose() {
    _waterSub?.cancel();
    _healthSub?.cancel();
    super.dispose();
  }
}
