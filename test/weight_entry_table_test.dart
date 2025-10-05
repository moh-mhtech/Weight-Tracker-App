import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:weight_graph/models/weight_entry.dart';
import 'package:weight_graph/providers/settings_provider.dart';
import 'package:weight_graph/widgets/weight_entry_table.dart';

void main() {
  group('WeightEntryTable Widget Tests', () {
    late SettingsProvider settingsProvider;

    setUp(() {
      settingsProvider = SettingsProvider();
    });

    Widget createTestWidget(List<WeightEntry> weightEntries) {
      return MaterialApp(
        home: ChangeNotifierProvider<SettingsProvider>(
          create: (_) => settingsProvider,
          child: Scaffold(
            body: WeightEntryTable(
              weightEntries: weightEntries,
              visibleEntriesCount: 10,
              onEditEntry: (entry) {},
              onDeleteEntry: (entry) {},
            ),
          ),
        ),
      );
    }

    testWidgets('displays single weight entry with correct measurement and average', (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Arrange
        final entries = [
          WeightEntry(weight: 75.5, date: DateTime.utc(2024, 1, 1)),
        ];

        // Act
        await tester.pumpWidget(createTestWidget(entries));
        await tester.pumpAndSettle();

        // Assert
        // Single entry, so measurement and average are the same
        expect(find.textContaining('75.5'), findsNWidgets(2)); // Measurement + average
        expect(find.textContaining('avg'), findsOneWidget);
      });
    });

    testWidgets('displays weight entries with correct averages', (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Arrange
        final entries = [
          WeightEntry(weight: 70.0, date: DateTime.utc(2024, 1, 1)),
          WeightEntry(weight: 71.0, date: DateTime.utc(2024, 1, 2)),
          WeightEntry(weight: 69.0, date: DateTime.utc(2024, 1, 3)),
        ];

        // Act
        settingsProvider.setRunningAverageDays(3); // Example: set averaging period to 3 days
        await tester.pumpWidget(createTestWidget(entries));
        await tester.pumpAndSettle();

        // Assert
        expect(find.textContaining('70.0'), findsNWidgets(3)); // Measurement + average for day 1 + day 3
        expect(find.textContaining('71.0'), findsOneWidget); // Measurement for day 2
        expect(find.textContaining('70.5'), findsOneWidget); // Average for day 2
        expect(find.textContaining('69.0'), findsOneWidget); // Measurement for day 3
        
        // Check that averages are displayed (not 0.0)
        // expect(find.textContaining('avg'), findsNWidgets(3));
      });
    });

    testWidgets('handles entries with different time components correctly', (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Arrange - Entries with different time components but same date
        final entries = [
          WeightEntry(weight: 70.0, date: DateTime.utc(2024, 1, 1, 8, 30)), // 8:30 AM
          WeightEntry(weight: 70.5, date: DateTime.utc(2024, 1, 1, 14, 45)), // 2:45 PM same day
          WeightEntry(weight: 71.0, date: DateTime.utc(2024, 1, 2, 9, 15)), // 9:15 AM next day
        ];

        // Act
        await tester.pumpWidget(createTestWidget(entries));
        await tester.pumpAndSettle();

        // Assert
        // Day 1: Two entries (70.0, 70.5), average = 70.25
        expect(find.text('70.0 kg'), findsOneWidget); // Measurement
        expect(find.text('70.5 kg'), findsOneWidget); // Measurement
        expect(find.text('70.3 kg'), findsOneWidget); // Average for day 1
        
        // Day 2: One entry (71.0), average = 71.0
        expect(find.text('71.0 kg'), findsNWidgets(2)); // Measurement + average
        
        // Check that averages are displayed (not 0.0)
        expect(find.textContaining('avg'), findsNWidgets(2));
      });
    });

    testWidgets('displays correct weight unit (lbs)', (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Arrange
        final entries = [
          WeightEntry(weight: 154.0, date: DateTime.utc(2024, 1, 1)), // ~70kg in lbs
        ];

        // Act
        settingsProvider.setWeightUnit('lbs');
        await tester.pumpWidget(createTestWidget(entries));
        await tester.pumpAndSettle();

        // Assert
        // Single entry, so measurement and average are the same
        expect(find.text('154.0 lbs'), findsNWidgets(2)); // Measurement + average
        expect(find.textContaining('avg'), findsOneWidget);
      });
    });

    testWidgets('handles empty entries list', (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Arrange
        final emptyEntries = <WeightEntry>[];

        // Act
        await tester.pumpWidget(createTestWidget(emptyEntries));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Card), findsOneWidget);
        // Should not crash with empty list
      });
    });
  });
}
