import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weight_entry.dart';
import '../providers/settings_provider.dart';
import '../services/average_calculation_service.dart';

class WeightChart extends StatefulWidget {
  final List<WeightEntry> weightEntries;

  const WeightChart({super.key, required this.weightEntries});

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  late TransformationController _transformationController;
  final GlobalKey _chartKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Calculate zoom and translation to show last 7 days using timestamps
    if (widget.weightEntries.length > 7) {
      // Use post-frame callback to ensure the widget is rendered before getting width
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateChartTransformation();
      });
    }
  }

  void _updateChartTransformation() {
    if (widget.weightEntries.length > 7) {
      final entries = widget.weightEntries;
      
      // Calculate zoom to show approximately 7 days (fence post rule)
      final zoomLevel = entries.length / 6.0;
      _transformationController.value = Matrix4.diagonal3Values(zoomLevel, 1.0, 1.0);
  
      final chartWidth = _getChartWidth();
      
      // Calculate timestamps
      final firstTimestamp = entries.first.date.millisecondsSinceEpoch;
      final lastTimestamp = entries.last.date.millisecondsSinceEpoch;
      final timestampRange = lastTimestamp - firstTimestamp;

      // Calculate target position
      final targetTimestamp = lastTimestamp - 7 * Duration.millisecondsPerDay;
      final targetPosition = ((targetTimestamp - firstTimestamp) / timestampRange) * chartWidth;
      final translationX = -targetPosition;

      _transformationController.value *= Matrix4.translationValues(translationX, 0.0, 0.0);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Gets the actual chart width from the widget's render object
  double _getChartWidth() {
    final margin = 24; // Dont know why this isn't 30, from the leftTitles ReservedWidth.
    
    final RenderBox? renderBox = _chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      return renderBox.size.width - margin;
    }
    // Fallback to a reasonable default if widget hasn't been rendered yet
    return 281.6 - margin;
  }

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

  FlTransformationConfig _getTransformationConfig() {
    return FlTransformationConfig(
      scaleAxis: FlScaleAxis.horizontal,
      minScale: 1.0,
      maxScale: 50.0,
      panEnabled: true,
      scaleEnabled: true,
      transformationController: _transformationController,
    );
  }

  FlGridData _getGridData() {
    return FlGridData(
      show: true,
      horizontalInterval: 0.5,
      verticalInterval: const Duration(days: 1).inMilliseconds.toDouble(),
    );
  }

  List<LineChartBarData> _getLineBarsData(SettingsProvider settingsProvider) {
    return [
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
        color: Colors.transparent,
        barWidth: 0,
        belowBarData: BarAreaData(show: false),
      ),
      // Running average curve
      LineChartBarData(
        spots: _getRunningAveragePoints(settingsProvider),
        isCurved: true,
        color: Theme.of(context).colorScheme.tertiary,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
    ];
  }

  FlTitlesData _getTitlesData() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          maxIncluded: false,
          minIncluded: false,
          reservedSize: 30,
          getTitlesWidget: (value, meta) => _buildLeftTitle(value, meta),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          maxIncluded: false,
          minIncluded: false,
          reservedSize: 28,
          interval: 86400000, // 1 day in milliseconds
          getTitlesWidget: (value, meta) => _buildBottomTitle(value, meta),
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _buildLeftTitle(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        value.toStringAsFixed(1),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildBottomTitle(double value, TitleMeta meta) {
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return SideTitleWidget(
      meta: meta,
      child: Transform.rotate(
        angle: -45 * 3.14159 / 180, // -45 degrees in radians
        child: Text(
          DateFormat('dd MMM').format(date).toLowerCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  LineTouchData _getLineTouchData() {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          return touchedBarSpots.map((barSpot) {
            final isRunningAverage = barSpot.barIndex == 1;
            return LineTooltipItem(
              '${barSpot.y.toStringAsFixed(1)} kg',
              TextStyle(
                color: isRunningAverage 
                  ? Theme.of(context).colorScheme.tertiary 
                  : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList();
        },
        getTooltipColor: (LineBarSpot barSpot) => Theme.of(context).colorScheme.inversePrimary,
        tooltipBorderRadius: BorderRadius.circular(12), 
        tooltipPadding: EdgeInsets.all(8.0),// Add rounded corners to the tooltip
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        if (widget.weightEntries.isEmpty) {
          return const _EmptyState();
        }

        // Sort entries by date
        final allEntries = List<WeightEntry>.from(widget.weightEntries)
          ..sort((a, b) => a.date.compareTo(b.date));

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
              padding: const EdgeInsets.only(bottom: 8),
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
            // Interactive Chart with zoom and pan
            Builder(
              builder: (context) {
                final (minY, maxY) = _getWeightRange(widget.weightEntries);
                return SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: LineChart(
                    key: _chartKey,
                    transformationConfig: _getTransformationConfig(),
                    LineChartData(
                      borderData: FlBorderData(show: true),
                      minY: minY,
                      maxY: maxY,
                      gridData: _getGridData(),
                      lineBarsData: _getLineBarsData(settingsProvider),
                      titlesData: _getTitlesData(),
                      lineTouchData: _getLineTouchData(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _ChartLegend(settingsProvider: settingsProvider),
          ],
        ),
      ),
    );
      },
    );
  }

  (double min, double max) _getWeightRange(List<WeightEntry> entries) {
    if (entries.isEmpty) return (0.0, 100.0);
    
    final weights = entries.map((e) => e.weight).toList();
    final min = weights.reduce((a, b) => a < b ? a : b);
    final max = weights.reduce((a, b) => a > b ? a : b);
    
    return (min - 0.2, max + 0.2);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No weight data available.\nAdd some weight entries to see the chart.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16, 
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const _ChartLegend({required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}