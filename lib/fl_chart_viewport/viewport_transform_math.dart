import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'axis_chart_domain.dart';
import 'fl_chart_virtual_rect.dart';

/// Tolerance for epoch-ms coordinate comparisons (~1 ms).
const double viewportEpsilonMs = 1.0;

/// Builds a transformation matrix that shows [xMin, xMax] in the plot viewport.
Matrix4 buildMatrixForXRange({
  required double xMin,
  required double xMax,
  required AxisChartDomain domain,
  required double plotWidth,
}) {
  final deltaX = domain.deltaX;
  if (deltaX == 0 || plotWidth <= 0) return Matrix4.identity();

  final targetSceneLeft = ((xMin - domain.minX) / deltaX) * plotWidth;
  final targetSceneRight = ((xMax - domain.minX) / deltaX) * plotWidth;
  final targetSceneWidth = targetSceneRight - targetSceneLeft;

  if (targetSceneWidth <= 0) return Matrix4.identity();

  final scale = plotWidth / targetSceneWidth;
  final translationX = -targetSceneLeft * scale;

  return Matrix4.identity()
    ..scale(scale, 1.0, 1.0)
    ..translate(translationX / scale, 0.0, 0.0);
}

/// Ground-truth visible X range via fl_chart's chartVirtualRect + getXForPixel path.
(double, double) readVisibleXRangeFlChart({
  required Matrix4 matrix,
  required Rect plotRect,
  required AxisChartDomain domain,
  required FlScaleAxis scaleAxis,
}) {
  final virtual = computeChartVirtualRect(matrix, plotRect, scaleAxis);
  if (virtual == null) return (domain.minX, domain.maxX);

  final deltaX = domain.deltaX;
  if (deltaX == 0) return (domain.minX, domain.maxX);

  final minX = (-virtual.left / virtual.width) * deltaX + domain.minX;
  final maxX =
      ((plotRect.width - virtual.left) / virtual.width) * deltaX + domain.minX;
  return (minX, maxX);
}

/// Alternative readback via [TransformationController.toScene] (not canonical for fl_chart).
(double, double) readVisibleXRangeToScene({
  required Matrix4 matrix,
  required double plotWidth,
  required AxisChartDomain domain,
}) {
  final controller = TransformationController(matrix);
  final sceneLeft = controller.toScene(Offset.zero);
  final sceneRight = controller.toScene(Offset(plotWidth, 0));

  final deltaX = domain.deltaX;
  if (deltaX == 0 || plotWidth <= 0) return (domain.minX, domain.maxX);

  final visibleMin = domain.minX + (sceneLeft.dx / plotWidth) * deltaX;
  final visibleMax = domain.minX + (sceneRight.dx / plotWidth) * deltaX;
  return (visibleMin, visibleMax);
}

/// Visible Y range for horizontal-scale charts: domain minY/maxY directly.
(double, double) readVisibleYRange({
  required AxisChartDomain domain,
  double? viewMinY,
  double? viewMaxY,
}) {
  if (viewMinY != null && viewMaxY != null) {
    return (viewMinY, viewMaxY);
  }
  return (domain.minY, domain.maxY);
}

/// Computes the target virtual rect for a desired X window (horizontal scale).
Rect computeTargetVirtualRectForXRange({
  required double xMin,
  required double xMax,
  required AxisChartDomain domain,
  required double plotWidth,
  required double plotHeight,
}) {
  final deltaX = domain.deltaX;
  final targetSpan = xMax - xMin;
  final virtualWidth = plotWidth * deltaX / targetSpan;
  final virtualLeft = -(xMin - domain.minX) * virtualWidth / deltaX;
  return Rect.fromLTWH(virtualLeft, 0, virtualWidth, plotHeight);
}

bool xRangeMatches(
  double actualMin,
  double actualMax,
  double expectedMin,
  double expectedMax, {
  double epsilon = viewportEpsilonMs,
}) {
  return (actualMin - expectedMin).abs() <= epsilon &&
      (actualMax - expectedMax).abs() <= epsilon;
}
