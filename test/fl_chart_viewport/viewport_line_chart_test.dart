import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weight_graph/fl_chart_viewport/axis_chart_domain.dart';
import 'package:weight_graph/fl_chart_viewport/axis_chart_view_controller.dart';
import 'package:weight_graph/fl_chart_viewport/viewport_line_chart.dart';
import 'package:weight_graph/fl_chart_viewport/viewport_transform_math.dart';

import 'test_data_factory.dart';

const double graphTimePadding = Duration.millisecondsPerDay / 2;
const double graphVisibleDuration =
    24 * Duration.millisecondsPerDay + 2 * graphTimePadding;

class _ChartHarness extends StatefulWidget {
  final AxisChartViewController controller;
  final List<FlSpot> spots;
  final AxisChartDomain domain;
  final void Function(AxisChartViewController controller)? onReady;

  const _ChartHarness({
    required this.controller,
    required this.spots,
    required this.domain,
    this.onReady,
  });

  @override
  State<_ChartHarness> createState() => _ChartHarnessState();
}

class _ChartHarnessState extends State<_ChartHarness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onReady?.call(widget.controller);
      if (mounted) setState(() {});
    });
  }

  LineChartData _buildChartData() {
    final yRange = widget.controller.getVisibleYRange();
    return LineChartData(
      borderData: FlBorderData(show: true),
      minX: widget.domain.minX,
      maxX: widget.domain.maxX,
      minY: yRange?.$1 ?? 60,
      maxY: yRange?.$2 ?? 90,
      lineBarsData: [
        LineChartBarData(
          spots: widget.spots,
          dotData: const FlDotData(show: false),
        ),
      ],
      titlesData: defaultTitlesData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.updateDomain(widget.domain);
    return SizedBox(
      width: 300,
      height: 200,
      child: ViewportLineChart(
        controller: widget.controller,
        transformationConfig: FlTransformationConfig(
          scaleAxis: FlScaleAxis.horizontal,
          minScale: 1.0,
          maxScale: 500.0,
          transformationController: widget.controller.transformationController,
        ),
        dataBuilder: (_, __) => _buildChartData(),
      ),
    );
  }
}

void main() {
  group('ViewportLineChart', () {
    Future<void> pumpChart(
      WidgetTester tester, {
      required AxisChartViewController controller,
      required List<FlSpot> spots,
      required AxisChartDomain domain,
      void Function(AxisChartViewController controller)? onReady,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ChartHarness(
              controller: controller,
              spots: spots,
              domain: domain,
              onReady: onReady,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('setXViewFromValues shows first/middle/last week', (
      WidgetTester tester,
    ) async {
      for (final spanDays in [21, 1095]) {
        final spots = spotsForSpanDays(spanDays);
        final domain = domainForSpots(spots);

        for (final position in WeekPosition.values) {
          final controller =
              AxisChartViewController(scaleAxis: FlScaleAxis.horizontal);
          final (xMin, xMax) = weekWindow(domain, position);

          await pumpChart(
            tester,
            controller: controller,
            spots: spots,
            domain: domain,
          );
          controller.setXViewFromValues(xMin, xMax);
          await tester.pumpAndSettle();

          final (visibleMin, visibleMax) = controller.getVisibleXRange();
          expect(
            xRangeMatches(visibleMin, visibleMax, xMin, xMax),
            isTrue,
            reason: '$spanDays days, $position: ($visibleMin, $visibleMax)',
          );
          controller.dispose();
        }
      }
    });

    testWidgets('initial 12-day view ends at newest + 12h (3-year regression)', (
      WidgetTester tester,
    ) async {
      final controller =
          AxisChartViewController(scaleAxis: FlScaleAxis.horizontal);
      final spots = spotsForSpanDays(1095);
      final domain = domainForSpots(spots);
      final newest = spots.last.x;
      final dataMaxX = newest + graphTimePadding;
      final targetMin = dataMaxX - graphVisibleDuration;
      final targetMax = dataMaxX;

      await pumpChart(
        tester,
        controller: controller,
        spots: spots,
        domain: domain,
        onReady: (c) => c.setXViewFromValues(targetMin, targetMax),
      );

      final (visibleMin, visibleMax) = controller.getVisibleXRange();
      expect(visibleMax, closeTo(targetMax, viewportEpsilonMs));
      expect(visibleMin, closeTo(targetMin, viewportEpsilonMs));
      expect(
        (visibleMax - newest) / graphTimePadding,
        closeTo(1.0, 0.01),
        reason: 'visible max should be newest + 12h, not days beyond',
      );
      controller.dispose();
    });

    testWidgets('setYViewFromValues updates chart Y bounds', (
      WidgetTester tester,
    ) async {
      final controller =
          AxisChartViewController(scaleAxis: FlScaleAxis.horizontal);
      final spots = spotsForSpanDays(21);
      final domain = domainForSpots(spots);

      await pumpChart(
        tester,
        controller: controller,
        spots: spots,
        domain: domain,
      );
      controller.setYViewFromValues(72, 78);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ChartHarness(
              controller: controller,
              spots: spots,
              domain: domain,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.getVisibleYRange(), (72.0, 78.0));

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      expect(lineChart.data.minY, 72);
      expect(lineChart.data.maxY, 78);
      controller.dispose();
    });
  });
}
