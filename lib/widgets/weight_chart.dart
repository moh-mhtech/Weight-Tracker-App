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
  bool _isPanEnabled = true;
  bool _isScaleEnabled = true;

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

    if (sortedEntries.isEmpty) {
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

    // Find date range for all data
    final earliestDate = sortedEntries.first.date;
    final latestDate = sortedEntries.last.date;
    final totalDays = latestDate.difference(earliestDate).inDays + 1;

    // Group entries by date for running average calculation
    final Map<String, List<WeightEntry>> dailyGroups = {};
    for (final entry in sortedEntries) {
      final dateKey = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
      dailyGroups.putIfAbsent(dateKey, () => []).add(entry);
    }

    // Calculate daily averages
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

    // Calculate running averages for all data
    final runningAverages = _calculateRunningAveragesForAllData(dailyAverages);

    // Calculate all measurement spots
    final allMeasurementSpots = _calculateAllMeasurementSpots(sortedEntries, earliestDate);
    final allRunningAverageSpots = _calculateAllRunningAverageSpots(runningAverages, earliestDate);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
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
                          if (dayIndex >= 0 && dayIndex < totalDays) {
                            final date = earliestDate.add(Duration(days: dayIndex));
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
                  maxX: totalDays - 1.0,
                  minY: _getMinWeight(sortedEntries) - 1,
                  maxY: _getMaxWeight(sortedEntries) + 1,
                  lineBarsData: [
                    // Individual measurements as dots
                    LineChartBarData(
                      spots: allMeasurementSpots,
                      isCurved: false,
                      color: Colors.transparent,
                      barWidth: 0,
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
                    ),
                    // Running average line
                    LineChartBarData(
                      spots: allRunningAverageSpots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blue.withOpacity(0.8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final dayIndex = touchedSpot.x.toInt();
                          final date = earliestDate.add(Duration(days: dayIndex));
                          return LineTooltipItem(
                            '${DateFormat('dd/MM/yyyy').format(date)}\n${touchedSpot.y.toStringAsFixed(1)} kg',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
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
            const SizedBox(height: 8),
            // Pan and Scale controls
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Pan'),
                Switch(
                  value: _isPanEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isPanEnabled = value;
                    });
                  },
                ),
                const SizedBox(width: 16),
                const Text('Scale'),
                Switch(
                  value: _isScaleEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isScaleEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Transformation control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // Zoom in functionality would go here
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    // Zoom out functionality would go here
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Reset functionality would go here
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Drag to pan, pinch to zoom through your weight history',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _calculateAllMeasurementSpots(List<WeightEntry> entries, DateTime startDate) {
    final spots = <FlSpot>[];
    
    for (final entry in entries) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      final daysFromStart = entryDate.difference(startDate).inDays.toDouble();
      spots.add(FlSpot(daysFromStart, entry.weight));
    }
    
    return spots;
  }

  List<FlSpot> _calculateAllRunningAverageSpots(List<double> runningAverages, DateTime startDate) {
    final spots = <FlSpot>[];
    
    for (int i = 0; i < runningAverages.length; i++) {
      spots.add(FlSpot(i.toDouble(), runningAverages[i]));
    }
    
    return spots;
  }

  List<double> _calculateRunningAveragesForAllData(List<WeightEntry> dailyAverages) {
    final averages = <double>[];
    
    // Generate running averages for each day in the dataset
    for (int i = 0; i < dailyAverages.length; i++) {
      final currentDate = dailyAverages[i].date;
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