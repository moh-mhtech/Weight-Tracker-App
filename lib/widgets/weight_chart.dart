import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weight_entry.dart';
import '../providers/settings_provider.dart';

class WeightChart extends StatefulWidget {
  final List<WeightEntry> weightEntries;

  const WeightChart({super.key, required this.weightEntries});

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  static const int _visibleDays = 7; // Number of days to show at once

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        if (widget.weightEntries.isEmpty) {
          return Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No weight data available.\nAdd some weight entries to see the chart.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSecondary),
                ),
              ),
            ),
          );
        }

        // Sort entries by date
        final sortedEntries = List<WeightEntry>.from(widget.weightEntries)
          ..sort((a, b) => a.date.compareTo(b.date));

        // Find the latest measurement date
        final latestDate = sortedEntries.last.date;
        
        // Calculate the 7-day period ending at the latest measurement
        final endDate = DateTime(latestDate.year, latestDate.month, latestDate.day);
        final startDate = endDate.subtract(const Duration(days: 6));
        
        // Filter entries to the 7-day period
        final periodEntries = sortedEntries.where((entry) {
          final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
          return entryDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                 entryDate.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();

        if (periodEntries.isEmpty) {
          return const Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No data available for the selected period.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          );
        }

        // Group entries by date for running average calculation
        final Map<String, List<WeightEntry>> dailyGroups = {};
        for (final entry in sortedEntries) {
          final dateKey = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
          dailyGroups.putIfAbsent(dateKey, () => []).add(entry);
        }

        // Calculate daily averages for running average calculation
        final List<WeightEntry> dailyAverages = [];
        dailyGroups.forEach((dateKey, dayEntries) {
          final sum = dayEntries.fold<double>(0, (sum, entry) => sum + entry.weight);
          final average = sum / dayEntries.length;
          dailyAverages.add(WeightEntry(
            weight: average,
            date: dayEntries.first.date,
          ));
        });

        // Sort daily averages by date
        dailyAverages.sort((a, b) => a.date.compareTo(b.date));

        // No need to pre-calculate running averages - we'll calculate them per data point

        return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Average Weight Label
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${settingsProvider.runningAverageDays}-day Average: ${_getLatestAverageWeight(periodEntries, settingsProvider.runningAverageDays).toStringAsFixed(1)} ${settingsProvider.weightUnit}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 220,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate responsive day width based on available space
                  final availableWidth = constraints.maxWidth; // Use full available width
                  
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(), // Disable built-in scrolling
                    child: SizedBox(
                      width: availableWidth,
                      child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 0.5,
                          verticalInterval: 1,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                // Only show labels at 0.5 intervals
                                if (value % 0.5 != 0) {
                                  return const SizedBox.shrink();
                                }
                                
                                // Hide labels for min and max values
                                final minWeight = _getMinWeight(periodEntries) - 0.2;
                                final maxWeight = _getMaxWeight(periodEntries) + 0.2;
                                
                                if (value == minWeight || value == maxWeight) {
                                  return const SizedBox.shrink(); // Hide min/max labels
                                }
                                
                                return Text(value.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 1, // Show every day
                              getTitlesWidget: (value, meta) {
                                final dayIndex = value.toInt();
                                if (dayIndex >= 0 && dayIndex < _visibleDays) {
                                  final date = startDate.add(Duration(days: dayIndex));
                                  return Transform.rotate(
                                    angle: -0.8, // Rotate -0.5 radians (about -28 degrees)
                                    child: Text(
                                      DateFormat('dd MMM').format(date).toLowerCase(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        minX: 0,
                        maxX: (_visibleDays - 1).toDouble(),
                        minY: _getMinWeight(periodEntries) - 0.2,
                        maxY: _getMaxWeight(periodEntries) + 0.2,
                        lineBarsData: [
                          // Running average line
                          LineChartBarData(
                            spots: _calculateRunningAverageSpots(periodEntries, startDate, settingsProvider.runningAverageDays),
                            isCurved: true,
                            color: Theme.of(context).colorScheme.tertiary, // Tertiary orange for moving average
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                          // Individual measurements as dots (no lines, no tooltips)
                          LineChartBarData(
                            spots: _calculateMeasurementSpots(periodEntries, startDate),
                            isCurved: false,
                            color: Colors.transparent, // Make line transparent
                            barWidth: 0, // No line width
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeWidth: 2,
                                  strokeColor: Colors.grey[100]!,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(show: false),
                            preventCurveOverShooting: false,
                          ),
                          ],
                        lineTouchData: LineTouchData(
                          enabled: false,
                        ),
                      ),
                    ),
                  ),
                );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Measurements'),
                const SizedBox(width: 24),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${settingsProvider.runningAverageDays}-day Average'),
              ],
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  List<FlSpot> _calculateMeasurementSpots(List<WeightEntry> entries, DateTime startDate) {
    final spots = <FlSpot>[];
    
    for (final entry in entries) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      final daysFromStart = entryDate.difference(startDate).inDays;
      
      if (daysFromStart >= 0 && daysFromStart < _visibleDays) {
        spots.add(FlSpot(daysFromStart.toDouble(), entry.weight));
      }
    }
    
    return spots;
  }

  List<FlSpot> _calculateRunningAverageSpots(List<WeightEntry> periodEntries, DateTime startDate, int runningAverageDays) {
    final spots = <FlSpot>[];
    
    // Calculate running average for each actual data point
    for (int i = 0; i < periodEntries.length; i++) {
      final entry = periodEntries[i];
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      
      // Calculate running average for this specific entry
      final runningAvg = _calculateRunningAverageForEntry(periodEntries, entryDate, runningAverageDays);
      
      // Calculate X position based on days from start date
      final daysFromStart = entryDate.difference(startDate).inDays;
      spots.add(FlSpot(daysFromStart.toDouble(), runningAvg));
    }
    
    return spots;
  }

  double _calculateRunningAverageForEntry(List<WeightEntry> entries, DateTime targetDate, int runningAverageDays) {
    // Get all entries within the configured days before the target date (including the target date)
    final startRangeDate = targetDate.subtract(Duration(days: runningAverageDays - 1));
    
    final relevantEntries = entries.where((entry) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      return entryDate.isAfter(startRangeDate.subtract(const Duration(days: 1))) &&
             entryDate.isBefore(targetDate.add(const Duration(days: 1)));
    }).toList();
    
    if (relevantEntries.isEmpty) {
      return 0.0;
    }
    
    final sum = relevantEntries.fold<double>(0, (sum, entry) => sum + entry.weight);
    return sum / relevantEntries.length;
  }

  double _getMinWeight(List<WeightEntry> entries) {
    if (entries.isEmpty) return 0;
    return entries.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxWeight(List<WeightEntry> entries) {
    if (entries.isEmpty) return 100;
    return entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
  }

  double _getLatestAverageWeight(List<WeightEntry> entries, int runningAverageDays) {
    if (entries.isEmpty) return 0.0;
    
    // Get the latest entry date
    final latestDate = entries.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
    
    // Calculate the running average for the latest date
    return _calculateRunningAverageForEntry(entries, latestDate, runningAverageDays);
  }
}