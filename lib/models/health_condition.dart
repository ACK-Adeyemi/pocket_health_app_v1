class HealthCondition {
  final String id;
  final String name;
  final String description;
  final bool isTracking;
  final DateTime addedAt;
  final String? severity; // 'mild', 'moderate', 'severe'
  final String? category; // 'chronic', 'acute', 'mental_health', etc.

  // New medication fields
  final bool? takesMedication;
  final String? medicationStabilityMetric; // 'yes', 'not_at_all', 'mostly', 'somewhat'

  HealthCondition({
    required this.id,
    required this.name,
    required this.description,
    this.isTracking = false,
    required this.addedAt,
    this.severity,
    this.category,
    this.takesMedication,
    this.medicationStabilityMetric,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isTracking': isTracking,
      'addedAt': addedAt.toIso8601String(),
      'severity': severity,
      'category': category,
      'takesMedication': takesMedication,
      'medicationStabilityMetric': medicationStabilityMetric,
    };
  }

  factory HealthCondition.fromMap(Map<String, dynamic> map) {
    return HealthCondition(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isTracking: map['isTracking'] ?? false,
      addedAt: DateTime.parse(map['addedAt'] ?? DateTime.now().toIso8601String()),
      severity: map['severity'],
      category: map['category'],
      takesMedication: map['takesMedication'],
      medicationStabilityMetric: map['medicationStabilityMetric'],
    );
  }

  HealthCondition copyWith({
    String? id,
    String? name,
    String? description,
    bool? isTracking,
    DateTime? addedAt,
    String? severity,
    String? category,
    bool? takesMedication,
    String? medicationStabilityMetric,
  }) {
    return HealthCondition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isTracking: isTracking ?? this.isTracking,
      addedAt: addedAt ?? this.addedAt,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      takesMedication: takesMedication ?? this.takesMedication,
      medicationStabilityMetric: medicationStabilityMetric ?? this.medicationStabilityMetric,
    );
  }

  @override
  String toString() {
    return 'HealthCondition(id: $id, name: $name, isTracking: $isTracking)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthCondition &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.isTracking == isTracking;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        isTracking.hashCode;
  }

  // Static list of common health conditions for the onboarding flow
  static List<HealthCondition> getCommonConditions() {
    final now = DateTime.now();
    return [
      HealthCondition(
        id: 'diabetes_type1',
        name: 'Type 1 Diabetes',
        description: 'A chronic condition where the pancreas produces little or no insulin.',
        addedAt: now,
        category: 'chronic',
        severity: 'moderate',
      ),
      HealthCondition(
        id: 'diabetes_type2',
        name: 'Type 2 Diabetes',
        description: 'A chronic condition that affects how your body processes blood sugar.',
        addedAt: now,
        category: 'chronic',
        severity: 'moderate',
      ),
      HealthCondition(
        id: 'hypertension',
        name: 'High Blood Pressure',
        description: 'A condition where blood pressure in the arteries is persistently elevated (also known as Hypertension).',
        addedAt: now,
        category: 'chronic',
        severity: 'moderate',
      ),
      HealthCondition(
        id: 'asthma',
        name: 'Asthma',
        description: 'A respiratory condition marked by attacks of spasm in the bronchi.',
        addedAt: now,
        category: 'chronic',
        severity: 'mild',
      ),
      HealthCondition(
        id: 'arthritis',
        name: 'Arthritis',
        description: 'Inflammation of one or more joints, causing pain and stiffness.',
        addedAt: now,
        category: 'chronic',
        severity: 'mild',
      ),
      HealthCondition(
        id: 'depression',
        name: 'Depression',
        description: 'A mental health disorder characterised by persistent sadness.',
        addedAt: now,
        category: 'mental_health',
        severity: 'moderate',
      ),
      HealthCondition(
        id: 'anxiety',
        name: 'Anxiety Disorder',
        description: 'A mental health disorder characterised by excessive worry or fear.',
        addedAt: now,
        category: 'mental_health',
        severity: 'mild',
      ),
      HealthCondition(
        id: 'heart_disease',
        name: 'Heart Disease',
        description: 'A range of conditions that affect your heart.',
        addedAt: now,
        category: 'chronic',
        severity: 'severe',
      ),
      HealthCondition(
        id: 'obesity',
        name: 'Obesity',
        description: 'A condition involving excessive body fat that increases health risks.',
        addedAt: now,
        category: 'chronic',
        severity: 'moderate',
      ),
      HealthCondition(
        id: 'migraine',
        name: 'Migraine',
        description: 'A neurological condition that can cause severe headaches.',
        addedAt: now,
        category: 'chronic',
        severity: 'mild',
      ),
      HealthCondition(
        id: 'copd',
        name: 'COPD',
        description: 'Chronic obstructive pulmonary disease affecting breathing.',
        addedAt: now,
        category: 'chronic',
        severity: 'severe',
      ),
      HealthCondition(
        id: 'thyroid',
        name: 'Thyroid Disorder',
        description: 'Conditions affecting the thyroid gland and hormone production.',
        addedAt: now,
        category: 'chronic',
        severity: 'mild',
      ),
    ];
  }
}
