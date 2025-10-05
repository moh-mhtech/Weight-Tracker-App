import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:weight_graph/models/weight_entry.dart';
import 'package:weight_graph/providers/settings_provider.dart';
import 'package:weight_graph/widgets/weight_chart.dart';

void main() {
  group('WeightChart Widget Tests', () {
    late SettingsProvider settingsProvider;

    setUp(() {
      settingsProvider = SettingsProvider();
    });

    Widget createTestWidget(List<WeightEntry> weightEntries) {
      return MaterialApp(
        home: ChangeNotifierProvider<SettingsProvider>(
          create: (_) => settingsProvider,
          child: Scaffold(
            body: WeightChart(weightEntries: weightEntries),
          ),
        ),
      );
    }

    testWidgets('displays empty state when no weight entries', (WidgetTester tester) async {
      // Arrange
      final emptyEntries = <WeightEntry>[];

      // Act
      await tester.pumpWidget(createTestWidget(emptyEntries));

      // Assert
      expect(find.text('No weight data available.\nAdd some weight entries to see the chart.'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('displays chart with single weight entry', (WidgetTester tester) async {
      // Arrange
      final singleEntry = [
        WeightEntry(weight: 70.0, date: DateTime.utc(2024, 1, 1)),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(singleEntry));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('5-day Average: 70.0 kg'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Measurements'), findsOneWidget);
      expect(find.text('5-day Average'), findsOneWidget);
    });

    testWidgets('displays chart with multiple weight entries', (WidgetTester tester) async {
      // Arrange
      final multipleEntries = [
        WeightEntry(weight: 70.0, date: DateTime.utc(2024, 1, 1)),
        WeightEntry(weight: 71.0, date: DateTime.utc(2024, 1, 2)),
        WeightEntry(weight: 69.0, date: DateTime.utc(2024, 1, 3)),
        WeightEntry(weight: 72.0, date: DateTime.utc(2024, 1, 4)),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(multipleEntries));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('5-day Average: 70.5 kg'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Measurements'), findsOneWidget);
      expect(find.text('5-day Average'), findsOneWidget);
    });

    testWidgets('displays correct average with different running average days', (WidgetTester tester) async {
      // Arrange
      final entries = [
        WeightEntry(weight: 70.0, date: DateTime.utc(2024, 1, 1)),
        WeightEntry(weight: 71.0, date: DateTime.utc(2024, 1, 2)),
        WeightEntry(weight: 69.0, date: DateTime.utc(2024, 1, 3)),
      ];

      // Act - Test with 3-day average
      settingsProvider.setRunningAverageDays(3);
      await tester.pumpWidget(createTestWidget(entries));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('3-day Average: 70.0 kg'), findsOneWidget);
      expect(find.text('3-day Average'), findsOneWidget);
    });

    testWidgets('displays correct weight unit (lbs)', (WidgetTester tester) async {
      // Arrange
      final entries = [
        WeightEntry(weight: 154.0, date: DateTime.utc(2024, 1, 1)), // ~70kg in lbs
      ];

      // Act
      settingsProvider.setWeightUnit('lbs');
      await tester.pumpWidget(createTestWidget(entries));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('5-day Average: 154.0 lbs'), findsOneWidget);
    });

    testWidgets('handles entries with same date correctly', (WidgetTester tester) async {
      // Arrange
      final entriesWithSameDate = [
        WeightEntry(weight: 70.0, date: DateTime.utc(2024, 1, 1)),
        WeightEntry(weight: 70.5, date: DateTime.utc(2024, 1, 1)), // Same date
        WeightEntry(weight: 71.0, date: DateTime.utc(2024, 1, 2)),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(entriesWithSameDate));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Measurements'), findsOneWidget);
      expect(find.text('5-day Average'), findsOneWidget);
    });

    testWidgets('displays legend correctly', (WidgetTester tester) async {
      // Arrange
      final entries = [
        WeightEntry(weight: 70.0, date: DateTime.utc(2024, 1, 1)),
        WeightEntry(weight: 71.0, date: DateTime.utc(2024, 1, 2)),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(entries));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Measurements'), findsOneWidget);
      expect(find.text('5-day Average'), findsOneWidget);
      
      // Check for legend indicators (colored circles)
      final legendContainers = find.byWidgetPredicate(
        (widget) => widget is Container && 
                   widget.decoration is BoxDecoration &&
                   (widget.decoration as BoxDecoration).shape == BoxShape.circle
      );
      expect(legendContainers, findsNWidgets(2)); // Two legend indicators
    });

    testWidgets('chart updates when settings change', (WidgetTester tester) async {
      // Arrange
      final entries = [
        WeightEntry(weight: 70.0, date: DateTime.utc(2024, 1, 1)),
        WeightEntry(weight: 71.0, date: DateTime.utc(2024, 1, 2)),
      ];

      // Act - Initial render
      await tester.pumpWidget(createTestWidget(entries));
      await tester.pumpAndSettle();

      // Assert initial state
      expect(find.text('5-day Average: 70.5 kg'), findsOneWidget);

      // Act - Change running average days
      settingsProvider.setRunningAverageDays(7);
      await tester.pumpAndSettle();

      // Assert updated state
      expect(find.text('7-day Average: 70.5 kg'), findsOneWidget);
      expect(find.text('7-day Average'), findsOneWidget);
    });

    testWidgets('chart handles edge case with very small weight values', (WidgetTester tester) async {
      // Arrange
      final entries = [
        WeightEntry(weight: 0.1, date: DateTime.utc(2024, 1, 1)),
        WeightEntry(weight: 0.2, date: DateTime.utc(2024, 1, 2)),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(entries));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Measurements'), findsOneWidget);
    });

    testWidgets('chart handles edge case with very large weight values', (WidgetTester tester) async {
      // Arrange
      final entries = [
        WeightEntry(weight: 200.0, date: DateTime.utc(2024, 1, 1)),
        WeightEntry(weight: 250.0, date: DateTime.utc(2024, 1, 2)),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(entries));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Measurements'), findsOneWidget);
    });

    testWidgets('chart displays correct date range for 7-day window', (WidgetTester tester) async {
      // Arrange
      final entries = [
        WeightEntry(weight: 70.0, date: DateTime.utc(2024, 1, 1)),
        WeightEntry(weight: 71.0, date: DateTime.utc(2024, 1, 8)), // 7 days later
      ];

      // Act
      await tester.pumpWidget(createTestWidget(entries));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
      // The chart should show a 7-day window ending at the latest entry
    });

    testWidgets('chart handles unsorted entries correctly', (WidgetTester tester) async {
      // Arrange - Entries in reverse chronological order
      final unsortedEntries = [
        WeightEntry(weight: 72.0, date: DateTime.utc(2024, 1, 4)),
        WeightEntry(weight: 70.0, date: DateTime.utc(2024, 1, 1)),
        WeightEntry(weight: 71.0, date: DateTime.utc(2024, 1, 2)),
        WeightEntry(weight: 69.0, date: DateTime.utc(2024, 1, 3)),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(unsortedEntries));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Measurements'), findsOneWidget);
      // Chart should still display correctly despite unsorted input
    });

    testWidgets('chart displays proper formatting for average values', (WidgetTester tester) async {
      // Arrange
      final entries = [
        WeightEntry(weight: 70.123, date: DateTime.utc(2024, 1, 1)),
        WeightEntry(weight: 71.456, date: DateTime.utc(2024, 1, 2)),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(entries));
      await tester.pumpAndSettle();

      // Assert
      // Average should be formatted to 1 decimal place
      expect(find.textContaining('70.8 kg'), findsOneWidget);
    });

    testWidgets('chart handles entries with different time components correctly', (WidgetTester tester) async {
      // Arrange - Entries with different time components but same date
      final entries = [
        WeightEntry(weight: 70.0, date: DateTime.utc(2024, 1, 1, 8, 30)), // 8:30 AM
        WeightEntry(weight: 71.0, date: DateTime.utc(2024, 1, 1, 14, 45)), // 2:45 PM
        WeightEntry(weight: 69.0, date: DateTime.utc(2024, 1, 2, 9, 15)), // 9:15 AM next day
      ];

      // Act
      await tester.pumpWidget(createTestWidget(entries));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Measurements'), findsOneWidget);
      // Should handle multiple entries on same date correctly
    });
  });
}
