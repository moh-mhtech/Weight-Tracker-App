import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weight_entry.dart';
import '../providers/settings_provider.dart';
import '../services/average_calculation_service.dart';
import '../services/chart_viewport_service.dart';

// Chart configuration constants
const double _graphTimePadding = Duration.millisecondsPerDay / 2;
const double _graphWeightPadding = 0.2;
const double _graphVisibleDuration = 10 * Duration.millisecondsPerDay + 2 * _graphTimePadding;
const double _leftTitleWidth = 28.0;

class WeightChart extends StatefulWidget {
  final List<WeightEntry> weightEntries;

  const WeightChart({super.key, required this.weightEntries});

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  late TransformationController _transformationController;
  double _chartWidth = 280.0;
  bool _initialTransformationApplied = false;
  List<WeightEntry> _chartEntries = [];
  bool _isLoadingMore = false;
  bool _isAdjustingTransformation = false;

  // Cached running averages - computed once per build
  Map<DateTime, double> _cachedRunningAverages = {};
  int _cachedAverageDays = 0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
    _initializeChartEntries();
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WeightChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weightEntries.length != oldWidget.weightEntries.length) {
      _initializeChartEntries();
      _initialTransformationApplied = false;
      _invalidateAveragesCache();
    }
  }

  // --- Data Management ---

  void _initializeChartEntries() {
    if (widget.weightEntries.isEmpty) {
      _chartEntries = [];
      return;
    }

    final sorted = List<WeightEntry>.from(widget.weightEntries)
      ..sort((a, b) => b.date.compareTo(a.date));

    _chartEntries = sorted.take(20).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    _invalidateAveragesCache();
  }

  void _loadMoreEntries(DateTime preserveMinDate, DateTime preserveMaxDate) {
    final hasMoreData = _chartEntries.length < widget.weightEntries.length;
    if (!hasMoreData || _isLoadingMore) return;

    _isLoadingMore = true;

    final sorted = List<WeightEntry>.from(widget.weightEntries)
      ..sort((a, b) => b.date.compareTo(a.date));

    final newCount = _chartEntries.length + 20;
    _chartEntries = sorted.take(newCount).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    _invalidateAveragesCache();

    _isAdjustingTransformation = true;
    _adjustTransformationForDates(preserveMinDate, preserveMaxDate);
    _isAdjustingTransformation = false;

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isLoadingMore = false;
    });
  }

  // --- Running Averages Cache ---

  void _invalidateAveragesCache() {
    _cachedRunningAverages = {};
    _cachedAverageDays = 0;
  }

  Map<DateTime, double> _getRunningAverages(int days) {
    if (_cachedAverageDays != days || _cachedRunningAverages.isEmpty) {
      _cachedRunningAverages = AverageCalculationService.calcDateAverages(_chartEntries, days);
      _cachedAverageDays = days;
    }
    return _cachedRunningAverages;
  }

  // --- Viewport & Transformation ---

  double get _contentWidth => _chartWidth - _leftTitleWidth;

  ChartViewport _createViewport() {
    final (minTime, maxTime) = _getTimeRange();
    return ChartViewport(
      dataMin: minTime - _graphTimePadding,
      dataMax: maxTime + _graphTimePadding,
      viewportWidth: _contentWidth,
    );
  }

  void _adjustTransformationForDates(DateTime targetMinDate, DateTime targetMaxDate) {
    final viewport = _createViewport();
    _transformationController.value = viewport.buildTransformationForRange(
      targetMinDate.millisecondsSinceEpoch.toDouble(),
      targetMaxDate.millisecondsSinceEpoch.toDouble(),
    );
  }

  void _onTransformationChanged() {
    if (_chartEntries.isEmpty || _isAdjustingTransformation) return;

    final viewport = _createViewport();
    final (visibleMinX, visibleMaxX) = viewport.getVisibleDataRange(_transformationController);

    final newVisibleMinDate = DateTime.fromMillisecondsSinceEpoch(visibleMinX.toInt());
    final newVisibleMaxDate = DateTime.fromMillisecondsSinceEpoch(visibleMaxX.toInt());

    // Check if near left edge to load more data
    final translationX = _transformationController.value.getTranslation().x;
    final hasMoreData = _chartEntries.length < widget.weightEntries.length;
    final nearLeftEdge = translationX > -50;

    if (nearLeftEdge && hasMoreData && !_isLoadingMore) {
      _loadMoreEntries(newVisibleMinDate, newVisibleMaxDate);
    }
  }

  void _updateChartTransformation(double chartWidth) {
    _chartWidth = chartWidth;

    final (minTime, maxTime) = _getTimeRange();
    final dataMaxX = maxTime + _graphTimePadding;
    final totalTimePeriod = maxTime - minTime + 2 * _graphTimePadding;

    if (totalTimePeriod >= _graphVisibleDuration) {
      final targetMaxDate = DateTime.fromMillisecondsSinceEpoch(dataMaxX.toInt());
      final targetMinDate = DateTime.fromMillisecondsSinceEpoch((dataMaxX - _graphVisibleDuration).toInt());
      _adjustTransformationForDates(targetMinDate, targetMaxDate);
    }
  }

  // --- Data Point Calculations ---

  (double, double) _getTimeRange() {
    if (_chartEntries.isEmpty) return (0.0, 0.0);
    final timestamps = _chartEntries.map((e) => e.date.normalizedMillis);
    return getMinMax(timestamps);
  }

  (double, double) _getWeightRange() {
    if (_chartEntries.isEmpty) return (0.0, 0.0);
    final (min, max) = getMinMax(_chartEntries.map((e) => e.weight));
    return (min - _graphWeightPadding, max + _graphWeightPadding);
  }

  List<FlSpot> get _dataPoints {
    return _chartEntries
        .map((e) => FlSpot(e.date.normalizedMillis, e.weight))
        .toList();
  }

  List<FlSpot> _getRunningAverageSpots(int days) {
    return _getRunningAverages(days)
        .entries
        .where((entry) => entry.value > 0)
        .map((entry) => FlSpot(entry.key.normalizedMillis, entry.value))
        .toList();
  }

  // --- Chart Configuration ---

  FlTransformationConfig _getTransformationConfig() {
    return FlTransformationConfig(
      scaleAxis: FlScaleAxis.horizontal,
      minScale: 1.0,
      maxScale: 500.0,
      panEnabled: true,
      scaleEnabled: true,
      transformationController: _transformationController,
    );
  }

  FlGridData _getGridData() {
    return FlGridData(
      show: true,
      horizontalInterval: 0.5,
      verticalInterval: Duration.millisecondsPerDay.toDouble(),
    );
  }

  List<LineChartBarData> _getLineBarsData(int runningAverageDays) {
    return [
      // Weight measurement points
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
      // Running average curve
      LineChartBarData(
        spots: _getRunningAverageSpots(runningAverageDays),
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
          getTitlesWidget: _buildLeftTitle,
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          maxIncluded: false,
          minIncluded: false,
          reservedSize: 28,
          interval: Duration.millisecondsPerDay.toDouble(),
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
        }).toList(),
        getTooltipColor: (_) => Theme.of(context).colorScheme.inversePrimary,
        tooltipBorderRadius: BorderRadius.circular(12),
        tooltipPadding: const EdgeInsets.all(8.0),
      ),
    );
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        if (_chartEntries.isEmpty) {
          return const _EmptyState();
        }

        final runningAverages = _getRunningAverages(settingsProvider.runningAverageDays);
        final latestDate = _chartEntries.last.date.dateOnly;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        _chartWidth = constraints.maxWidth;

        if (!_initialTransformationApplied) {
          _initialTransformationApplied = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateChartTransformation(_chartWidth);
          });
        }

        final (minY, maxY) = _getWeightRange();
        final (minTime, maxTime) = _getTimeRange();
        final timeRange = maxTime - minTime;
        final shouldSetXBounds = timeRange < _graphVisibleDuration;

        return SizedBox(
          width: double.infinity,
          height: 200,
          child: LineChart(
            transformationConfig: _getTransformationConfig(),
            LineChartData(
              borderData: FlBorderData(show: true),
              minY: minY,
              maxY: maxY,
              minX: shouldSetXBounds
                  ? maxTime - _graphVisibleDuration - _graphTimePadding
                  : minTime - _graphTimePadding,
              maxX: maxTime + _graphTimePadding,
              gridData: _getGridData(),
              lineBarsData: _getLineBarsData(settingsProvider.runningAverageDays),
              titlesData: _getTitlesData(),
              lineTouchData: _getLineTouchData(),
            ),
          ),
        );
      },
    );
  }
}

// --- Supporting Widgets ---

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
