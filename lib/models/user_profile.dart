class UserProfile {
  final String name;
  final int age;
  final double height;
  final double weight;

  const UserProfile({
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
  });

  /// Recommended daily intake in ml based on weight (35ml per kg)
  int get recommendedGoalMl => (weight * 35).toInt();

  UserProfile copyWith({
    String? name,
    int? age,
    double? height,
    double? weight,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }
}
