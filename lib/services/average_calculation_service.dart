import '../models/weight_entry.dart';

class AverageCalculationService {
  /// Calculates running averages for all dates from first to last entry
  /// 
  /// [entries] - List of weight entries
  /// [averagingPeriod] - Number of days to include in the running average
  /// 
  /// Returns a map where keys are dates and values are running averages
  static Map<DateTime, double> calcDateAverages(
    List<WeightEntry> entries,
    int averagingPeriod,
  ) {
    if (entries.isEmpty) return {};

    // Sort entries by date
    final sortedEntries = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Create date range from first to last entry
    final firstDate = DateTime(sortedEntries.first.date.year, sortedEntries.first.date.month, sortedEntries.first.date.day);
    final lastDate = DateTime(sortedEntries.last.date.year, sortedEntries.last.date.month, sortedEntries.last.date.day);
    
    // Initialize array of all dates with empty measurement lists
    final Map<DateTime, List<double>> dateMeasurements = {};
    for (DateTime currentDate = firstDate;
         currentDate.isBefore(lastDate.add(const Duration(days: 1)));
         currentDate = currentDate.add(const Duration(days: 1))) {
      dateMeasurements[currentDate] = [];
    }
    
    // Add each entry's weight to all relevant dates (current date and previous dates within averaging period)
    for (final entry in sortedEntries) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      
      // Add this entry's weight to the measurement date
      dateMeasurements[entryDate]!.add(entry.weight);
      
    }

    // Calculate date averages and leave blank for dates without measurements
    final Map<DateTime, double> dateAverages = {};
    for (final currentDate in dateMeasurements.keys) {
      final measurements = dateMeasurements[currentDate]!;
      final sum = measurements.fold<double>(0, (sum, weight) => sum + weight);
      // If measurements is empty, avoid division by zero and do not add an average for this date
      if (measurements.isNotEmpty) {
        dateAverages[currentDate] = sum / measurements.length;
      }
    }
    
    // Calculate running averages for each date by averaging the date averages
    final Map<DateTime, double> runningAverages = {};
    double? lastCalculatedAverage;
    
    for (final currentDate in dateMeasurements.keys) {
      // Extract the list of dates for the averaging window
      final windowDates = <DateTime>[];
      for (int i = 0; i < averagingPeriod; i++) {
        final date = currentDate.subtract(Duration(days: i));
        if (dateAverages.containsKey(date)) {
          windowDates.add(date);
        }
      }
      if (windowDates.isNotEmpty) {
        final windowAverages = windowDates.map((d) => dateAverages[d]!).toList();
        final sum = windowAverages.fold<double>(0, (sum, value) => sum + value);
        runningAverages[currentDate] = double.parse((sum / windowAverages.length).toStringAsFixed(3));
        lastCalculatedAverage = runningAverages[currentDate];
      }
      else {
        runningAverages[currentDate] = lastCalculatedAverage ?? 0.0;
      }
    }
    
    return runningAverages;
  }
}
