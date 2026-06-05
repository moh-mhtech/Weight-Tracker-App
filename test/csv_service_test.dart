import 'package:flutter_test/flutter_test.dart';
import 'package:weight_graph/models/weight_entry.dart';
import 'package:weight_graph/services/chart_viewport_service.dart';
import 'package:weight_graph/services/csv_service.dart';

void main() {
  group('CsvService.parseCsvContent', () {
    test('parses comma-separated CSV with dot decimals', () {
      const csv = 'Date,Weight\n01/06/2025,82.5\n02/06/2025,82.1\n';

      final result = CsvService.parseCsvContent(csv, 'dd/MM/yyyy');

      expect(result.errors, isEmpty);
      expect(result.entries, hasLength(2));
      expect(result.entries[0].weight, 82.5);
      expect(result.entries[1].weight, 82.1);
    });

    test('parses semicolon-separated European CSV with comma decimals', () {
      const csv = 'Date;Weight\n03/06/2026;78,0\n02/06/2026;78,3\n';

      final result = CsvService.parseCsvContent(csv, 'dd/MM/yyyy');

      expect(result.errors, isEmpty);
      expect(result.entries, hasLength(2));
      expect(result.entries[0].weight, 78.0);
      expect(result.entries[1].weight, 78.3);
    });

    test('parses each supported date format', () {
      final cases = {
        'dd/MM/yyyy': 'Date,Weight\n15/03/2025,80.0\n',
        'MM/dd/yyyy': 'Date,Weight\n03/15/2025,80.0\n',
        'yyyy-MM-dd': 'Date,Weight\n2025-03-15,80.0\n',
      };

      for (final entry in cases.entries) {
        final result = CsvService.parseCsvContent(entry.value, entry.key);

        expect(result.errors, isEmpty, reason: entry.key);
        expect(result.entries, hasLength(1));
        expect(result.entries.first.date.year, 2025);
        expect(result.entries.first.date.month, 3);
        expect(result.entries.first.date.day, 15);
      }
    });

    test('ignores Average column on import', () {
      const csv = 'Date,Weight,Average\n01/06/2025,82.5,81.833\n';

      final result = CsvService.parseCsvContent(csv, 'dd/MM/yyyy');

      expect(result.errors, isEmpty);
      expect(result.entries, hasLength(1));
      expect(result.entries.first.weight, 82.5);
    });

    test('ignores Average column with semicolon delimiter', () {
      const csv = 'Date;Weight;Average\n03/06/2026;78,0;77,5\n';

      final result = CsvService.parseCsvContent(csv, 'dd/MM/yyyy');

      expect(result.errors, isEmpty);
      expect(result.entries.single.weight, 78.0);
    });

    test('normalizes imported dates to UTC midnight', () {
      const csv = 'Date,Weight\n01/06/2025,82.5\n';

      final result = CsvService.parseCsvContent(csv, 'dd/MM/yyyy');
      final date = result.entries.single.date;

      expect(date, normalizeDate(date));
      expect(date.isUtc, isTrue);
    });

    test('skips trailing empty Excel rows', () {
      const csv = 'Date;Weight\n03/06/2026;78,0\n;\n;\n';

      final result = CsvService.parseCsvContent(csv, 'dd/MM/yyyy');

      expect(result.errors, isEmpty);
      expect(result.entries, hasLength(1));
      expect(result.entries.single.weight, 78.0);
    });

    test('rejects invalid weight values', () {
      const csv = 'Date,Weight\n01/06/2025,not-a-number\n';

      final result = CsvService.parseCsvContent(csv, 'dd/MM/yyyy');

      expect(result.entries, isEmpty);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('invalid weight'));
    });

    test('rejects missing header columns', () {
      const csv = 'Date\n01/06/2025\n';

      final result = CsvService.parseCsvContent(csv, 'dd/MM/yyyy');

      expect(result.entries, isEmpty);
      expect(result.errors.first, contains('Invalid header'));
    });

    test('rejects empty file', () {
      final result = CsvService.parseCsvContent('', 'dd/MM/yyyy');

      expect(result.entries, isEmpty);
      expect(result.errors.first, contains('empty'));
    });
  });

  group('CsvService.validateCsvContent', () {
    test('returns valid result for importable file', () {
      const csv = 'Date,Weight\n01/06/2025,82.5\n';

      final result = CsvService.validateCsvContent(csv, 'dd/MM/yyyy');

      expect(result.isValid, isTrue);
      expect(result.entryCount, 1);
    });
  });

  group('CsvService.buildCsvContent', () {
    test('produces 3-column header and correct row count', () {
      final entries = [
        WeightEntry(weight: 82.5, date: DateTime(2025, 6, 1)),
        WeightEntry(weight: 82.1, date: DateTime(2025, 6, 2)),
      ];

      final csv = CsvService.buildCsvContent(entries, 'dd/MM/yyyy', 5);
      final lines = csv.trim().split('\n');

      expect(lines.first, 'Date,Weight,Average');
      expect(lines, hasLength(3));
    });

    test('round-trips export through import with Average ignored', () {
      final entries = [
        WeightEntry(weight: 82.5, date: DateTime(2025, 6, 1)),
        WeightEntry(weight: 82.1, date: DateTime(2025, 6, 2)),
        WeightEntry(weight: 81.8, date: DateTime(2025, 6, 3)),
      ];

      final exported = CsvService.buildCsvContent(entries, 'dd/MM/yyyy', 2);
      final imported = CsvService.parseCsvContent(exported, 'dd/MM/yyyy');

      expect(imported.errors, isEmpty);
      expect(imported.entries, hasLength(entries.length));

      for (var i = 0; i < entries.length; i++) {
        expect(imported.entries[i].weight, entries[i].weight);
        expect(
          imported.entries[i].date.dateOnly,
          normalizeDate(entries[i].date),
        );
      }
    });

    test('includes average values for entries with history', () {
      final entries = [
        WeightEntry(weight: 80.0, date: DateTime(2025, 6, 1)),
        WeightEntry(weight: 82.0, date: DateTime(2025, 6, 2)),
      ];

      final csv = CsvService.buildCsvContent(entries, 'yyyy-MM-dd', 2);
      final lines = csv.trim().split('\n');

      expect(lines[1].endsWith(',80.0'), isTrue);
      expect(lines[2].split(',').last.isNotEmpty, isTrue);
    });
  });

  group('CsvService.generateDefaultFilename', () {
    test('returns csv filename with timestamp pattern', () {
      final fileName = CsvService.generateDefaultFilename();

      expect(fileName, startsWith('weight_data_'));
      expect(fileName, endsWith('.csv'));
    });
  });
}
