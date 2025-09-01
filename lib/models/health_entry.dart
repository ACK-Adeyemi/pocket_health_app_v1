class HealthEntry {
  final String id;
  final String userId;
  final String conditionId;
  final String metricId;
  final dynamic value; // Can be double, String, or List<String>
  final DateTime timestamp;
  final String? notes;
  final Map<String, dynamic>? additionalData;

  HealthEntry({
    required this.id,
    required this.userId,
    required this.conditionId,
    required this.metricId,
    required this.value,
    required this.timestamp,
    this.notes,
    this.additionalData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'conditionId': conditionId,
      'metricId': metricId,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'additionalData': additionalData,
    };
  }

  factory HealthEntry.fromMap(Map<String, dynamic> map) {
    return HealthEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      conditionId: map['conditionId'] ?? '',
      metricId: map['metricId'] ?? '',
      value: map['value'],
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      notes: map['notes'],
      additionalData: map['additionalData'] != null 
          ? Map<String, dynamic>.from(map['additionalData']) 
          : null,
    );
  }

  HealthEntry copyWith({
    String? id,
    String? userId,
    String? conditionId,
    String? metricId,
    dynamic value,
    DateTime? timestamp,
    String? notes,
    Map<String, dynamic>? additionalData,
  }) {
    return HealthEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      conditionId: conditionId ?? this.conditionId,
      metricId: metricId ?? this.metricId,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Helper methods for different value types
  double? get numericValue {
    if (value is double) return value as double;
    if (value is int) return (value as int).toDouble();
    if (value is String) return double.tryParse(value as String);
    return null;
  }

  String? get stringValue {
    if (value is String) return value as String;
    if (value is double || value is int) return value.toString();
    return null;
  }

  List<String>? get listValue {
    if (value is List) return List<String>.from(value as List);
    return null;
  }

  // Helper method to format value for display
  String getDisplayValue() {
    if (value is List) {
      return (value as List).join(', ');
    }
    return value.toString();
  }

  @override
  String toString() {
    return 'HealthEntry(id: $id, conditionId: $conditionId, metricId: $metricId, value: $value, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthEntry &&
        other.id == id &&
        other.userId == userId &&
        other.conditionId == conditionId &&
        other.metricId == metricId &&
        other.value == value &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        conditionId.hashCode ^
        metricId.hashCode ^
        value.hashCode ^
        timestamp.hashCode;
  }
}

// Helper class for grouped health entries (e.g., blood pressure with systolic/diastolic)
class HealthEntryGroup {
  final String id;
  final String userId;
  final String conditionId;
  final DateTime timestamp;
  final List<HealthEntry> entries;
  final String? notes;

  HealthEntryGroup({
    required this.id,
    required this.userId,
    required this.conditionId,
    required this.timestamp,
    required this.entries,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'conditionId': conditionId,
      'timestamp': timestamp.toIso8601String(),
      'entries': entries.map((e) => e.toMap()).toList(),
      'notes': notes,
    };
  }

  factory HealthEntryGroup.fromMap(Map<String, dynamic> map) {
    return HealthEntryGroup(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      conditionId: map['conditionId'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      entries: (map['entries'] as List<dynamic>?)
              ?.map((e) => HealthEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'],
    );
  }

  // Helper method to get entry by metric ID
  HealthEntry? getEntryByMetricId(String metricId) {
    try {
      return entries.firstWhere((entry) => entry.metricId == metricId);
    } catch (e) {
      return null;
    }
  }

  // Helper method to get blood pressure reading (systolic/diastolic)
  Map<String, double>? getBloodPressureReading() {
    final systolic = getEntryByMetricId('bp_systolic')?.numericValue;
    final diastolic = getEntryByMetricId('bp_diastolic')?.numericValue;
    
    if (systolic != null && diastolic != null) {
      return {
        'systolic': systolic,
        'diastolic': diastolic,
      };
    }
    return null;
  }

  // Helper method to classify blood pressure according to NICE guidelines
  String? getBloodPressureClassification() {
    final bp = getBloodPressureReading();
    if (bp == null) return null;

    final systolic = bp['systolic']!;
    final diastolic = bp['diastolic']!;

    // NICE blood pressure classification
    if (systolic < 120 && diastolic < 80) {
      return 'Optimal';
    } else if (systolic < 130 && diastolic < 85) {
      return 'Normal';
    } else if (systolic < 140 && diastolic < 90) {
      return 'High Normal';
    } else if (systolic < 160 && diastolic < 100) {
      return 'Stage 1 Hypertension';
    } else if (systolic < 180 && diastolic < 110) {
      return 'Stage 2 Hypertension';
    } else {
      return 'Stage 3 Hypertension';
    }
  }
}
