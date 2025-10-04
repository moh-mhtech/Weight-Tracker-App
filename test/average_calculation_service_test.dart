import 'package:flutter_test/flutter_test.dart';
import 'package:weight_graph/models/weight_entry.dart';
import 'package:weight_graph/services/average_calculation_service.dart';

void main() {
  group('AverageCalculationService', () {
    group('calcDateAverages', () {
      test('returns empty map when entries list is empty', () {
        // Arrange
        final entries = <WeightEntry>[];
        const averagingPeriod = 5;

        // Act
        final result = AverageCalculationService.calcDateAverages(entries, averagingPeriod);

        // Assert
        expect(result, isEmpty);
      });

      test('calculates correct averages for single entry', () {
        // Arrange
        final entries = [
          WeightEntry(weight: 70.0, date: DateTime(2024, 1, 1)),
        ];
        const averagingPeriod = 3;

        // Act
        final result = AverageCalculationService.calcDateAverages(entries, averagingPeriod);

        // Assert
        expect(result.length, equals(1)); // Only Jan 1 (entry date)
        expect(result[DateTime(2024, 1, 1)], equals(70.0));
      });

      test('calculates correct averages for consecutive entries', () {
        // Arrange
        final entries = [
          WeightEntry(weight: 70.0, date: DateTime(2024, 1, 1)),
          WeightEntry(weight: 71.0, date: DateTime(2024, 1, 2)),
          WeightEntry(weight: 69.0, date: DateTime(2024, 1, 3)),
        ];
        const averagingPeriod = 3;

        // Act
        final result = AverageCalculationService.calcDateAverages(entries, averagingPeriod);

        // Assert
        expect(result.length, equals(3)); // Jan 1-3 (only entry dates)
        
        // Day 1: Only 70kg
        expect(result[DateTime(2024, 1, 1)], equals(70.0));
        
        // Day 2: 70kg + 71kg = 70.5kg
        expect(result[DateTime(2024, 1, 2)], equals(70.5));
        
        // Day 3: 70kg + 71kg + 69kg = 70.0kg
        expect(result[DateTime(2024, 1, 3)], equals(70.0));
      });

      test('handles entries with gaps correctly', () {
        // Arrange
        final entries = [
          WeightEntry(weight: 70.0, date: DateTime(2024, 1, 1)),
          WeightEntry(weight: 72.0, date: DateTime(2024, 1, 5)), // Gap of 3 days
          WeightEntry(weight: 68.0, date: DateTime(2024, 1, 7)),
        ];
        const averagingPeriod = 3;

        // Act
        final result = AverageCalculationService.calcDateAverages(entries, averagingPeriod);

        // Assert
        expect(result.length, equals(7)); // Jan 1-7 (all dates from first to last entry)
        
        // Day 1: Only 70kg
        expect(result[DateTime(2024, 1, 1)], equals(70.0));
        
        // Days 2-4: Use previous average (70.0)
        expect(result[DateTime(2024, 1, 2)], equals(70.0));
        expect(result[DateTime(2024, 1, 3)], equals(70.0));
        expect(result[DateTime(2024, 1, 4)], equals(70.0));
        
        // Day 5: Only 72kg
        expect(result[DateTime(2024, 1, 5)], equals(72.0));
        
        // Day 6: Use previous average (72.0)
        expect(result[DateTime(2024, 1, 6)], equals(72.0));
        
        // Day 7: 72kg + 68kg = 70.0kg (from Jan 5 and Jan 7)
        expect(result[DateTime(2024, 1, 7)], equals(70.0));
      });

      test('handles unsorted entries correctly', () {
        // Arrange - entries in reverse chronological order
        final entries = [
          WeightEntry(weight: 69.0, date: DateTime(2024, 1, 3)),
          WeightEntry(weight: 71.0, date: DateTime(2024, 1, 2)),
          WeightEntry(weight: 70.0, date: DateTime(2024, 1, 1)),
        ];
        const averagingPeriod = 2;

        // Act
        final result = AverageCalculationService.calcDateAverages(entries, averagingPeriod);

        // Assert
        expect(result.length, equals(3)); // Jan 1-3 (only entry dates)
        
        // Day 1: Only 70kg
        expect(result[DateTime(2024, 1, 1)], equals(70.0));
        
        // Day 2: 70kg + 71kg = 70.5kg
        expect(result[DateTime(2024, 1, 2)], equals(70.5));
        
        // Day 3: 71kg + 69kg = 70.0kg
        expect(result[DateTime(2024, 1, 3)], equals(70.0));
      });

      test('handles different averaging periods correctly', () {
        // Arrange
        final entries = [
          WeightEntry(weight: 70.0, date: DateTime(2024, 1, 1)),
          WeightEntry(weight: 71.0, date: DateTime(2024, 1, 2)),
          WeightEntry(weight: 69.0, date: DateTime(2024, 1, 3)),
          WeightEntry(weight: 72.0, date: DateTime(2024, 1, 4)),
        ];

        // Act & Assert - 2-day average
        final result2Day = AverageCalculationService.calcDateAverages(entries, 2);
        expect(result2Day.length, equals(4)); // Jan 1-4 (only entry dates)
        expect(result2Day[DateTime(2024, 1, 1)], equals(70.0)); // Only 70kg
        expect(result2Day[DateTime(2024, 1, 2)], equals(70.5)); // (70+71)/2
        expect(result2Day[DateTime(2024, 1, 3)], equals(70.0)); // (71+69)/2
        expect(result2Day[DateTime(2024, 1, 4)], equals(70.5)); // (69+72)/2

        // Act & Assert - 4-day average
        final result4Day = AverageCalculationService.calcDateAverages(entries, 4);
        expect(result4Day.length, equals(4)); // Jan 1-4 (only entry dates)
        expect(result4Day[DateTime(2024, 1, 1)], equals(70.0)); // Only 70kg
        expect(result4Day[DateTime(2024, 1, 2)], equals(70.5)); // (70+71)/2
        expect(result4Day[DateTime(2024, 1, 3)], equals(70.0)); // (70+71+69)/3
        expect(result4Day[DateTime(2024, 1, 4)], equals(70.5)); // (70+71+69+72)/4
      });

      test('handles entries with same date correctly', () {
        // Arrange - multiple entries on same date
        final entries = [
          WeightEntry(weight: 70.0, date: DateTime(2024, 1, 1)),
          WeightEntry(weight: 70.5, date: DateTime(2024, 1, 1)), // Same date
          WeightEntry(weight: 71.0, date: DateTime(2024, 1, 2)),
        ];
        const averagingPeriod = 2;

        // Act
        final result = AverageCalculationService.calcDateAverages(entries, averagingPeriod);

        // Assert
        expect(result.length, equals(2)); // Jan 1-2 (only entry dates)
        
        // Day 1: (70.0 + 70.5 + 71.0 + 71.0) / 4 = 70.25kg
        expect(result[DateTime(2024, 1, 1)], equals(70.25));
        
        // Day 2: avg(avg(70.0 + 70.5) + 71.0) = 70.625kg
        expect(result[DateTime(2024, 1, 2)], equals(70.625));
      });

      test('handles edge case with averaging period of 1', () {
        // Arrange
        final entries = [
          WeightEntry(weight: 70.0, date: DateTime(2024, 1, 1)),
          WeightEntry(weight: 71.0, date: DateTime(2024, 1, 3)),
        ];
        const averagingPeriod = 1;

        // Act
        final result = AverageCalculationService.calcDateAverages(entries, averagingPeriod);

        // Assert
        expect(result.length, equals(3)); // Jan 1-3 (all dates from first to last entry)
        
        // Day 1: Only 70kg
        expect(result[DateTime(2024, 1, 1)], equals(70.0));
        
        // Day 2: Use previous average (70.0)
        expect(result[DateTime(2024, 1, 2)], equals(70.0));
        
        // Day 3: Only 71kg
        expect(result[DateTime(2024, 1, 3)], equals(71.0));
      });

      test('handles large averaging period correctly', () {
        // Arrange
        final entries = [
          WeightEntry(weight: 70.0, date: DateTime(2024, 1, 1)),
          WeightEntry(weight: 71.0, date: DateTime(2024, 1, 2)),
        ];
        const averagingPeriod = 10; // Larger than number of entries

        // Act
        final result = AverageCalculationService.calcDateAverages(entries, averagingPeriod);

        // Assert
        expect(result.length, equals(2)); // Jan 1-2 (only entry dates)
        
        // Day 1: Only 70kg
        expect(result[DateTime(2024, 1, 1)], equals(70.0));
        
        // Day 2: (70 + 71) / 2 = 70.5kg
        expect(result[DateTime(2024, 1, 2)], equals(70.5));
      });

      test('returns dates in chronological order', () {
        // Arrange
        final entries = [
          WeightEntry(weight: 70.0, date: DateTime(2024, 1, 3)),
          WeightEntry(weight: 71.0, date: DateTime(2024, 1, 1)),
          WeightEntry(weight: 69.0, date: DateTime(2024, 1, 2)),
        ];
        const averagingPeriod = 2;

        // Act
        final result = AverageCalculationService.calcDateAverages(entries, averagingPeriod);

        // Assert
        final dates = result.keys.toList();
        for (int i = 0; i < dates.length - 1; i++) {
          expect(dates[i].isBefore(dates[i + 1]), isTrue);
        }
      });

      test('handles complex scenario with multiple entries per day', () {
        // Arrange - multiple entries on different days
        final entries = [
          WeightEntry(weight: 70.0, date: DateTime(2024, 1, 1)),
          WeightEntry(weight: 70.5, date: DateTime(2024, 1, 1)), // Same day
          WeightEntry(weight: 71.0, date: DateTime(2024, 1, 2)),
          WeightEntry(weight: 69.0, date: DateTime(2024, 1, 3)),
          WeightEntry(weight: 69.5, date: DateTime(2024, 1, 3)), // Same day
        ];
        const averagingPeriod = 3;

        // Act
        final result = AverageCalculationService.calcDateAverages(entries, averagingPeriod);

        // Assert
        expect(result.length, equals(3)); // Jan 1-3 (all dates from first to last entry)
        
        // Day 1: avg(70.0, 70.5) = 70.25kg
        expect(result[DateTime(2024, 1, 1)], equals(70.25));
        
        // Day 2: avg(avg(70.0, 70.5), 71.0) = avg(70.25 + 71.0) = 70.625kg
        expect(result[DateTime(2024, 1, 2)], equals(70.625));
        
        // Day 3: avg(avg(70.0, 70.5), 71.0), avg(71.0), avg(69.0, 69.5)) = avg(70.25, 71.0, 69.25) = 70.167kg
        expect(result[DateTime(2024, 1, 3)], equals(70.167));
      });

      test('handles single day with multiple measurements', () {
        // Arrange - all entries on same day
        final entries = [
          WeightEntry(weight: 70.0, date: DateTime(2024, 1, 1)),
          WeightEntry(weight: 70.5, date: DateTime(2024, 1, 1)),
          WeightEntry(weight: 71.0, date: DateTime(2024, 1, 1)),
        ];
        const averagingPeriod = 2;

        // Act
        final result = AverageCalculationService.calcDateAverages(entries, averagingPeriod);

        // Assert
        expect(result.length, equals(1)); // Only Jan 1
        expect(result[DateTime(2024, 1, 1)], equals(70.5)); // (70.0 + 70.5 + 71.0) / 3
      });
    });
  });
}
