import 'package:intl/intl.dart';
import '../models/weight_entry.dart';
import 'average_calculation_service.dart';
import 'chart_viewport_service.dart';

class CsvParseResult {
  final List<WeightEntry> entries;
  final List<String> errors;

  const CsvParseResult({required this.entries, required this.errors});

  bool get hasEntries => entries.isNotEmpty;
}

class CsvValidationResult {
  final bool isValid;
  final int entryCount;
  final String? error;

  const CsvValidationResult({
    required this.isValid,
    this.entryCount = 0,
    this.error,
  });
}

class CsvService {
  static const _exportHeader = 'Date,Weight,Average';
  static const _supportedDateFormats = [
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'yyyy-MM-dd',
  ];

  static CsvParseResult parseCsvContent(String content, String dateFormat) {
    var text = content;
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }

    final lines = text
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const CsvParseResult(
        entries: [],
        errors: ['CSV file is empty'],
      );
    }

    final delimiter = _detectDelimiter(lines.first);
    final headerParts = lines.first
        .split(delimiter)
        .map((part) => part.trim().toLowerCase())
        .toList();

    if (headerParts.length < 2 ||
        headerParts[0] != 'date' ||
        !headerParts[1].startsWith('weight')) {
      return const CsvParseResult(
        entries: [],
        errors: ['Invalid header: expected Date and Weight columns'],
      );
    }

    final entries = <WeightEntry>[];
    final errors = <String>[];

    for (var i = 1; i < lines.length; i++) {
      final lineNumber = i + 1;
      final parts = lines[i].split(delimiter);

      if (parts.length < 2) {
        errors.add('Line $lineNumber: insufficient columns');
        continue;
      }

      final dateStr = parts[0].trim();
      final weightStr = parts[1].trim();

      if (dateStr.isEmpty && weightStr.isEmpty) {
        continue;
      }

      final weight = _parseDecimal(weightStr);

      if (weight == null) {
        errors.add('Line $lineNumber: invalid weight "$weightStr"');
        continue;
      }

      try {
        final date = _parseDate(dateStr, dateFormat);
        entries.add(WeightEntry(weight: weight, date: date));
      } catch (_) {
        errors.add('Line $lineNumber: invalid date "$dateStr"');
      }
    }

    return CsvParseResult(entries: entries, errors: errors);
  }

  static CsvValidationResult validateCsvContent(
    String content,
    String dateFormat,
  ) {
    final result = parseCsvContent(content, dateFormat);

    if (result.entries.isEmpty) {
      final error = result.errors.isNotEmpty
          ? result.errors.first
          : 'No data rows found';
      return CsvValidationResult(isValid: false, error: error);
    }

    if (result.errors.isNotEmpty) {
      return CsvValidationResult(
        isValid: false,
        entryCount: result.entries.length,
        error: result.errors.first,
      );
    }

    return CsvValidationResult(
      isValid: true,
      entryCount: result.entries.length,
    );
  }

  static String buildCsvContent(
    List<WeightEntry> entries,
    String dateFormat,
    int averagePeriod,
  ) {
    final sortedEntries = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final averages = AverageCalculationService.calcDateAverages(
      sortedEntries,
      averagePeriod,
    );

    final buffer = StringBuffer()..writeln(_exportHeader);

    for (final entry in sortedEntries) {
      final dateStr = DateFormat(dateFormat).format(entry.date);
      final dateKey = entry.date.dateOnly;
      final average = averages[dateKey];
      final averageStr = average != null ? average.toString() : '';

      buffer.writeln('$dateStr,${entry.weight},$averageStr');
    }

    return buffer.toString();
  }

  static String generateDefaultFilename() {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    return 'weight_data_$timestamp.csv';
  }

  static String _detectDelimiter(String headerLine) {
    final semiParts = headerLine
        .split(';')
        .map((part) => part.trim().toLowerCase())
        .toList();
    if (semiParts.length >= 2 &&
        semiParts[0] == 'date' &&
        semiParts[1].startsWith('weight')) {
      return ';';
    }
    return ',';
  }

  static double? _parseDecimal(String raw) {
    final trimmed = raw.trim();
    if (trimmed.contains(',') && !trimmed.contains('.')) {
      return double.tryParse(trimmed.replaceAll(',', '.'));
    }
    return double.tryParse(trimmed);
  }

  static DateTime _parseDate(String dateStr, String primaryFormat) {
    final formats = [primaryFormat, ..._supportedDateFormats];

    for (final format in formats.toSet()) {
      try {
        final parsed = DateFormat(format).parse(dateStr);
        return normalizeDate(parsed);
      } catch (_) {
        // Try next format.
      }
    }

    throw FormatException('Unable to parse date: $dateStr');
  }
}
