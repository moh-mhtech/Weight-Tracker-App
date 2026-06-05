import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

/// Port of fl_chart's [CustomInteractiveViewer.transformViewport].
Quad transformViewport(Matrix4 matrix, Rect viewport) {
  final inverseMatrix = matrix.clone()..invert();
  return Quad.points(
    inverseMatrix.transform3(
      Vector3(viewport.topLeft.dx, viewport.topLeft.dy, 0),
    ),
    inverseMatrix.transform3(
      Vector3(viewport.topRight.dx, viewport.topRight.dy, 0),
    ),
    inverseMatrix.transform3(
      Vector3(viewport.bottomRight.dx, viewport.bottomRight.dy, 0),
    ),
    inverseMatrix.transform3(
      Vector3(viewport.bottomLeft.dx, viewport.bottomLeft.dy, 0),
    ),
  );
}

/// Port of fl_chart's [CustomInteractiveViewer.axisAlignedBoundingBox].
Rect axisAlignedBoundingBox(Quad quad) {
  var xMin = quad.point0.x;
  var xMax = quad.point0.x;
  var yMin = quad.point0.y;
  var yMax = quad.point0.y;
  for (final point in <Vector3>[
    quad.point1,
    quad.point2,
    quad.point3,
  ]) {
    if (point.x < xMin) {
      xMin = point.x;
    } else if (point.x > xMax) {
      xMax = point.x;
    }
    if (point.y < yMin) {
      yMin = point.y;
    } else if (point.y > yMax) {
      yMax = point.y;
    }
  }
  return Rect.fromLTRB(xMin, yMin, xMax, yMax);
}

bool _canScaleHorizontally(FlScaleAxis scaleAxis) =>
    scaleAxis == FlScaleAxis.horizontal || scaleAxis == FlScaleAxis.free;

bool _canScaleVertically(FlScaleAxis scaleAxis) =>
    scaleAxis == FlScaleAxis.vertical || scaleAxis == FlScaleAxis.free;

/// Mirrors [AxisChartScaffoldWidget._calculateAdjustedRect].
Rect? computeChartVirtualRect(
  Matrix4 matrix,
  Rect plotRect,
  FlScaleAxis scaleAxis,
) {
  final scale = matrix.getMaxScaleOnAxis();
  if (scale == 1.0) return null;

  final inverseMatrix = Matrix4.inverted(matrix);
  final chartVirtualQuad = transformViewport(inverseMatrix, plotRect);
  final chartVirtualRect = axisAlignedBoundingBox(chartVirtualQuad);

  return Rect.fromLTWH(
    _canScaleHorizontally(scaleAxis) ? chartVirtualRect.left : plotRect.left,
    _canScaleVertically(scaleAxis) ? chartVirtualRect.top : plotRect.top,
    _canScaleHorizontally(scaleAxis)
        ? chartVirtualRect.width
        : plotRect.width,
    _canScaleVertically(scaleAxis)
        ? chartVirtualRect.height
        : plotRect.height,
  );
}
