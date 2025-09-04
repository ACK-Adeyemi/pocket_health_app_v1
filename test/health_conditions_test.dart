import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_health/models/health_condition.dart';

void main() {
  group('Health Conditions Tests', () {
    test('should convert condition IDs to HealthCondition objects', () {
      // Arrange
      final selectedConditionIds = ['diabetes_type1', 'hypertension', 'asthma'];
      final availableConditions = HealthCondition.getCommonConditions();
      
      // Act
      final selectedHealthConditions = <HealthCondition>[];
      for (final conditionId in selectedConditionIds) {
        final condition = availableConditions.firstWhere(
          (c) => c.id == conditionId,
          orElse: () => HealthCondition(
            id: conditionId,
            name: 'Unknown Condition',
            description: 'Custom health condition',
            addedAt: DateTime.now(),
            category: 'other',
          ),
        );
        selectedHealthConditions.add(condition);
      }
      
      // Assert
      expect(selectedHealthConditions.length, equals(3));
      expect(selectedHealthConditions[0].id, equals('diabetes_type1'));
      expect(selectedHealthConditions[1].id, equals('hypertension'));
      expect(selectedHealthConditions[2].id, equals('asthma'));
      
      // Verify that each condition has proper data
      for (final condition in selectedHealthConditions) {
        expect(condition.name, isNotEmpty);
        expect(condition.description, isNotEmpty);
        expect(condition.addedAt, isNotNull);
        expect(condition.category, isNotEmpty);
      }
    });

    test('should handle unknown condition IDs gracefully', () {
      // Arrange
      final selectedConditionIds = ['unknown_condition'];
      final availableConditions = HealthCondition.getCommonConditions();
      
      // Act
      final selectedHealthConditions = <HealthCondition>[];
      for (final conditionId in selectedConditionIds) {
        final condition = availableConditions.firstWhere(
          (c) => c.id == conditionId,
          orElse: () => HealthCondition(
            id: conditionId,
            name: 'Unknown Condition',
            description: 'Custom health condition',
            addedAt: DateTime.now(),
            category: 'other',
          ),
        );
        selectedHealthConditions.add(condition);
      }
      
      // Assert
      expect(selectedHealthConditions.length, equals(1));
      expect(selectedHealthConditions[0].id, equals('unknown_condition'));
      expect(selectedHealthConditions[0].name, equals('Unknown Condition'));
      expect(selectedHealthConditions[0].category, equals('other'));
    });

    test('should serialize health conditions to map correctly', () {
      // Arrange
      final condition = HealthCondition(
        id: 'test_condition',
        name: 'Test Condition',
        description: 'A test condition',
        addedAt: DateTime.now(),
        category: 'test',
      );
      
      // Act
      final conditionMap = condition.toMap();
      
      // Assert
      expect(conditionMap['id'], equals('test_condition'));
      expect(conditionMap['name'], equals('Test Condition'));
      expect(conditionMap['description'], equals('A test condition'));
      expect(conditionMap['addedAt'], isNotNull);
      expect(conditionMap['category'], equals('test'));
    });

    test('should get common conditions list', () {
      // Act
      final commonConditions = HealthCondition.getCommonConditions();
      
      // Assert
      expect(commonConditions, isNotEmpty);
      expect(commonConditions.length, greaterThan(5)); // Should have multiple conditions
      
      // Check that common conditions like diabetes, hypertension exist
      final conditionIds = commonConditions.map((c) => c.id).toList();
      expect(conditionIds, contains('diabetes_type1'));
      expect(conditionIds, contains('hypertension'));
    });

    test('should handle empty condition list', () {
      // Arrange
      final selectedConditionIds = <String>[];
      
      // Act
      final selectedHealthConditions = <HealthCondition>[];
      if (selectedConditionIds.isNotEmpty) {
        final availableConditions = HealthCondition.getCommonConditions();
        for (final conditionId in selectedConditionIds) {
          final condition = availableConditions.firstWhere(
            (c) => c.id == conditionId,
            orElse: () => HealthCondition(
              id: conditionId,
              name: 'Unknown Condition',
              description: 'Custom health condition',
              addedAt: DateTime.now(),
              category: 'other',
            ),
          );
          selectedHealthConditions.add(condition);
        }
      }
      
      // Assert
      expect(selectedHealthConditions, isEmpty);
    });
  });
}
