import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'axis_chart_domain.dart';
import 'chart_plot_metrics.dart';
import 'viewport_transform_math.dart';

/// Controls X viewport via [TransformationController] and Y viewport via minY/maxY.
class AxisChartViewController {
  final TransformationController transformationController;
  final bool _ownsTransformationController;
  FlScaleAxis scaleAxis;

  AxisChartDomain? _domain;
  ChartPlotMetrics? _plotMetrics;
  double? _viewMinY;
  double? _viewMaxY;

  bool isAdjusting = false;

  AxisChartViewController({
    TransformationController? transformationController,
    this.scaleAxis = FlScaleAxis.horizontal,
  })  : transformationController =
            transformationController ?? TransformationController(),
        _ownsTransformationController = transformationController == null;

  AxisChartDomain? get domain => _domain;
  ChartPlotMetrics? get plotMetrics => _plotMetrics;

  void updateDomain(AxisChartDomain domain) {
    _domain = domain;
  }

  void updatePlotMetrics(ChartPlotMetrics metrics) {
    _plotMetrics = metrics;
  }

  void setYViewFromValues(double yMin, double yMax) {
    _viewMinY = yMin;
    _viewMaxY = yMax;
  }

  (double, double)? getVisibleYRange() {
    if (_viewMinY == null || _viewMaxY == null) return null;
    return (_viewMinY!, _viewMaxY!);
  }

  (double, double) getVisibleXRange() {
    final domain = _domain;
    final plot = _plotMetrics;
    if (domain == null || plot == null) {
      if (domain != null) return (domain.minX, domain.maxX);
      return (0, 0);
    }
    return readVisibleXRangeFlChart(
      matrix: transformationController.value,
      plotRect: plot.plotRect,
      domain: domain,
      scaleAxis: scaleAxis,
    );
  }

  /// Sets the visible X range to [xMin, xMax] using fl_chart's viewport pipeline.
  void setXViewFromValues(double xMin, double xMax) {
    final domain = _domain;
    final plot = _plotMetrics;
    assert(
      domain != null && plot != null,
      'Domain and plot metrics must be set before setXViewFromValues',
    );
    if (domain == null || plot == null) return;

    var clampedMin = xMin.clamp(domain.minX, domain.maxX);
    var clampedMax = xMax.clamp(domain.minX, domain.maxX);
    if (clampedMin >= clampedMax) return;

    final matrix = buildMatrixForXRange(
      xMin: clampedMin,
      xMax: clampedMax,
      domain: domain,
      plotWidth: plot.plotWidth,
    );

    isAdjusting = true;
    transformationController.value = matrix;
    isAdjusting = false;
  }

  void dispose() {
    if (_ownsTransformationController) {
      transformationController.dispose();
    }
  }
}
