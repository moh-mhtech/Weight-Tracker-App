import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weight_entry.dart';
import '../services/average_calculation_service.dart';
import '../providers/settings_provider.dart';

class LineChartSample12 extends StatefulWidget {
  final List<WeightEntry> weightEntries;
  
  const LineChartSample12({super.key, required this.weightEntries});

  @override
  State<LineChartSample12> createState() => _LineChartSample12State();
}

class _LineChartSample12State extends State<LineChartSample12> {
  late TransformationController _transformationController;
  
  List<FlSpot> get _dataPoints {
    return widget.weightEntries.map((weightEntry) {
      // Remove the time part by creating a new DateTime with only year, month, day
      final dateOnly = DateTime(weightEntry.date.year, weightEntry.date.month, weightEntry.date.day);
      final timestamp = dateOnly.millisecondsSinceEpoch.toDouble();
      return FlSpot(timestamp, weightEntry.weight);
    }).toList();
  }

  List<FlSpot> _getRunningAveragePoints(SettingsProvider settingsProvider) {
    final runningAverages = AverageCalculationService.calcDateAverages(
      widget.weightEntries,
      settingsProvider.runningAverageDays,
    );
    return runningAverages.entries
        .where((entry) => entry.value > 0)
        .map((entry) {
          final dateOnly = DateTime(entry.key.year, entry.key.month, entry.key.day);
          final timestamp = dateOnly.millisecondsSinceEpoch.toDouble();
          return FlSpot(timestamp, entry.value);
        })
        .toList();
  }

  @override
  void initState() {
    _transformationController = TransformationController();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Calculate zoom and translation to show last 7 days using timestamps
    if (widget.weightEntries.length > 7) {
      final entries = widget.weightEntries;
      final last7Entries = entries.skip(entries.length - 7).toList();
      
      if (last7Entries.length >= 2) {
        final firstTimestamp = last7Entries.first.date.millisecondsSinceEpoch;
        final lastTimestamp = last7Entries.last.date.millisecondsSinceEpoch;
        
        // Calculate zoom to show approximately 7 days (fence post rule)
        final zoomLevel = entries.length / 6.0;
        
        // Calculate translation to center on the last 7 days
        final centerTimestamp = (firstTimestamp + lastTimestamp) / 2;
        final chartCenter = (entries.first.date.millisecondsSinceEpoch + entries.last.date.millisecondsSinceEpoch) / 2;
        final translationX = -(centerTimestamp - chartCenter) * 0.001; // Scale factor for translation
        
        _transformationController.value = Matrix4.diagonal3Values(zoomLevel, 1.0, 1.0) * 
                                         Matrix4.translationValues(translationX, 0.0, 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tooltipColor = Theme.of(context).colorScheme.inversePrimary;
    
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 200,
          child: Padding(
            padding: EdgeInsets.zero,
            child: LineChart(
          transformationConfig: FlTransformationConfig(
            scaleAxis: FlScaleAxis.horizontal,
            minScale: 1.0,
            maxScale: 50.0, // Increased max scale for better zoom capability
            panEnabled: true,
            scaleEnabled: true,
            transformationController: _transformationController,
          ),
          LineChartData(
            borderData: FlBorderData(show: true),
            minY: _getMinWeight(widget.weightEntries) - 0.2,
            maxY: _getMaxWeight(widget.weightEntries) + 0.2,
            gridData: FlGridData(
              show: true,
              horizontalInterval: 0.5,
              verticalInterval: const Duration(days: 1).inMilliseconds.toDouble(),
            ),
            lineBarsData: [
              // Weight measurement points
              LineChartBarData(
                spots: _dataPoints,
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
                color: Colors.transparent, // Hide the line
                barWidth: 0, // No line width
                belowBarData: BarAreaData(
                  show: false, // Hide the area fill
                ),
              ),
              // Running average curve
              LineChartBarData(
                spots: _getRunningAveragePoints(settingsProvider),
                isCurved: true,
                color: Theme.of(context).colorScheme.tertiary, // Tertiary color for moving average
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false), // Hide dots for the curve
                belowBarData: BarAreaData(show: false),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (value, meta) {
                    // Only show labels at 0.5 intervals
                    if (value % 0.5 != 0) {
                      return const SizedBox.shrink();
                    }
                    
                    // Hide labels for min and max values
                    final minWeight = _getMinWeight(widget.weightEntries) - 0.2;
                    final maxWeight = _getMaxWeight(widget.weightEntries) + 0.2;
                    
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
                  maxIncluded: false,
                  minIncluded: false,
                  reservedSize: 28,
                  interval: 86400000, // 1 day in milliseconds
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    return Transform.rotate(
                      angle: -0.8, // Rotate -0.8 radians (about -45 degrees)
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          DateFormat('dd MMM').format(date).toLowerCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    // Check if this is the running average line (second LineChartBarData)
                    final isRunningAverage = barSpot.barIndex == 1;
                    
                    return LineTooltipItem(
                      isRunningAverage 
                        ? '${barSpot.y.toStringAsFixed(1)} kg'
                        : '${barSpot.y.toStringAsFixed(1)} kg',
                      TextStyle(
                        color: isRunningAverage 
                          ? Theme.of(context).colorScheme.tertiary 
                          : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
                getTooltipColor: (LineBarSpot barSpot) => tooltipColor,
              ),
            ),
          ),
        ),
      ),
      );
      },
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  double _getMinWeight(List<WeightEntry> entries) {
    if (entries.isEmpty) return 0.0;
    return entries.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxWeight(List<WeightEntry> entries) {
    if (entries.isEmpty) return 0.0;
    return entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
  }
}