import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'axis_chart_view_controller.dart';
import 'chart_plot_metrics.dart';

typedef ViewportLineChartDataBuilder = LineChartData Function(
  ChartPlotMetrics plotMetrics,
  AxisChartViewController controller,
);

/// Wraps [LineChart] with layout-aware plot metrics for the viewport controller.
class ViewportLineChart extends StatelessWidget {
  final AxisChartViewController controller;
  final ViewportLineChartDataBuilder dataBuilder;
  final FlTransformationConfig? transformationConfig;
  final Duration? duration;
  final Curve? curve;

  const ViewportLineChart({
    super.key,
    required this.controller,
    required this.dataBuilder,
    this.transformationConfig,
    this.duration,
    this.curve,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final probeMetrics = ChartPlotMetrics(
          plotWidth: constraints.maxWidth,
          plotHeight: constraints.maxHeight,
        );
        final probeData = dataBuilder(probeMetrics, controller);

        final metrics = ChartPlotMetrics.fromFlChartLayout(
          constraints: constraints,
          titlesData: probeData.titlesData,
          borderData: probeData.borderData,
        );
        controller.updatePlotMetrics(metrics);

        final chartData = dataBuilder(metrics, controller);

        final config = transformationConfig ??
            FlTransformationConfig(
              scaleAxis: controller.scaleAxis,
              transformationController: controller.transformationController,
            );

        return LineChart(
          transformationConfig: config,
          chartData,
          duration: duration ?? const Duration(milliseconds: 150),
          curve: curve ?? Curves.linear,
        );
      },
    );
  }
}
