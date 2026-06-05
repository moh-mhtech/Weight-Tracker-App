/// Full axis domain bounds for an axis-based chart.
class AxisChartDomain {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  const AxisChartDomain({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  double get deltaX => maxX - minX;
  double get deltaY => maxY - minY;

  AxisChartDomain copyWith({
    double? minX,
    double? maxX,
    double? minY,
    double? maxY,
  }) {
    return AxisChartDomain(
      minX: minX ?? this.minX,
      maxX: maxX ?? this.maxX,
      minY: minY ?? this.minY,
      maxY: maxY ?? this.maxY,
    );
  }
}
