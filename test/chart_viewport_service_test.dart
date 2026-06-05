import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weight_graph/services/chart_viewport_service.dart';

void main() {
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
