import 'package:flutter/material.dart';

enum MetricType {
  pain,
  bloodGlucose,
  bloodPressure,
  peakFlow,
  mood,
  anxiety,
  weight,
  temperature,
  heartRate,
  custom,
}

enum MetricUnit {
  scale0to10,
  mmolL,
  mmHg,
  lMin,
  bpm,
  celsius,
  kg,
  percentage,
  minutes,
  custom,
}

class HealthMetric {
  // Mapping of icon code points to const IconData instances for tree shaking
  static const Map<int, IconData> _iconMapping = {
    0xe3f4: Icons.help_outline, // Default fallback
  };

  final String id;
  final String conditionId;
  final String name;
  final String description;
  final MetricType type;
  final MetricUnit unit;
  final double? minValue;
  final double? maxValue;
  final List<String>? options; // For categorical metrics
  final String? instructions;
  final bool isRequired;
  final Color color;
  final IconData icon;

  const HealthMetric({
    required this.id,
    required this.conditionId,
    required this.name,
    required this.description,
    required this.type,
    required this.unit,
    this.minValue,
    this.maxValue,
    this.options,
    this.instructions,
    this.isRequired = false,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conditionId': conditionId,
      'name': name,
      'description': description,
      'type': type.name,
      'unit': unit.name,
      'minValue': minValue,
      'maxValue': maxValue,
      'options': options,
      'instructions': instructions,
      'isRequired': isRequired,
      'color': color.value,
      'icon': icon.codePoint,
    };
  }

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      id: map['id'] ?? '',
      conditionId: map['conditionId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: MetricType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MetricType.custom,
      ),
      unit: MetricUnit.values.firstWhere(
        (e) => e.name == map['unit'],
        orElse: () => MetricUnit.custom,
      ),
      minValue: map['minValue']?.toDouble(),
      maxValue: map['maxValue']?.toDouble(),
      options: map['options'] != null ? List<String>.from(map['options']) : null,
      instructions: map['instructions'],
      isRequired: map['isRequired'] ?? false,
      color: Color(map['color'] ?? 0xFF1565C0),
      icon: _iconMapping[map['icon'] ?? 0xe3f4] ?? Icons.help_outline,
    );
  }

  String getUnitDisplay() {
    switch (unit) {
      case MetricUnit.scale0to10:
        return '/10';
      case MetricUnit.mmolL:
        return 'mmol/L';
      case MetricUnit.mmHg:
        return 'mmHg';
      case MetricUnit.lMin:
        return 'L/min';
      case MetricUnit.bpm:
        return 'BPM';
      case MetricUnit.celsius:
        return '°C';
      case MetricUnit.kg:
        return 'kg';
      case MetricUnit.percentage:
        return '%';
      case MetricUnit.minutes:
        return 'min';
      case MetricUnit.custom:
        return '';
    }
  }

  // Predefined metrics for common UK health conditions
  static List<HealthMetric> getMetricsForCondition(String conditionId) {
    switch (conditionId) {
      case 'arthritis':
        return [
          HealthMetric(
            id: 'arthritis_pain_vas',
            conditionId: 'arthritis',
            name: 'Pain Level (VAS)',
            description: 'Visual Analogue Scale for pain assessment',
            type: MetricType.pain,
            unit: MetricUnit.scale0to10,
            minValue: 0,
            maxValue: 10,
            instructions: 'Rate your pain from 0 (no pain) to 10 (worst pain imaginable)',
            isRequired: true,
            color: const Color(0xFFE57373),
            icon: Icons.healing,
          ),
          HealthMetric(
            id: 'arthritis_stiffness',
            conditionId: 'arthritis',
            name: 'Morning Stiffness',
            description: 'Duration of morning joint stiffness',
            type: MetricType.custom,
            unit: MetricUnit.minutes,
            minValue: 0,
            maxValue: 480,
            instructions: 'How long did morning stiffness last? (in minutes)',
            color: const Color(0xFFFFB74D),
            icon: Icons.schedule,
          ),
          HealthMetric(
            id: 'arthritis_joints',
            conditionId: 'arthritis',
            name: 'Affected Joints',
            description: 'Which joints are affected today?',
            type: MetricType.custom,
            unit: MetricUnit.custom,
            options: ['Hands', 'Wrists', 'Elbows', 'Shoulders', 'Knees', 'Ankles', 'Feet', 'Spine'],
            color: const Color(0xFF81C784),
            icon: Icons.accessibility,
          ),
        ];

      case 'diabetes_type1':
      case 'diabetes_type2':
        return [
          HealthMetric(
            id: 'diabetes_glucose',
            conditionId: conditionId,
            name: 'Blood Glucose',
            description: 'Blood glucose level in mmol/L (UK standard)',
            type: MetricType.bloodGlucose,
            unit: MetricUnit.mmolL,
            minValue: 2.0,
            maxValue: 30.0,
            instructions: 'Enter your blood glucose reading in mmol/L',
            isRequired: true,
            color: const Color(0xFF64B5F6),
            icon: Icons.bloodtype,
          ),
          HealthMetric(
            id: 'diabetes_meal_timing',
            conditionId: conditionId,
            name: 'Meal Timing',
            description: 'When was this reading taken?',
            type: MetricType.custom,
            unit: MetricUnit.custom,
            options: ['Before breakfast', 'After breakfast', 'Before lunch', 'After lunch', 'Before dinner', 'After dinner', 'Bedtime'],
            color: const Color(0xFFAED581),
            icon: Icons.restaurant,
          ),
          HealthMetric(
            id: 'diabetes_insulin',
            conditionId: conditionId,
            name: 'Insulin Dose',
            description: 'Insulin units administered',
            type: MetricType.custom,
            unit: MetricUnit.custom,
            minValue: 0,
            maxValue: 100,
            instructions: 'Enter insulin dose in units (if applicable)',
            color: const Color(0xFFBA68C8),
            icon: Icons.medication,
          ),
        ];

      case 'hypertension':
        return [
          HealthMetric(
            id: 'bp_systolic',
            conditionId: 'hypertension',
            name: 'Systolic BP',
            description: 'Systolic blood pressure',
            type: MetricType.bloodPressure,
            unit: MetricUnit.mmHg,
            minValue: 70,
            maxValue: 250,
            instructions: 'Enter systolic blood pressure (top number)',
            isRequired: true,
            color: const Color(0xFFE57373),
            icon: Icons.favorite,
          ),
          HealthMetric(
            id: 'bp_diastolic',
            conditionId: 'hypertension',
            name: 'Diastolic BP',
            description: 'Diastolic blood pressure',
            type: MetricType.bloodPressure,
            unit: MetricUnit.mmHg,
            minValue: 40,
            maxValue: 150,
            instructions: 'Enter diastolic blood pressure (bottom number)',
            isRequired: true,
            color: const Color(0xFFE57373),
            icon: Icons.favorite,
          ),
          HealthMetric(
            id: 'bp_heart_rate',
            conditionId: 'hypertension',
            name: 'Heart Rate',
            description: 'Pulse rate in beats per minute',
            type: MetricType.heartRate,
            unit: MetricUnit.bpm,
            minValue: 30,
            maxValue: 200,
            instructions: 'Enter your heart rate in BPM',
            color: const Color(0xFFFF8A65),
            icon: Icons.monitor_heart,
          ),
        ];

      case 'asthma':
        return [
          HealthMetric(
            id: 'asthma_peak_flow',
            conditionId: 'asthma',
            name: 'Peak Flow',
            description: 'Peak expiratory flow rate',
            type: MetricType.peakFlow,
            unit: MetricUnit.lMin,
            minValue: 50,
            maxValue: 800,
            instructions: 'Enter your peak flow reading in L/min',
            isRequired: true,
            color: const Color(0xFF4FC3F7),
            icon: Icons.air,
          ),
          HealthMetric(
            id: 'asthma_symptoms',
            conditionId: 'asthma',
            name: 'Symptom Severity',
            description: 'Overall asthma symptom severity',
            type: MetricType.custom,
            unit: MetricUnit.scale0to10,
            minValue: 0,
            maxValue: 4,
            options: ['None', 'Mild', 'Moderate', 'Severe'],
            instructions: 'Rate your asthma symptoms today',
            color: const Color(0xFF81C784),
            icon: Icons.healing,
          ),
          HealthMetric(
            id: 'asthma_inhaler',
            conditionId: 'asthma',
            name: 'Inhaler Use',
            description: 'Number of inhaler puffs used',
            type: MetricType.custom,
            unit: MetricUnit.custom,
            minValue: 0,
            maxValue: 20,
            instructions: 'How many puffs of reliever inhaler did you use?',
            color: const Color(0xFFFFB74D),
            icon: Icons.medication,
          ),
        ];

      case 'depression':
        return [
          HealthMetric(
            id: 'depression_mood',
            conditionId: 'depression',
            name: 'Mood Rating',
            description: 'Overall mood assessment',
            type: MetricType.mood,
            unit: MetricUnit.scale0to10,
            minValue: 0,
            maxValue: 10,
            instructions: 'Rate your mood from 0 (very low) to 10 (excellent)',
            isRequired: true,
            color: const Color(0xFF9575CD),
            icon: Icons.sentiment_satisfied,
          ),
          HealthMetric(
            id: 'depression_sleep',
            conditionId: 'depression',
            name: 'Sleep Quality',
            description: 'Quality of sleep last night',
            type: MetricType.custom,
            unit: MetricUnit.scale0to10,
            minValue: 0,
            maxValue: 10,
            instructions: 'Rate your sleep quality from 0 (very poor) to 10 (excellent)',
            color: const Color(0xFF64B5F6),
            icon: Icons.bedtime,
          ),
          HealthMetric(
            id: 'depression_energy',
            conditionId: 'depression',
            name: 'Energy Level',
            description: 'Current energy level',
            type: MetricType.custom,
            unit: MetricUnit.scale0to10,
            minValue: 0,
            maxValue: 10,
            instructions: 'Rate your energy level from 0 (no energy) to 10 (very energetic)',
            color: const Color(0xFFFFB74D),
            icon: Icons.battery_charging_full,
          ),
        ];

      case 'anxiety':
        return [
          HealthMetric(
            id: 'anxiety_level',
            conditionId: 'anxiety',
            name: 'Anxiety Level',
            description: 'Current anxiety level',
            type: MetricType.anxiety,
            unit: MetricUnit.scale0to10,
            minValue: 0,
            maxValue: 10,
            instructions: 'Rate your anxiety from 0 (no anxiety) to 10 (severe anxiety)',
            isRequired: true,
            color: const Color(0xFFFFB74D),
            icon: Icons.psychology,
          ),
          HealthMetric(
            id: 'anxiety_triggers',
            conditionId: 'anxiety',
            name: 'Triggers',
            description: 'What triggered your anxiety?',
            type: MetricType.custom,
            unit: MetricUnit.custom,
            options: ['Work stress', 'Social situations', 'Health concerns', 'Financial worries', 'Family issues', 'Unknown', 'Other'],
            color: const Color(0xFFE57373),
            icon: Icons.warning,
          ),
          HealthMetric(
            id: 'anxiety_symptoms',
            conditionId: 'anxiety',
            name: 'Physical Symptoms',
            description: 'Physical symptoms experienced',
            type: MetricType.custom,
            unit: MetricUnit.custom,
            options: ['Racing heart', 'Sweating', 'Trembling', 'Shortness of breath', 'Nausea', 'Dizziness', 'None'],
            color: const Color(0xFF81C784),
            icon: Icons.healing,
          ),
        ];

      default:
        return [];
    }
  }
}
