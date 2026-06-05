import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weight_graph/fl_chart_viewport/axis_chart_domain.dart';
import 'package:weight_graph/fl_chart_viewport/axis_chart_view_controller.dart';
import 'package:weight_graph/fl_chart_viewport/chart_plot_metrics.dart';
import 'package:weight_graph/fl_chart_viewport/viewport_transform_math.dart';

import 'test_data_factory.dart';

void main() {
  group('ChartPlotMetrics', () {
    test('matches scaffold layout for weight chart title config', () {
      final constraints = const BoxConstraints(maxWidth: 300, maxHeight: 200);
      final titles = defaultTitlesData();
      final border = FlBorderData(show: true);

      final metrics = ChartPlotMetrics.fromFlChartLayout(
        constraints: constraints,
        titlesData: titles,
        borderData: border,
      );

      // 300 - 30 (left) - 2 (border) = 268
      expect(metrics.plotWidth, closeTo(268, 0.01));
      // 200 - 28 (bottom) - 2 (border) = 170
      expect(metrics.plotHeight, closeTo(170, 0.01));
    });

    test('wide left titles reduce plot width', () {
      final constraints = const BoxConstraints(maxWidth: 400, maxHeight: 200);
      final metrics = ChartPlotMetrics.fromFlChartLayout(
        constraints: constraints,
        titlesData: wideLeftTitlesData(),
        borderData: FlBorderData(show: true),
      );

      // 400 - 50 (left) - 2 (border) = 348
      expect(metrics.plotWidth, closeTo(348, 0.01));
    });
  });

  group('X viewport round-trip', () {
    final plotWidths = [200.0, 360.0, 400.0];
    final titleConfigs = [
      ('default', defaultTitlesData),
      ('wideLeft', wideLeftTitlesData),
    ];

    for (final spanDays in [21, 1095]) {
      for (final position in WeekPosition.values) {
        for (final plotWidth in plotWidths) {
          for (final (configName, titlesFn) in titleConfigs) {
            test(
              '${spanDays}d domain, $position week, plotWidth=$plotWidth, titles=$configName',
              () {
                final spots = spotsForSpanDays(spanDays);
                final domain = domainForSpots(spots);
                final (xMin, xMax) = weekWindow(domain, position);

                final constraints = BoxConstraints(
                  maxWidth: plotWidth + 58,
                  maxHeight: 200,
                );
                final metrics = ChartPlotMetrics.fromFlChartLayout(
                  constraints: constraints,
                  titlesData: titlesFn(),
                  borderData: FlBorderData(show: true),
                );

                final matrix = buildMatrixForXRange(
                  xMin: xMin,
                  xMax: xMax,
                  domain: domain,
                  plotWidth: metrics.plotWidth,
                );

                final (visibleMin, visibleMax) = readVisibleXRangeFlChart(
                  matrix: matrix,
                  plotRect: metrics.plotRect,
                  domain: domain,
                  scaleAxis: FlScaleAxis.horizontal,
                );

                expect(
                  xRangeMatches(visibleMin, visibleMax, xMin, xMax),
                  isTrue,
                  reason:
                      'visible=($visibleMin, $visibleMax) expected=($xMin, $xMax)',
                );
              },
            );
          }
        }
      }
    }

    test('full domain at identity matrix returns full domain', () {
      final domain = domainForSpots(spotsForSpanDays(21));
      final metrics = const ChartPlotMetrics(plotWidth: 280, plotHeight: 170);

      final (minX, maxX) = readVisibleXRangeFlChart(
        matrix: Matrix4.identity(),
        plotRect: metrics.plotRect,
        domain: domain,
        scaleAxis: FlScaleAxis.horizontal,
      );

      expect(minX, domain.minX);
      expect(maxX, domain.maxX);
    });
  });

  group('readVisibleXRangeFlChart vs readVisibleXRangeToScene', () {
    test('paths agree within epsilon for subset windows', () {
      final domain = domainForSpots(spotsForSpanDays(1095));
      const plotWidth = 280.0;
      const plotHeight = 170.0;
      final plotRect = Rect.fromLTWH(0, 0, plotWidth, plotHeight);

      for (final position in WeekPosition.values) {
        final (xMin, xMax) = weekWindow(domain, position);
        final matrix = buildMatrixForXRange(
          xMin: xMin,
          xMax: xMax,
          domain: domain,
          plotWidth: plotWidth,
        );

        final flChart = readVisibleXRangeFlChart(
          matrix: matrix,
          plotRect: plotRect,
          domain: domain,
          scaleAxis: FlScaleAxis.horizontal,
        );
        final toScene = readVisibleXRangeToScene(
          matrix: matrix,
          plotWidth: plotWidth,
          domain: domain,
        );

        expect(flChart.$1, closeTo(toScene.$1, viewportEpsilonMs));
        expect(flChart.$2, closeTo(toScene.$2, viewportEpsilonMs));
      }
    });
  });

  group('AxisChartViewController Y view', () {
    test('setYViewFromValues stores visible Y range', () {
      final controller = AxisChartViewController();
      controller.setYViewFromValues(70, 80);
      expect(controller.getVisibleYRange(), (70.0, 80.0));
      controller.dispose();
    });

    test('setXViewFromValues round-trips through controller', () {
      final controller = AxisChartViewController();
      final domain = domainForSpots(spotsForSpanDays(21));
      controller.updateDomain(domain);
      controller.updatePlotMetrics(
        const ChartPlotMetrics(plotWidth: 268, plotHeight: 170),
      );

      final (xMin, xMax) = weekWindow(domain, WeekPosition.last);
      controller.setXViewFromValues(xMin, xMax);

      final (visibleMin, visibleMax) = controller.getVisibleXRange();
      expect(
        xRangeMatches(visibleMin, visibleMax, xMin, xMax),
        isTrue,
      );
      controller.dispose();
    });
  });
}
