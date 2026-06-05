import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weight_entry.dart';
import '../providers/settings_provider.dart';
import '../services/average_calculation_service.dart';
import '../services/chart_viewport_service.dart';
import '../fl_chart_viewport/fl_chart_viewport.dart';

// 11 days of data + 12h padding on each end = 12 calendar days on the axis
const double _graphTimePadding = Duration.millisecondsPerDay / 2;
const double _graphWeightPadding = 0.2;
const double _graphVisibleDuration =
    10 * Duration.millisecondsPerDay + 2 * _graphTimePadding;

class WeightChart extends StatefulWidget {
  final List<WeightEntry> weightEntries;

  const WeightChart({super.key, required this.weightEntries});

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  late AxisChartViewController _viewController;
  bool _initialTransformationApplied = false;

  double? _weightMinY;
  double? _weightMaxY;
  double? _minViewedDateMs;
  int _runningAverageDays = 5;

  Map<DateTime, double> _cachedRunningAverages = {};
  int _cachedAverageDays = 0;

  double _visibleTimeRange = _graphVisibleDuration;

  @override
  void initState() {
    super.initState();
    _viewController = AxisChartViewController(scaleAxis: FlScaleAxis.horizontal);
    _viewController.transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _viewController.transformationController.removeListener(_onTransformationChanged);
    _viewController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WeightChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weightEntries.length != oldWidget.weightEntries.length) {
      _initialTransformationApplied = false;
      _weightMinY = null;
      _weightMaxY = null;
      _minViewedDateMs = null;
      _invalidateAveragesCache();
    }
  }

  List<WeightEntry> get _sortedEntries {
    if (widget.weightEntries.isEmpty) return [];
    return List<WeightEntry>.from(widget.weightEntries)
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  void _invalidateAveragesCache() {
    _cachedRunningAverages = {};
    _cachedAverageDays = 0;
  }

  Map<DateTime, double> _getRunningAverages(int days) {
    if (_cachedAverageDays != days || _cachedRunningAverages.isEmpty) {
      _cachedRunningAverages =
          AverageCalculationService.calcDateAverages(_sortedEntries, days);
      _cachedAverageDays = days;
    }
    return _cachedRunningAverages;
  }

  (double, double) _getFullDataTimeRange() {
    if (_sortedEntries.isEmpty) return (0.0, 0.0);
    final timestamps = _sortedEntries.map((e) => e.date.normalizedMillis);
    return getMinMax(timestamps);
  }

  double get _latestEntryMs => _sortedEntries.last.date.normalizedMillis;

  (double, double) _getChartXBounds() {
    final (minTime, maxTime) = _getFullDataTimeRange();
    return getChartXBounds(
      minTime: minTime,
      maxTime: maxTime,
      visibleDuration: _graphVisibleDuration,
      timePadding: _graphTimePadding,
    );
  }

  AxisChartDomain _getChartDomain(double minY, double maxY) {
    final (minX, maxX) = _getChartXBounds();
    return AxisChartDomain(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  (double, double) _computeWeightRangeForDateWindow(
    double windowMinMs,
    double windowMaxMs,
  ) {
    final values = <double>[];

    for (final entry in _sortedEntries) {
      final ms = entry.date.normalizedMillis;
      if (ms >= windowMinMs && ms <= windowMaxMs) {
        values.add(entry.weight);
      }
    }

    for (final averageEntry in _getRunningAverages(_runningAverageDays).entries) {
      if (averageEntry.value <= 0) continue;
      final ms = averageEntry.key.normalizedMillis;
      if (ms >= windowMinMs && ms <= windowMaxMs) {
        values.add(averageEntry.value);
      }
    }

    if (values.isEmpty) return (0.0, 0.0);
    final (min, max) = getMinMax(values);
    return (min - _graphWeightPadding, max + _graphWeightPadding);
  }

  bool _applyWeightRangeForDateWindow(double windowMinMs, double windowMaxMs) {
    final (newMin, newMax) =
        _computeWeightRangeForDateWindow(windowMinMs, windowMaxMs);
    if (_weightMinY == newMin && _weightMaxY == newMax) return false;
    _weightMinY = newMin;
    _weightMaxY = newMax;
    _viewController.setYViewFromValues(newMin, newMax);
    return true;
  }

  void _recalculateWeightRangeFromViewport() {
    if (_sortedEntries.isEmpty || _minViewedDateMs == null) return;
    _applyWeightRangeForDateWindow(_minViewedDateMs!, _latestEntryMs);
  }

  void _onTransformationChanged() {
    if (_sortedEntries.isEmpty || _viewController.isAdjusting) return;

    final (visibleMinX, visibleMaxX) = _viewController.getVisibleXRange();
    final newVisibleRange = visibleMaxX - visibleMinX;

    _minViewedDateMs = updateMinViewedDateMs(
      visibleMinMs: visibleMinX,
      currentMinViewedMs: _minViewedDateMs,
    );

    final weightRangeChanged = _applyWeightRangeForDateWindow(
      _minViewedDateMs!,
      _latestEntryMs,
    );

    final oldInterval = calculateTimeTickInterval(_visibleTimeRange);
    final newInterval = calculateTimeTickInterval(newVisibleRange);

    if (weightRangeChanged || oldInterval != newInterval) {
      setState(() => _visibleTimeRange = newVisibleRange);
    } else {
      _visibleTimeRange = newVisibleRange;
    }
  }

  void _applyInitialXView() {
    final (minTime, maxTime) = _getFullDataTimeRange();
    if (_sortedEntries.isEmpty) return;

    final dataMaxX = maxTime + _graphTimePadding;
    final totalTimePeriod = maxTime - minTime + 2 * _graphTimePadding;

    if (totalTimePeriod >= _graphVisibleDuration) {
      final targetMaxMs = dataMaxX;
      final targetMinMs = dataMaxX - _graphVisibleDuration;

      _viewController.setXViewFromValues(targetMinMs, targetMaxMs);

      _minViewedDateMs = targetMinMs;
      _applyWeightRangeForDateWindow(targetMinMs, maxTime);
    }
  }

  (double, double) _getWeightRange() {
    if (_weightMinY != null && _weightMaxY != null) {
      return (_weightMinY!, _weightMaxY!);
    }

    if (_sortedEntries.isEmpty) return (0.0, 0.0);
    final latestMs = _latestEntryMs;
    final initialMinMs = latestMs + _graphTimePadding - _graphVisibleDuration;
    return _computeWeightRangeForDateWindow(initialMinMs, latestMs);
  }

  List<FlSpot> get _dataPoints {
    return _sortedEntries
        .map((e) => FlSpot(e.date.normalizedMillis, e.weight))
        .toList();
  }

  List<FlSpot> _getRunningAverageSpots(int days) {
    final spots = _getRunningAverages(days)
        .entries
        .where((entry) => entry.value > 0)
        .map((entry) => FlSpot(entry.key.normalizedMillis, entry.value))
        .toList();
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  List<LineChartBarData> _getRunningAverageBars(int days) {
    final segments = splitSpotsByDayGaps(_getRunningAverageSpots(days));
    final color = Theme.of(context).colorScheme.tertiary;

    return segments
        .map(
          (spots) => LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        )
        .toList();
  }

  FlTransformationConfig _getTransformationConfig() {
    return FlTransformationConfig(
      scaleAxis: FlScaleAxis.horizontal,
      minScale: 1.0,
      maxScale: 500.0,
      panEnabled: true,
      scaleEnabled: true,
      transformationController: _viewController.transformationController,
    );
  }

  FlGridData _getGridData() {
    final timeInterval = calculateTimeTickInterval(_visibleTimeRange);
    final (minY, maxY) = _getWeightRange();
    final (_, weightGridInterval) = calculateWeightIntervals(minY, maxY);

    return FlGridData(
      show: true,
      horizontalInterval: weightGridInterval,
      verticalInterval: timeInterval,
    );
  }

  List<LineChartBarData> _getLineBarsData(int runningAverageDays) {
    return [
      LineChartBarData(
        spots: _dataPoints,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 4,
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 2,
            strokeColor: Colors.grey[100]!,
          ),
        ),
        color: Colors.transparent,
        barWidth: 0,
        belowBarData: BarAreaData(show: false),
      ),
      ..._getRunningAverageBars(runningAverageDays),
    ];
  }

  FlTitlesData _getTitlesData() {
    final timeInterval = calculateTimeTickInterval(_visibleTimeRange);
    final (minY, maxY) = _getWeightRange();
    final (weightTickInterval, _) = calculateWeightIntervals(minY, maxY);

    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          maxIncluded: false,
          minIncluded: false,
          reservedSize: 30,
          interval: weightTickInterval,
          getTitlesWidget: _buildLeftTitle,
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          maxIncluded: false,
          minIncluded: false,
          reservedSize: 28,
          interval: timeInterval,
          getTitlesWidget: _buildBottomTitle,
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _buildLeftTitle(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _buildBottomTitle(double value, TitleMeta meta) {
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return SideTitleWidget(
      meta: meta,
      child: Transform.rotate(
        angle: -45 * 3.14159 / 180,
        child: Text(
          DateFormat('dd MMM').format(date).toLowerCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  LineTouchData _getLineTouchData() {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (touchedBarSpots) => touchedBarSpots.map((barSpot) {
          final isRunningAverage = barSpot.barIndex >= 1;
          return LineTooltipItem(
            '${barSpot.y.toStringAsFixed(1)} kg',
            TextStyle(
              color: isRunningAverage
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
        getTooltipColor: (_) => Theme.of(context).colorScheme.inversePrimary,
        tooltipBorderRadius: BorderRadius.circular(12),
        tooltipPadding: const EdgeInsets.all(8.0),
      ),
    );
  }

  LineChartData _buildLineChartData(ChartPlotMetrics plotMetrics) {
    final (minY, maxY) = _getWeightRange();
    final domain = _getChartDomain(minY, maxY);
    _viewController.updateDomain(domain);

    return LineChartData(
      borderData: FlBorderData(show: true),
      minY: minY,
      maxY: maxY,
      minX: domain.minX,
      maxX: domain.maxX,
      gridData: _getGridData(),
      lineBarsData: _getLineBarsData(_runningAverageDays),
      titlesData: _getTitlesData(),
      lineTouchData: _getLineTouchData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        if (_sortedEntries.isEmpty) {
          return const _EmptyState();
        }

        final runningAverages = _getRunningAverages(settingsProvider.runningAverageDays);
        final latestDate = _sortedEntries.last.date.dateOnly;
        final latestRunningAverage = runningAverages[latestDate] ?? 0.0;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AverageLabel(
                  days: settingsProvider.runningAverageDays,
                  average: latestRunningAverage,
                  unit: settingsProvider.weightUnit,
                ),
                _buildChart(settingsProvider),
                const SizedBox(height: 16),
                _ChartLegend(settingsProvider: settingsProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChart(SettingsProvider settingsProvider) {
    final days = settingsProvider.runningAverageDays;
    if (days != _runningAverageDays) {
      _runningAverageDays = days;
      _invalidateAveragesCache();
      _recalculateWeightRangeFromViewport();
    }

    if (!_initialTransformationApplied) {
      _initialTransformationApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyInitialXView();
          setState(() {});
        }
      });
    }

    return SizedBox(
      width: double.infinity,
      height: 200,
      child: ViewportLineChart(
        controller: _viewController,
        transformationConfig: _getTransformationConfig(),
        dataBuilder: (plotMetrics, _) => _buildLineChartData(plotMetrics),
      ),
    );
  }
}

class _AverageLabel extends StatelessWidget {
  final int days;
  final double average;
  final String unit;

  const _AverageLabel({
    required this.days,
    required this.average,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$days-day Average: ${average.toStringAsFixed(1)} $unit',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        textAlign: TextAlign.center,
      ),
    );
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
        _LegendItem(
          color: Theme.of(context).colorScheme.primary,
          label: 'Measurements',
        ),
        const SizedBox(width: 24),
        _LegendItem(
          color: Theme.of(context).colorScheme.tertiary,
          label: '${settingsProvider.runningAverageDays}-day Average',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
