import 'dart:convert';

/// Domain model representing a user's credentials, account details,
/// and personal tracking preferences.
class UserProfile {
  final String name;
  final String email;
  final String avatarId;
  final int age;
  final double heightCm;
  final double weightKg;
  final String trackingGoal;
  final int usualCycleLength;
  final int usualPeriodLength;
  final DateTime memberSince;
  final bool isLoggedIn;

  const UserProfile({
    required this.name,
    required this.email,
    required this.avatarId,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.trackingGoal,
    required this.usualCycleLength,
    required this.usualPeriodLength,
    required this.memberSince,
    required this.isLoggedIn,
  });

  /// Default baseline profile so existing data and tests work seamlessly.
  factory UserProfile.defaultUser() => UserProfile(
        name: 'Bloom User',
        email: 'bloom.user@bloom.app',
        avatarId: 'coquette',
        age: 24,
        heightCm: 165.0,
        weightKg: 58.0,
        trackingGoal: 'Track menstrual cycle',
        usualCycleLength: 28,
        usualPeriodLength: 5,
        memberSince: DateTime(2026, 1, 1),
        isLoggedIn: true,
      );

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatarId,
    int? age,
    double? heightCm,
    double? weightKg,
    String? trackingGoal,
    int? usualCycleLength,
    int? usualPeriodLength,
    DateTime? memberSince,
    bool? isLoggedIn,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarId: avatarId ?? this.avatarId,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      trackingGoal: trackingGoal ?? this.trackingGoal,
      usualCycleLength: usualCycleLength ?? this.usualCycleLength,
      usualPeriodLength: usualPeriodLength ?? this.usualPeriodLength,
      memberSince: memberSince ?? this.memberSince,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'avatarId': avatarId,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'trackingGoal': trackingGoal,
        'usualCycleLength': usualCycleLength,
        'usualPeriodLength': usualPeriodLength,
        'memberSince': memberSince.toIso8601String(),
        'isLoggedIn': isLoggedIn,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        name: map['name'] as String? ?? 'Bloom User',
        email: map['email'] as String? ?? 'bloom.user@bloom.app',
        avatarId: map['avatarId'] as String? ?? 'coquette',
        age: (map['age'] as num?)?.toInt() ?? 24,
        heightCm: (map['heightCm'] as num?)?.toDouble() ?? 165.0,
        weightKg: (map['weightKg'] as num?)?.toDouble() ?? 58.0,
        trackingGoal:
            map['trackingGoal'] as String? ?? 'Track menstrual cycle',
        usualCycleLength:
            (map['usualCycleLength'] as num?)?.toInt() ?? 28,
        usualPeriodLength:
            (map['usualPeriodLength'] as num?)?.toInt() ?? 5,
        memberSince: DateTime.tryParse(map['memberSince'] as String? ?? '') ??
            DateTime(2026, 1, 1),
        isLoggedIn: map['isLoggedIn'] as bool? ?? true,
      );

  String toJson() => jsonEncode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
