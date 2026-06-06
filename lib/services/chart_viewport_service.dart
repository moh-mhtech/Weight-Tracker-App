import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Normalizes a DateTime to midnight UTC (removes time component).
/// This ensures consistent date comparisons and chart positioning.
DateTime normalizeDate(DateTime date) {
  return DateTime.utc(date.year, date.month, date.day);
}

/// Extension on DateTime for convenient date normalization.
extension DateNormalization on DateTime {
  /// Returns this date normalized to midnight UTC.
  DateTime get dateOnly => DateTime.utc(year, month, day);

  /// Returns the milliseconds since epoch for the normalized date.
  double get normalizedMillis => dateOnly.millisecondsSinceEpoch.toDouble();
}

/// Calculates the min and max values from a list of doubles.
/// Returns (min, max) tuple, or (0.0, 0.0) if empty.
(double, double) getMinMax(Iterable<double> values) {
  if (values.isEmpty) return (0.0, 0.0);

  final list = values.toList();
  final min = list.reduce((a, b) => a < b ? a : b);
  final max = list.reduce((a, b) => a > b ? a : b);

  return (min, max);
}

/// Y-axis padding above/below the min/max of viewed measurements and averages.
/// Returns 0.5 for kg and 1.0 for lbs.
double chartWeightPaddingForUnit(String unit) {
  return unit == 'lbs' ? 1.0 : 0.5;
}

/// Calculates X-axis (time) tick interval from visible range and plot width.
/// Returns interval in milliseconds.
///
/// Plot width sets the maximum tick count (48px per label). Uses 1-day ticks
/// while the visible range fits within that cap; otherwise doubles the interval
/// (2d, 4d, 8d …) until tick count is within the cap.
double calculateTimeTickInterval({
  required double visibleRangeMs,
  required double plotWidthPx,
  double minLabelSpacingPx = 18,
  int minTicks = 3,
}) {
  const double oneDay = Duration.millisecondsPerDay * 1.0;
  if (visibleRangeMs <= 0 || plotWidthPx <= 0) return oneDay;

  final maxTicks = max(minTicks, (plotWidthPx / minLabelSpacingPx).floor());

  if (visibleRangeMs <= maxTicks * oneDay) return oneDay;

  var interval = oneDay;
  while (visibleRangeMs / interval > maxTicks) {
    interval *= 2;
  }
  return interval;
}

/// Calculates "nice" Y-axis intervals for the given range.
/// Returns (tickInterval, gridInterval) where gridInterval = tickInterval / 2.
///
/// Targets ~6 ticks, with a minimum of 3 ticks guaranteed.
/// Uses a "nice numbers" algorithm to find intervals like 0.5, 1, 2, 5, 10, etc.
(double, double) calculateWeightIntervals(double minY, double maxY) {
  final range = maxY - minY;
  if (range <= 0) return (1.0, 0.5);

  final rawInterval = range / 6;
  final magnitude = pow(10, (log(rawInterval) / ln10).floor()).toDouble();
  final normalized = rawInterval / magnitude;

  double niceInterval;
  if (normalized <= 1) {
    niceInterval = magnitude;
  } else if (normalized <= 2) {
    niceInterval = 2 * magnitude;
  } else if (normalized <= 5) {
    niceInterval = 5 * magnitude;
  } else {
    niceInterval = 10 * magnitude;
  }

  final maxInterval = range / 3;
  if (niceInterval > maxInterval) {
    niceInterval = maxInterval;
  }

  return (niceInterval, niceInterval / 2);
}

/// Returns chart X-axis bounds for LineChartData minX/maxX.
(double minX, double maxX) getChartXBounds({
  required double minTime,
  required double maxTime,
  required double visibleDuration,
  required double timePadding,
}) {
  final timeRange = maxTime - minTime;
  final minX = timeRange < visibleDuration
      ? maxTime - visibleDuration - timePadding
      : minTime - timePadding;
  final maxX = maxTime + timePadding;
  return (minX, maxX);
}

/// Tracks the leftmost date scrolled to for Y-axis scaling.
/// Only moves earlier; panning back toward recent dates does not shrink it.
double updateMinViewedDateMs({
  required double visibleMinMs,
  double? currentMinViewedMs,
}) {
  if (currentMinViewedMs == null || visibleMinMs < currentMinViewedMs) {
    return visibleMinMs;
  }
  return currentMinViewedMs;
}

/// Splits chart spots into separate segments when consecutive points are more
/// than one calendar day apart.
List<List<FlSpot>> splitSpotsByDayGaps(List<FlSpot> spots) {
  if (spots.isEmpty) return [];

  final sortedSpots = List<FlSpot>.from(spots)
    ..sort((a, b) => a.x.compareTo(b.x));

  final segments = <List<FlSpot>>[];
  var currentSegment = <FlSpot>[sortedSpots.first];

  for (int i = 1; i < sortedSpots.length; i++) {
    final previous = sortedSpots[i - 1];
    final current = sortedSpots[i];
    final gapMs = current.x - previous.x;

    if (gapMs > Duration.millisecondsPerDay) {
      segments.add(currentSegment);
      currentSegment = [current];
    } else {
      currentSegment.add(current);
    }
  }

  segments.add(currentSegment);
  return segments;
}
