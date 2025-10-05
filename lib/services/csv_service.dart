import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/weight_entry.dart';

class CsvService {
  static const String _csvHeader = 'Date,Weight,Timestamp';
  
  /// Export weight entries to a CSV file
  static Future<String> exportToCsv(List<WeightEntry> entries, String filePath) async {
    try {
      final file = File(filePath);
      final buffer = StringBuffer();
      
      // Add CSV header
      buffer.writeln(_csvHeader);
      
      // Sort entries by date
      final sortedEntries = List<WeightEntry>.from(entries)
        ..sort((a, b) => a.date.compareTo(b.date));
      
      // Add data rows
      for (final entry in sortedEntries) {
        final dateStr = DateFormat('yyyy-MM-dd').format(entry.date);
        final timeStr = DateFormat('HH:mm:ss').format(entry.date);
        final timestamp = entry.date.millisecondsSinceEpoch;
        
        buffer.writeln('$dateStr,$timeStr,${entry.weight},$timestamp');
      }
      
      // Convert to bytes for mobile platforms
      final csvContent = buffer.toString();
      final bytes = utf8.encode(csvContent);
      
      // Write to file using bytes (required for Android/iOS)
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }
  
  /// Import weight entries from a CSV file
  static Future<List<WeightEntry>> importFromCsv(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }
      
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      if (lines.isEmpty) {
        throw Exception('CSV file is empty');
      }
      
      // Skip header line
      final dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty).toList();
      
      final entries = <WeightEntry>[];
      
      for (int i = 0; i < dataLines.length; i++) {
        try {
          final line = dataLines[i];
          final parts = line.split(',');
          
          if (parts.length < 3) {
            throw Exception('Invalid CSV format at line ${i + 2}: insufficient columns');
          }
          
          // Parse date and time
          final dateStr = parts[0].trim();
          final timeStr = parts[1].trim();
          final weightStr = parts[2].trim();
          
          // Parse weight
          final weight = double.tryParse(weightStr);
          if (weight == null) {
            throw Exception('Invalid weight value at line ${i + 2}: $weightStr');
          }
          
          // Parse date and time
          DateTime date;
          try {
            if (parts.length >= 4) {
              // Use timestamp if available
              final timestamp = int.tryParse(parts[3].trim());
              if (timestamp != null) {
                date = DateTime.fromMillisecondsSinceEpoch(timestamp);
              } else {
                date = _parseDateTime(dateStr, timeStr);
              }
            } else {
              date = _parseDateTime(dateStr, timeStr);
            }
          } catch (e) {
            throw Exception('Invalid date/time format at line ${i + 2}: $dateStr $timeStr');
          }
          
          entries.add(WeightEntry(
            weight: weight,
            date: date,
          ));
        } catch (e) {
          throw Exception('Error parsing line ${i + 2}: $e');
        }
      }
      
      return entries;
    } catch (e) {
      throw Exception('Failed to import CSV: $e');
    }
  }
  
  /// Parse date and time strings into DateTime
  static DateTime _parseDateTime(String dateStr, String timeStr) {
    try {
      // Try different date formats
      final dateFormats = [
        'yyyy-MM-dd',
        'dd/MM/yyyy',
        'MM/dd/yyyy',
        'dd-MM-yyyy',
        'MM-dd-yyyy',
      ];
      
      DateTime? date;
      for (final format in dateFormats) {
        try {
          date = DateFormat(format).parse(dateStr);
          break;
        } catch (e) {
          // Try next format
        }
      }
      
      if (date == null) {
        throw Exception('Unable to parse date: $dateStr');
      }
      
      // Parse time
      final timeFormats = ['HH:mm:ss', 'HH:mm', 'H:mm:ss', 'H:mm'];
      DateTime? time;
      for (final format in timeFormats) {
        try {
          time = DateFormat(format).parse(timeStr);
          break;
        } catch (e) {
          // Try next format
        }
      }
      
      if (time == null) {
        // If time parsing fails, use midnight
        time = DateTime(1970, 1, 1, 0, 0, 0);
      }
      
      // Combine date and time
      return DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
        time.second,
      );
    } catch (e) {
      throw Exception('Failed to parse date/time: $dateStr $timeStr');
    }
  }
  
  /// Generate a default filename with timestamp
  static String generateDefaultFilename() {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    return 'weight_data_$timestamp.csv';
  }
  
  /// Validate CSV content before import
  static Future<bool> validateCsvFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      if (lines.isEmpty) {
        return false;
      }
      
      // Check header
      if (!lines[0].contains('Date') || !lines[0].contains('Weight')) {
        return false;
      }
      
      // Check at least one data line
      final dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty).toList();
      if (dataLines.isEmpty) {
        return false;
      }
      
      // Try to parse first data line
      try {
        final firstLine = dataLines[0];
        final parts = firstLine.split(',');
        if (parts.length < 3) {
          return false;
        }
        
        // Check if weight can be parsed
        final weight = double.tryParse(parts[2].trim());
        if (weight == null) {
          return false;
        }
      } catch (e) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
