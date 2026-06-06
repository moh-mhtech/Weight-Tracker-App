import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weight_graph/services/chart_viewport_service.dart';

void main() {
  group('chartWeightPaddingForUnit', () {
    test('returns 0.5 for kg', () {
      expect(chartWeightPaddingForUnit('kg'), 0.5);
    });

    test('returns 1.0 for lbs', () {
      expect(chartWeightPaddingForUnit('lbs'), 1.0);
    });
  });

  group('calculateTimeTickInterval', () {
    const oneDay = Duration.millisecondsPerDay * 1.0;

    double daysToMs(int days) => days * oneDay;

    test('25-day range at 360px uses 4-day interval', () {
      expect(
        calculateTimeTickInterval(
          visibleRangeMs: daysToMs(25),
          plotWidthPx: 360,
        ),
        daysToMs(4),
      );
    });

    test('25-day range at 1200px uses 1-day interval', () {
      expect(
        calculateTimeTickInterval(
          visibleRangeMs: daysToMs(25),
          plotWidthPx: 1200,
        ),
        oneDay,
      );
    });

    test('6-day range at 360px uses 1-day interval when zoomed in', () {
      expect(
        calculateTimeTickInterval(
          visibleRangeMs: daysToMs(6),
          plotWidthPx: 360,
        ),
        oneDay,
      );
    });

    test('10-day range at 360px uses 2-day interval', () {
      expect(
        calculateTimeTickInterval(
          visibleRangeMs: daysToMs(10),
          plotWidthPx: 360,
        ),
        daysToMs(2),
      );
    });

    test('returns 1 day for zero width or zero range', () {
      expect(
        calculateTimeTickInterval(
          visibleRangeMs: daysToMs(10),
          plotWidthPx: 0,
        ),
        oneDay,
      );
      expect(
        calculateTimeTickInterval(
          visibleRangeMs: 0,
          plotWidthPx: 360,
        ),
        oneDay,
      );
    });
  });

  group('splitSpotsByDayGaps', () {
    test('returns empty list for empty input', () {
      expect(splitSpotsByDayGaps([]), isEmpty);
    });

    test('returns single segment for consecutive daily spots', () {
      final oneDay = Duration.millisecondsPerDay.toDouble();
      final spots = [
        const FlSpot(0, 70),
        FlSpot(oneDay, 71),
        FlSpot(2 * oneDay, 72),
      ];

      final segments = splitSpotsByDayGaps(spots);

      expect(segments.length, equals(1));
      expect(segments.first.length, equals(3));
    });

    test('splits into multiple segments when gap exceeds one day', () {
      final oneDay = Duration.millisecondsPerDay.toDouble();
      final spots = [
        const FlSpot(0, 70),
        FlSpot(oneDay, 71),
        FlSpot(10 * oneDay, 80),
        FlSpot(11 * oneDay, 81),
      ];

      final segments = splitSpotsByDayGaps(spots);

      expect(segments.length, equals(2));
      expect(segments[0].map((spot) => spot.y).toList(), equals([70, 71]));
      expect(segments[1].map((spot) => spot.y).toList(), equals([80, 81]));
    });
  });
}
