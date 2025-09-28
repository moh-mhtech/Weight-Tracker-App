import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/weight_entry.dart';

class WeightChart extends StatefulWidget {
  final List<WeightEntry> weightEntries;

  const WeightChart({super.key, required this.weightEntries});

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  static const int _visibleDays = 14; // Number of days to show at once

  @override
  Widget build(BuildContext context) {
    if (widget.weightEntries.isEmpty) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No weight data available.\nAdd some weight entries to see the chart.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
    
    // Calculate the 14-day period ending at the latest measurement
    final endDate = DateTime(latestDate.year, latestDate.month, latestDate.day);
    final startDate = endDate.subtract(const Duration(days: 13));
    
    // Filter entries to the 14-day period
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

    // Calculate running averages for the visible period
    final runningAverages = _calculateRunningAveragesForPeriod(
      dailyAverages, 
      startDate, 
      endDate,
    );

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
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
                          horizontalInterval: 1,
                          verticalInterval: 1,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toStringAsFixed(1)}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1, // Show every day
                              getTitlesWidget: (value, meta) {
                                final dayIndex = value.toInt();
                                if (dayIndex >= 0 && dayIndex < _visibleDays) {
                                  final date = startDate.add(Duration(days: dayIndex));
                                  return Text(
                                    DateFormat('dd/MM').format(date),
                                    style: const TextStyle(fontSize: 10),
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
                        minY: _getMinWeight(periodEntries) - 1,
                        maxY: _getMaxWeight(periodEntries) + 1,
                        lineBarsData: [
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
                                  color: Colors.blue,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(show: false),
                            preventCurveOverShooting: false,
                          ),
                          // Running average line
                          LineChartBarData(
                            spots: _calculateRunningAverageSpots(runningAverages, startDate),
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
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
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Measurements'),
                const SizedBox(width: 24),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('5-Day Average'),
              ],
            ),
          ],
        ),
      ),
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

  List<FlSpot> _calculateRunningAverageSpots(List<double> runningAverages, DateTime startDate) {
    final spots = <FlSpot>[];
    
    for (int i = 0; i < runningAverages.length && i < _visibleDays; i++) {
      spots.add(FlSpot(i.toDouble(), runningAverages[i]));
    }
    
    return spots;
  }

  List<double> _calculateRunningAveragesForPeriod(
    List<WeightEntry> dailyAverages, 
    DateTime startDate, 
    DateTime endDate,
  ) {
    final averages = <double>[];
    
    // Generate running averages for each day in the 14-day period
    for (int day = 0; day < 14; day++) {
      final currentDate = startDate.add(Duration(days: day));
      final startRangeDate = currentDate.subtract(const Duration(days: 4));
      
      final relevantDailyAverages = dailyAverages.where((entry) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        return entryDate.isAfter(startRangeDate.subtract(const Duration(days: 1))) &&
               entryDate.isBefore(currentDate.add(const Duration(days: 1)));
      }).toList();
      
      if (relevantDailyAverages.isNotEmpty) {
        final sum = relevantDailyAverages.fold<double>(0, (sum, entry) => sum + entry.weight);
        averages.add(sum / relevantDailyAverages.length);
      } else {
        // If no data for this day, use the previous average or 0
        averages.add(averages.isNotEmpty ? averages.last : 0.0);
      }
    }
    
    return averages;
  }

  double _getMinWeight(List<WeightEntry> entries) {
    if (entries.isEmpty) return 0;
    return entries.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxWeight(List<WeightEntry> entries) {
    if (entries.isEmpty) return 100;
    return entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
  }
}