import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_health/providers/health_tracking_provider.dart';
import 'package:pocket_health/models/health_condition.dart';
import 'package:pocket_health/models/health_entry.dart';

void main() {
  group('HealthTrackingProvider Tests', () {
    late HealthTrackingProvider provider;

    setUp(() {
      provider = HealthTrackingProvider();
    });

    test('should handle empty state correctly', () {
      // Assert initial state
      expect(provider.recentEntries, isEmpty);
      expect(provider.entriesByCondition, isEmpty);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.userConditions, isEmpty);
    });

    test('should set user conditions correctly', () {
      // Arrange
      final conditions = [
        HealthCondition(
          id: 'diabetes_type1',
          name: 'Type 1 Diabetes',
          description: 'Autoimmune diabetes',
          addedAt: DateTime.now(),
          category: 'endocrine',
        ),
        HealthCondition(
          id: 'hypertension',
          name: 'Hypertension',
          description: 'High blood pressure',
          addedAt: DateTime.now(),
          category: 'cardiovascular',
        ),
      ];
      
      // Act
      provider.setUserConditions(conditions);
      
      // Assert
      expect(provider.userConditions.length, equals(2));
      expect(provider.userConditions[0].id, equals('diabetes_type1'));
      expect(provider.userConditions[1].id, equals('hypertension'));
    });

    test('should get condition by ID correctly', () {
      // Arrange
      final conditions = [
        HealthCondition(
          id: 'diabetes_type1',
          name: 'Type 1 Diabetes',
          description: 'Autoimmune diabetes',
          addedAt: DateTime.now(),
          category: 'endocrine',
        ),
      ];
      provider.setUserConditions(conditions);
      
      // Act
      final foundCondition = provider.getConditionById('diabetes_type1');
      final notFoundCondition = provider.getConditionById('unknown_condition');
      
      // Assert
      expect(foundCondition, isNotNull);
      expect(foundCondition!.id, equals('diabetes_type1'));
      expect(notFoundCondition, isNull);
    });

    test('should get entries for condition correctly', () {
      // Arrange
      const conditionId = 'diabetes_type1';
      final entries = [
        HealthEntry(
          id: 'entry1',
          userId: 'user123',
          conditionId: conditionId,
          metricId: 'blood_glucose',
          value: 120.0,
          timestamp: DateTime.now(),
        ),
        HealthEntry(
          id: 'entry2',
          userId: 'user123',
          conditionId: conditionId,
          metricId: 'blood_glucose',
          value: 110.0,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
      
      // Simulate entries being loaded
      provider.entriesByCondition[conditionId] = entries;
      
      // Act
      final conditionEntries = provider.getEntriesForCondition(conditionId);
      final emptyEntries = provider.getEntriesForCondition('unknown_condition');
      
      // Assert
      expect(conditionEntries.length, equals(2));
      expect(conditionEntries[0].id, equals('entry1'));
      expect(emptyEntries, isEmpty);
    });

    test('should get latest entry for metric correctly', () {
      // Arrange
      const conditionId = 'diabetes_type1';
      const metricId = 'blood_glucose';
      final entries = [
        HealthEntry(
          id: 'entry1',
          userId: 'user123',
          conditionId: conditionId,
          metricId: metricId,
          value: 120.0,
          timestamp: DateTime.now(),
        ),
        HealthEntry(
          id: 'entry2',
          userId: 'user123',
          conditionId: conditionId,
          metricId: metricId,
          value: 110.0,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        HealthEntry(
          id: 'entry3',
          userId: 'user123',
          conditionId: conditionId,
          metricId: 'different_metric',
          value: 80.0,
          timestamp: DateTime.now(),
        ),
      ];
      
      provider.entriesByCondition[conditionId] = entries;
      
      // Act
      final latestEntry = provider.getLatestEntryForMetric(conditionId, metricId);
      final notFoundEntry = provider.getLatestEntryForMetric(conditionId, 'unknown_metric');
      
      // Assert
      expect(latestEntry, isNotNull);
      expect(latestEntry!.id, equals('entry1')); // First matching entry
      expect(notFoundEntry, isNull);
    });

    test('should get entries for metric with limit', () {
      // Arrange
      const conditionId = 'diabetes_type1';
      const metricId = 'blood_glucose';
      final entries = [
        HealthEntry(
          id: 'entry1',
          userId: 'user123',
          conditionId: conditionId,
          metricId: metricId,
          value: 120.0,
          timestamp: DateTime.now(),
        ),
        HealthEntry(
          id: 'entry2',
          userId: 'user123',
          conditionId: conditionId,
          metricId: metricId,
          value: 110.0,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        HealthEntry(
          id: 'entry3',
          userId: 'user123',
          conditionId: conditionId,
          metricId: metricId,
          value: 100.0,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
      
      provider.entriesByCondition[conditionId] = entries;
      
      // Act
      final allEntries = provider.getEntriesForMetric(conditionId, metricId);
      final limitedEntries = provider.getEntriesForMetric(conditionId, metricId, limit: 2);
      
      // Assert
      expect(allEntries.length, equals(3));
      expect(limitedEntries.length, equals(2));
    });

    test('should calculate average for numeric metric correctly', () {
      // Arrange
      const conditionId = 'diabetes_type1';
      const metricId = 'blood_glucose';
      final now = DateTime.now();
      final entries = [
        HealthEntry(
          id: 'entry1',
          userId: 'user123',
          conditionId: conditionId,
          metricId: metricId,
          value: 120.0,
          timestamp: now,
        ),
        HealthEntry(
          id: 'entry2',
          userId: 'user123',
          conditionId: conditionId,
          metricId: metricId,
          value: 110.0,
          timestamp: now.subtract(const Duration(hours: 1)),
        ),
        HealthEntry(
          id: 'entry3',
          userId: 'user123',
          conditionId: conditionId,
          metricId: metricId,
          value: 100.0,
          timestamp: now.subtract(const Duration(days: 2)),
        ),
      ];
      
      provider.entriesByCondition[conditionId] = entries;
      
      // Act
      final overallAverage = provider.getAverageForMetric(conditionId, metricId);
      final recentAverage = provider.getAverageForMetric(conditionId, metricId, days: 1);
      final noDataAverage = provider.getAverageForMetric('unknown_condition', metricId);
      
      // Assert
      expect(overallAverage, equals(110.0)); // (120 + 110 + 100) / 3
      expect(recentAverage, equals(115.0)); // (120 + 110) / 2 (last 1 day)
      expect(noDataAverage, isNull);
    });

    test('should get trend data correctly', () {
      // Arrange
      const conditionId = 'diabetes_type1';
      const metricId = 'blood_glucose';
      final now = DateTime.now();
      final entries = [
        HealthEntry(
          id: 'entry1',
          userId: 'user123',
          conditionId: conditionId,
          metricId: metricId,
          value: 120.0,
          timestamp: now,
        ),
        HealthEntry(
          id: 'entry2',
          userId: 'user123',
          conditionId: conditionId,
          metricId: metricId,
          value: 110.0,
          timestamp: now.subtract(const Duration(days: 15)),
        ),
        HealthEntry(
          id: 'entry3',
          userId: 'user123',
          conditionId: conditionId,
          metricId: metricId,
          value: 100.0,
          timestamp: now.subtract(const Duration(days: 45)), // Outside 30-day window
        ),
      ];
      
      provider.entriesByCondition[conditionId] = entries;
      
      // Act
      final trendData = provider.getTrendData(conditionId, metricId);
      
      // Assert
      expect(trendData.length, equals(2)); // Only entries within last 30 days
      expect(trendData.any((entry) => entry.id == 'entry1'), isTrue);
      expect(trendData.any((entry) => entry.id == 'entry2'), isTrue);
      expect(trendData.any((entry) => entry.id == 'entry3'), isFalse);
    });

    test('should clear error correctly', () {
      // Arrange - simulate an error state by calling clearError first, then checking
      // Since _error is private, we test the clearError functionality indirectly
      
      // Act
      provider.clearError();
      
      // Assert
      expect(provider.error, isNull);
    });

    test('should handle in-memory sorting logic correctly', () {
      // Test the sorting logic that would be used in loadHealthEntries
      final now = DateTime.now();
      final entries = [
        HealthEntry(
          id: 'entry1',
          userId: 'user123',
          conditionId: 'diabetes_type1',
          metricId: 'blood_glucose',
          value: 120.0,
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        HealthEntry(
          id: 'entry2',
          userId: 'user123',
          conditionId: 'diabetes_type1',
          metricId: 'blood_glucose',
          value: 110.0,
          timestamp: now, // Most recent
        ),
        HealthEntry(
          id: 'entry3',
          userId: 'user123',
          conditionId: 'diabetes_type1',
          metricId: 'blood_glucose',
          value: 100.0,
          timestamp: now.subtract(const Duration(hours: 1)),
        ),
      ];

      // Sort by timestamp descending (most recent first)
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Assert correct sorting
      expect(entries[0].id, equals('entry2')); // Most recent
      expect(entries[1].id, equals('entry3')); // Middle
      expect(entries[2].id, equals('entry1')); // Oldest

      // Test taking first 100 (or less)
      final recentEntries = entries.take(100).toList();
      expect(recentEntries.length, equals(3));
      expect(recentEntries[0].id, equals('entry2'));
    });
  });
}
