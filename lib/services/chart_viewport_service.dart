import 'dart:math';
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

/// Calculates X-axis (time) tick interval based on visible range.
/// Returns interval in milliseconds.
///
/// Behavior (max 16 ticks):
/// - < 16 days visible: 1 day interval
/// - 16-31 days visible: 2 day interval
/// - 32-63 days visible: 4 day interval
/// - 64+ days: continues doubling
double calculateTimeTickInterval(double visibleRangeMs) {
  const double oneDay = Duration.millisecondsPerDay * 1.0;
  const double baseThreshold = 16 * oneDay;

  if (visibleRangeMs < baseThreshold) return oneDay;

  final ratio = visibleRangeMs / baseThreshold;
  final doublings = ratio.floor().bitLength - 1;
  return oneDay * (1 << doublings);
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
