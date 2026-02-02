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
