import 'dart:math';
import 'package:flutter/material.dart';

/// A utility class for handling chart viewport coordinate transformations.
/// 
/// This class encapsulates the math for converting between:
/// - Data coordinates (the actual values being plotted)
/// - Scene coordinates (the chart's internal coordinate system)
/// - Viewport coordinates (screen pixels)
class ChartViewport {
  final double dataMin;
  final double dataMax;
  final double viewportWidth;

  const ChartViewport({
    required this.dataMin,
    required this.dataMax,
    required this.viewportWidth,
  });

  double get dataRange => dataMax - dataMin;

  /// Converts a scene X coordinate to a data value.
  /// Scene coordinates range from [0..viewportWidth].
  double sceneToData(double sceneX) {
    return dataMin + (sceneX / viewportWidth) * dataRange;
  }

  /// Converts a data value to a scene X coordinate.
  /// Returns a value in the range [0..viewportWidth].
  double dataToScene(double dataX) {
    return ((dataX - dataMin) / dataRange) * viewportWidth;
  }

  /// Builds a transformation matrix that displays the specified data range
  /// within the viewport.
  Matrix4 buildTransformationForRange(double targetMin, double targetMax) {
    final targetSceneLeft = dataToScene(targetMin);
    final targetSceneRight = dataToScene(targetMax);
    final targetSceneWidth = targetSceneRight - targetSceneLeft;

    // Scale: how much to zoom so targetSceneWidth fills the viewport
    final scale = viewportWidth / targetSceneWidth;

    // Translation: shift so the left edge of target range is at viewport left
    final translationX = -targetSceneLeft * scale;

    return Matrix4.identity()
      ..scale(scale, 1.0, 1.0)
      ..translate(translationX / scale, 0.0, 0.0);
  }

  /// Gets the currently visible data range from a transformation controller.
  /// Returns (minData, maxData) tuple.
  (double, double) getVisibleDataRange(TransformationController controller) {
    final sceneLeft = controller.toScene(Offset.zero);
    final sceneRight = controller.toScene(Offset(viewportWidth, 0));

    final visibleMin = sceneToData(sceneLeft.dx);
    final visibleMax = sceneToData(sceneRight.dx);

    return (visibleMin, visibleMax);
  }
}

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
  
  // Calculate how many times we've doubled past the threshold
  final ratio = visibleRangeMs / baseThreshold;
  final doublings = ratio.floor().bitLength - 1;
  return oneDay * (1 << doublings); // 1, 2, 4, 8... days
}

/// Calculates "nice" Y-axis intervals for the given range.
/// Returns (tickInterval, gridInterval) where gridInterval = tickInterval / 2.
/// 
/// Targets ~6 ticks, with a minimum of 3 ticks guaranteed.
/// Uses a "nice numbers" algorithm to find intervals like 0.5, 1, 2, 5, 10, etc.
(double, double) calculateWeightIntervals(double minY, double maxY) {
  final range = maxY - minY;
  if (range <= 0) return (1.0, 0.5);
  
  // Aim for approximately 6 ticks
  final rawInterval = range / 6;
  
  // Find the magnitude (power of 10)
  final magnitude = pow(10, (log(rawInterval) / ln10).floor()).toDouble();
  final normalized = rawInterval / magnitude;
  
  // Round to a "nice" number: 1, 2, 5, or 10
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
  
  // Ensure at least 3 ticks (interval must not exceed range / 3)
  final maxInterval = range / 3;
  if (niceInterval > maxInterval) {
    niceInterval = maxInterval;
  }
  
  return (niceInterval, niceInterval / 2);
}

/// Returns chart X-axis bounds shared by LineChart and ChartViewport.
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
