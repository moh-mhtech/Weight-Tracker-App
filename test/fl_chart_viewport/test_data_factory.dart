import 'package:fl_chart/fl_chart.dart';

import 'package:weight_graph/fl_chart_viewport/axis_chart_domain.dart';

const double oneDayMs = Duration.millisecondsPerDay * 1.0;
const double halfDayMs = oneDayMs / 2;

/// Synthetic daily spots spanning [spanDays] days ending at [endDate].
List<FlSpot> spotsForSpanDays(int spanDays, {DateTime? endDate}) {
  final end = endDate ?? DateTime.utc(2024, 6, 30);
  final start = end.subtract(Duration(days: spanDays - 1));
  final spots = <FlSpot>[];
  for (var i = 0; i < spanDays; i++) {
    final date = start.add(Duration(days: i));
    spots.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), 70.0 + i * 0.01));
  }
  return spots;
}

AxisChartDomain domainForSpots(List<FlSpot> spots, {double minY = 60, double maxY = 90}) {
  if (spots.isEmpty) {
    return AxisChartDomain(minX: 0, maxX: 1, minY: minY, maxY: maxY);
  }
  final xs = spots.map((s) => s.x);
  final minX = xs.reduce((a, b) => a < b ? a : b);
  final maxX = xs.reduce((a, b) => a > b ? a : b);
  return AxisChartDomain(
    minX: minX - halfDayMs,
    maxX: maxX + halfDayMs,
    minY: minY,
    maxY: maxY,
  );
}

enum WeekPosition { first, middle, last }

/// Returns a 7-day window within the domain for the given position.
(double, double) weekWindow(AxisChartDomain domain, WeekPosition position) {
  final span = domain.deltaX;
  const weekMs = 7 * oneDayMs;
  final effectiveWeek = weekMs < span ? weekMs : span * 0.5;

  switch (position) {
    case WeekPosition.first:
      return (domain.minX, domain.minX + effectiveWeek);
    case WeekPosition.middle:
      final mid = domain.minX + span / 2;
      return (mid - effectiveWeek / 2, mid + effectiveWeek / 2);
    case WeekPosition.last:
      return (domain.maxX - effectiveWeek, domain.maxX);
  }
}

FlTitlesData defaultTitlesData() {
  return FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: true, reservedSize: 30),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: true, reservedSize: 28),
    ),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );
}

FlTitlesData wideLeftTitlesData() {
  return FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: true, reservedSize: 50),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: true, reservedSize: 28),
    ),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );
}
