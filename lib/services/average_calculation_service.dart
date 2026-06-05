import '../models/weight_entry.dart';

typedef _DateCluster = ({DateTime start, DateTime end});

class AverageCalculationService {
  /// Calculates running averages for dates within entry clusters.
  ///
  /// Entry dates are grouped into clusters. A new cluster starts when the
  /// number of calendar days without measurements between consecutive entry
  /// dates exceeds [averagingPeriod]. Averages are computed for every calendar
  /// day from each cluster's first entry date to its last entry date.
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

    final sortedEntries = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final dateMeasurements = <DateTime, List<double>>{};
    for (final entry in sortedEntries) {
      final entryDate = DateTime.utc(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      dateMeasurements.putIfAbsent(entryDate, () => []).add(entry.weight);
    }

    final dateAverages = <DateTime, double>{};
    for (final entry in dateMeasurements.entries) {
      final sum = entry.value.fold<double>(0, (sum, weight) => sum + weight);
      dateAverages[entry.key] = sum / entry.value.length;
    }

    final entryDates = dateMeasurements.keys.toList()..sort();
    final clusters = _buildEntryClusters(entryDates, averagingPeriod);

    final runningAverages = <DateTime, double>{};

    for (final cluster in clusters) {
      double? lastCalculatedAverage;

      for (DateTime currentDate = cluster.start;
          !currentDate.isAfter(cluster.end);
          currentDate = currentDate.add(const Duration(days: 1))) {
        final windowDates = <DateTime>[];
        for (int i = 0; i < averagingPeriod; i++) {
          final date = currentDate.subtract(Duration(days: i));
          if (!date.isBefore(cluster.start) && dateAverages.containsKey(date)) {
            windowDates.add(date);
          }
        }

        if (windowDates.isNotEmpty) {
          final windowAverages =
              windowDates.map((d) => dateAverages[d]!).toList();
          final sum =
              windowAverages.fold<double>(0, (sum, value) => sum + value);
          runningAverages[currentDate] = double.parse(
            (sum / windowAverages.length).toStringAsFixed(3),
          );
          lastCalculatedAverage = runningAverages[currentDate];
        } else if (lastCalculatedAverage != null) {
          runningAverages[currentDate] = lastCalculatedAverage;
        }
      }
    }

    return runningAverages;
  }

  static List<_DateCluster> _buildEntryClusters(
    List<DateTime> entryDates,
    int averagingPeriod,
  ) {
    if (entryDates.isEmpty) return [];

    final clusters = <_DateCluster>[];
    var clusterStart = entryDates.first;
    var clusterEnd = entryDates.first;

    for (int i = 1; i < entryDates.length; i++) {
      final prev = entryDates[i - 1];
      final current = entryDates[i];
      final gapDays = current.difference(prev).inDays - 1;

      if (gapDays > averagingPeriod) {
        clusters.add((start: clusterStart, end: clusterEnd));
        clusterStart = current;
        clusterEnd = current;
      } else {
        clusterEnd = current;
      }
    }

    clusters.add((start: clusterStart, end: clusterEnd));
    return clusters;
  }
}
