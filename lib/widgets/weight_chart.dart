import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weight_entry.dart';
import '../providers/settings_provider.dart';
import '../services/average_calculation_service.dart';
import 'chart_sample.dart';

class WeightChart extends StatefulWidget {
  final List<WeightEntry> weightEntries;

  const WeightChart({super.key, required this.weightEntries});

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
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
        final allEntries = List<WeightEntry>.from(widget.weightEntries)
          ..sort((a, b) => a.date.compareTo(b.date));

        // Find the latest measurement date
        final latestDate = allEntries.last.date;
        
        // Calculate the 7-day period ending at the latest measurement
        final endDate = DateTime(latestDate.year, latestDate.month, latestDate.day);
        final startDate = endDate.subtract(const Duration(days: 6));

        // Calculate running averages on all entries (already returns sorted)
        final runningAverages = AverageCalculationService.calcDateAverages(
          allEntries,
          settingsProvider.runningAverageDays,
        );

        // Get the latest running average for the label (from all data)
        final latestDateNormalized = DateTime(allEntries.last.date.year, allEntries.last.date.month, allEntries.last.date.day);
        final latestRunningAverage = runningAverages[latestDateNormalized] ?? 0.0;

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
                '${settingsProvider.runningAverageDays}-day Average: ${latestRunningAverage.toStringAsFixed(1)} ${settingsProvider.weightUnit}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            LineChartSample12(weightEntries: widget.weightEntries),
            
            // SizedBox(
            //   height: 220,
            //   child: LayoutBuilder(
            //     builder: (context, constraints) {
            //       // Calculate responsive day width based on available space
            //       final availableWidth = constraints.maxWidth; // Use full available width
                  
            //       return SingleChildScrollView(
            //         scrollDirection: Axis.horizontal,
            //         physics: const NeverScrollableScrollPhysics(), // Disable built-in scrolling
            //         child: SizedBox(
            //           width: availableWidth,
            //           child: LineChart(
            //           LineChartData(
            //             gridData: FlGridData(
            //               show: true,
            //               horizontalInterval: 0.5,
            //               verticalInterval: 1,
            //             ),
            //             titlesData: FlTitlesData(
            //               leftTitles: AxisTitles(
            //                 sideTitles: SideTitles(
            //                   showTitles: true,
            //                   reservedSize: 40,
            //                   getTitlesWidget: (value, meta) {
            //                     // Only show labels at 0.5 intervals
            //                     if (value % 0.5 != 0) {
            //                       return const SizedBox.shrink();
            //                     }
                                
            //                     // Hide labels for min and max values
            //                     final minWeight = _getMinWeight(allEntries) - 0.2;
            //                     final maxWeight = _getMaxWeight(allEntries) + 0.2;
                                
            //                     if (value == minWeight || value == maxWeight) {
            //                       return const SizedBox.shrink(); // Hide min/max labels
            //                     }
                                
            //                     return Text(value.toStringAsFixed(1),
            //                       style: const TextStyle(fontSize: 10),
            //                     );
            //                   },
            //                 ),
            //               ),
            //               bottomTitles: AxisTitles(
            //                 sideTitles: SideTitles(
            //                   showTitles: true,
            //                   reservedSize: 40,
            //                   interval: 86400000, // 1 day in milliseconds
            //                   getTitlesWidget: (value, meta) {
            //                     final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
            //                     return Transform.rotate(
            //                       angle: -0.8, // Rotate -0.8 radians (about -45 degrees)
            //                       child: Text(min
            //                         DateFormat('dd MMM').format(date).toLowerCase(),
            //                         style: const TextStyle(fontSize: 10),
            //                       ),
            //                     );
            //                   },
            //                 ),
            //               ),
            //               topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            //               rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            //             ),
            //             borderData: FlBorderData(show: true),
            //             minX: startDate.millisecondsSinceEpoch.toDouble(),
            //             maxX: endDate.millisecondsSinceEpoch.toDouble(),
            //             minY: _getMinWeight(allEntries) - 0.2,
            //             maxY: _getMaxWeight(allEntries) + 0.2,
            //             lineBarsData: [
            //               // Running average line
            //               LineChartBarData(
            //                 spots: runningAverages.entries
            //                     .where((entry) => entry.value > 0)
            //                     .map((entry) => FlSpot(entry.key.millisecondsSinceEpoch.toDouble(), entry.value))
            //                     .toList(),
            //                 isCurved: true,
            //                 color: Theme.of(context).colorScheme.tertiary, // Tertiary orange for moving average
            //                 barWidth: 2,
            //                 isStrokeCapRound: true,
            //                 dotData: const FlDotData(show: false),
            //                 belowBarData: BarAreaData(show: false),
            //               ),
            //               // Individual measurements as dots (no lines, no tooltips)
            //               LineChartBarData(
            //                 spots: allEntries.map((entry) => FlSpot(entry.date.millisecondsSinceEpoch.toDouble(), entry.weight)).toList(),
            //                 isCurved: false,
            //                 color: Colors.transparent, // Make line transparent
            //                 barWidth: 0, // No line width
            //                 isStrokeCapRound: true,
            //                 dotData: FlDotData(
            //                   show: true,
            //                   getDotPainter: (spot, percent, barData, index) {
            //                     return FlDotCirclePainter(
            //                       radius: 4,
            //                       color: Theme.of(context).colorScheme.primary,
            //                       strokeWidth: 2,
            //                       strokeColor: Colors.grey[100]!,
            //                     );
            //                   },
            //                 ),
            //                 belowBarData: BarAreaData(show: false),
            //                 preventCurveOverShooting: false,
            //               ),
            //               ],
            //             lineTouchData: LineTouchData(
            //               enabled: false,
            //             ),
            //           ),
            //         ),
            //       ),
            //     );
            //     },
            //   ),
            // ),
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

  double _getMinWeight(List<WeightEntry> entries) {
    if (entries.isEmpty) return 0;
    return entries.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxWeight(List<WeightEntry> entries) {
    if (entries.isEmpty) return 100;
    return entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
  }
}