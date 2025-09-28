import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/weight_entry.dart';
import '../database/database_helper.dart';

class SampleDataService {
  static final Random _random = Random();
  
  static Future<void> addSampleDataIfNeeded() async {
    // Only add sample data in debug mode
    if (!kDebugMode) return;
    
    final DatabaseHelper dbHelper = DatabaseHelper();
    final existingEntries = await dbHelper.getAllWeightEntries();
    
    // Only add sample data if no entries exist
    if (existingEntries.isNotEmpty) return;
    
    final sampleEntries = _generateSampleData();
    
    for (final entry in sampleEntries) {
      await dbHelper.insertWeightEntry(entry);
    }
  }
  
  static Future<void> regenerateSampleData() async {
    // Only regenerate sample data in debug mode
    if (!kDebugMode) return;
    
    final DatabaseHelper dbHelper = DatabaseHelper();
    final existingEntries = await dbHelper.getAllWeightEntries();
    
    // Clear existing sample data (assuming all entries are sample data if we have 30+ entries)
    if (existingEntries.length >= 30) {
      for (final entry in existingEntries) {
        if (entry.id != null) {
          await dbHelper.deleteWeightEntry(entry.id!);
        }
      }
    }
    
    // Add new sample data
    final sampleEntries = _generateSampleData();
    
    for (final entry in sampleEntries) {
      await dbHelper.insertWeightEntry(entry);
    }
  }
  
  static List<WeightEntry> _generateSampleData() {
    final List<WeightEntry> entries = [];
    final DateTime today = DateTime.now();
    final DateTime startDate = today.subtract(const Duration(days: 39)); // 40 days total
    
    // Linear progression from 85kg to 80kg over 40 days
    const double startWeight = 85.0;
    const double endWeight = 80.0;
    const double totalWeightLoss = startWeight - endWeight;
    const int totalDays = 40;
    
    // Define days to skip (randomly selected) - but ensure we have at least 30 days of data
    final Set<int> skipDays = {3, 7, 12, 18, 25, 35};
    
    // Define continuous days to skip (6 days starting from day 15)
    final Set<int> continuousSkipDays = {15, 16, 17, 18, 19, 20};
    
    // Define days with multiple measurements
    final Map<int, int> multipleMeasurementsDays = {
      5: 2,   // 2 measurements on day 5
      10: 3,  // 3 measurements on day 10
      22: 2,  // 2 measurements on day 22
      28: 2,  // 2 measurements on day 28
      33: 2,  // 2 measurements on day 33
    };
    
    for (int day = 0; day < totalDays; day++) {
      // Skip individual days
      if (skipDays.contains(day)) continue;
      
      // Skip continuous days
      if (continuousSkipDays.contains(day)) continue;
      
      // Calculate base weight for this day (linear progression)
      final double progress = day / (totalDays - 1);
      final double baseWeight = startWeight - (totalWeightLoss * progress);
      
      final DateTime entryDate = startDate.add(Duration(days: day));
      
      // Check if this day has multiple measurements
      final int measurementCount = multipleMeasurementsDays[day] ?? 1;
      
      for (int measurement = 0; measurement < measurementCount; measurement++) {
        // Add random variance of ±0.5kg
        final double variance = (_random.nextDouble() - 0.5) * 1.0; // -0.5 to +0.5
        
        // For multiple measurements on same day, add smaller variance between them
        final double measurementVariance = measurementCount > 1 
            ? (_random.nextDouble() - 0.5) * 0.3 // ±0.3kg between measurements
            : 0.0;
        
        final double finalWeight = baseWeight + variance + measurementVariance;
        
        // Round to 1 decimal place
        final double roundedWeight = (finalWeight * 10).round() / 10;
        
        // For multiple measurements, add some hours to make them different times
        final DateTime measurementTime = measurementCount > 1
            ? entryDate.add(Duration(hours: measurement * 6)) // 6 hours apart
            : entryDate;
        
        entries.add(WeightEntry(
          weight: roundedWeight,
          date: measurementTime,
        ));
      }
    }
    
    return entries;
  }
}
