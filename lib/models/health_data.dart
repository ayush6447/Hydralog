class HealthData {
  final int steps;
  final double caloriesBurned;
  final double sleepHours;
  final double screenTimeHours; // Android/Samsung only
  final String deviceSource; // 'iphone' | 'samsung' | 'manual'

  const HealthData({
    this.steps = 0,
    this.caloriesBurned = 0,
    this.sleepHours = 0,
    this.screenTimeHours = 0,
    this.deviceSource = 'manual',
  });

  HealthData copyWith({
    int? steps,
    double? caloriesBurned,
    double? sleepHours,
    double? screenTimeHours,
    String? deviceSource,
  }) {
    return HealthData(
      steps: steps ?? this.steps,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      sleepHours: sleepHours ?? this.sleepHours,
      screenTimeHours: screenTimeHours ?? this.screenTimeHours,
      deviceSource: deviceSource ?? this.deviceSource,
    );
  }

  Map<String, dynamic> toMap() => {
        'steps': steps,
        'caloriesBurned': caloriesBurned,
        'sleepHours': sleepHours,
        'screenTimeHours': screenTimeHours,
        'deviceSource': deviceSource,
      };

  factory HealthData.fromMap(Map<String, dynamic> map) => HealthData(
        steps: (map['steps'] as num?)?.toInt() ?? 0,
        caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble() ?? 0,
        sleepHours: (map['sleepHours'] as num?)?.toDouble() ?? 0,
        screenTimeHours: (map['screenTimeHours'] as num?)?.toDouble() ?? 0,
        deviceSource: map['deviceSource'] as String? ?? 'manual',
      );

  HealthData merge(HealthData other) {
    // When merging data from two devices, take the max steps/calories
    // (one device might not have moved, the other did)
    return HealthData(
      steps: steps > other.steps ? steps : other.steps,
      caloriesBurned: caloriesBurned > other.caloriesBurned
          ? caloriesBurned
          : other.caloriesBurned,
      sleepHours: sleepHours > 0 ? sleepHours : other.sleepHours,
      screenTimeHours:
          screenTimeHours > 0 ? screenTimeHours : other.screenTimeHours,
      deviceSource: 'merged',
    );
  }
}
