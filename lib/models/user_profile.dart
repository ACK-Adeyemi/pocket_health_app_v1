import 'package:cloud_firestore/cloud_firestore.dart';
import 'health_condition.dart';

/// User roles for community access control
enum UserRole {
  user('user', 'Regular user with community access'),
  moderator('moderator', 'Content moderator with elevated permissions'),
  admin('admin', 'Administrator with full system access');

  const UserRole(this.value, this.description);
  final String value;
  final String description;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.user,
    );
  }
}

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final int age;
  final double height;
  final double weight;
  final String heightUnit; // 'cm' or 'ft'
  final String weightUnit; // 'kg' or 'lbs'
  final List<HealthCondition> healthConditions;
  final Map<String, dynamic>? gpDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasCompletedOnboarding;
  final UserRole role; // User role for community permissions
  final String? anonymousId; // SHA-256 hash for community anonymity
  final bool isHealthcareProfessional; // For specialized moderation
  
  // New fields for Quick Check-In and A/B Testing
  final String? abTestGroup; // 'A' (Quick emphasis) or 'B' (Classic emphasis)
  final String preferredLoggingMode; // 'quick' or 'classic'
  final bool hasSeenQuickCheckInOnboarding;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.heightUnit,
    required this.weightUnit,
    this.healthConditions = const [],
    this.gpDetails,
    required this.createdAt,
    required this.updatedAt,
    this.hasCompletedOnboarding = false,
    this.role = UserRole.user,
    this.anonymousId,
    this.isHealthcareProfessional = false,
    this.abTestGroup,
    this.preferredLoggingMode = 'classic',
    this.hasSeenQuickCheckInOnboarding = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      'heightUnit': heightUnit,
      'weightUnit': weightUnit,
      'healthConditions': healthConditions.map((c) => c.toMap()).toList(),
      'gpDetails': gpDetails,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'role': role.value,
      'anonymousId': anonymousId,
      'isHealthcareProfessional': isHealthcareProfessional,
      'abTestGroup': abTestGroup,
      'preferredLoggingMode': preferredLoggingMode,
      'hasSeenQuickCheckInOnboarding': hasSeenQuickCheckInOnboarding,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      age: map['age']?.toInt() ?? 0,
      height: map['height']?.toDouble() ?? 0.0,
      weight: map['weight']?.toDouble() ?? 0.0,
      heightUnit: map['heightUnit'] ?? 'cm',
      weightUnit: map['weightUnit'] ?? 'kg',
      healthConditions: (map['healthConditions'] as List<dynamic>?)
              ?.map((c) => HealthCondition.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      gpDetails: map['gpDetails'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      hasCompletedOnboarding: map['hasCompletedOnboarding'] ?? false,
      role: UserRole.fromString(map['role'] ?? 'user'),
      anonymousId: map['anonymousId'] as String?,
      isHealthcareProfessional: map['isHealthcareProfessional'] ?? false,
      abTestGroup: map['abTestGroup'],
      preferredLoggingMode: map['preferredLoggingMode'] ?? 'classic',
      hasSeenQuickCheckInOnboarding: map['hasSeenQuickCheckInOnboarding'] ?? false,
    );
  }

  // Helper method to parse DateTime from either Timestamp or String
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }
    
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    }
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    // Fallback for any other type
    return DateTime.now();
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    int? age,
    double? height,
    double? weight,
    String? heightUnit,
    String? weightUnit,
    List<HealthCondition>? healthConditions,
    Map<String, dynamic>? gpDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasCompletedOnboarding,
    UserRole? role,
    String? anonymousId,
    bool? isHealthcareProfessional,
    String? abTestGroup,
    String? preferredLoggingMode,
    bool? hasSeenQuickCheckInOnboarding,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      heightUnit: heightUnit ?? this.heightUnit,
      weightUnit: weightUnit ?? this.weightUnit,
      healthConditions: healthConditions ?? this.healthConditions,
      gpDetails: gpDetails ?? this.gpDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      role: role ?? this.role,
      anonymousId: anonymousId ?? this.anonymousId,
      isHealthcareProfessional: isHealthcareProfessional ?? this.isHealthcareProfessional,
      abTestGroup: abTestGroup ?? this.abTestGroup,
      preferredLoggingMode: preferredLoggingMode ?? this.preferredLoggingMode,
      hasSeenQuickCheckInOnboarding: hasSeenQuickCheckInOnboarding ?? this.hasSeenQuickCheckInOnboarding,
    );
  }

  // Helper methods for unit conversions
  double get heightInCm {
    if (heightUnit == 'ft') {
      return height * 30.48; // Convert feet to cm
    }
    return height;
  }

  double get weightInKg {
    if (weightUnit == 'lbs') {
      return weight * 0.453592; // Convert lbs to kg
    }
    return weight;
  }

  // Calculate BMI
  double get bmi {
    final heightInMeters = heightInCm / 100;
    if (heightInMeters == 0) return 0;
    return weightInKg / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal weight';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, email: $email, name: $name, age: $age, height: $height$heightUnit, weight: $weight$weightUnit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.uid == uid &&
        other.email == email &&
        other.name == name &&
        other.age == age &&
        other.height == height &&
        other.weight == weight &&
        other.heightUnit == heightUnit &&
        other.weightUnit == weightUnit;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        name.hashCode ^
        age.hashCode ^
        height.hashCode ^
        weight.hashCode ^
        heightUnit.hashCode ^
        weightUnit.hashCode;
  }
}
