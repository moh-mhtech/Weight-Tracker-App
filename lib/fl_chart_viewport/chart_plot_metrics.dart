import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Layout metrics for the interactive plot area inside an fl_chart scaffold.
class ChartPlotMetrics {
  final double plotWidth;
  final double plotHeight;

  const ChartPlotMetrics({
    required this.plotWidth,
    required this.plotHeight,
  });

  Rect get plotRect => Rect.fromLTWH(0, 0, plotWidth, plotHeight);

  /// Mirrors [AxisChartScaffoldWidget] rect math:
  /// `constraints - titlesData.allSidesPadding - border dimensions`.
  factory ChartPlotMetrics.fromFlChartLayout({
    required BoxConstraints constraints,
    required FlTitlesData titlesData,
    required FlBorderData borderData,
  }) {
    final margin = _allSidesPadding(titlesData);

    final border = borderData.show && borderData.border.isVisible()
        ? borderData.border
        : null;
    final borderWidth = border == null ? 0.0 : _borderHorizontal(border);
    final borderHeight = border == null ? 0.0 : _borderVertical(border);

    final plotWidth =
        constraints.maxWidth - margin.horizontal - borderWidth;
    final plotHeight =
        constraints.maxHeight - margin.vertical - borderHeight;

    return ChartPlotMetrics(
      plotWidth: plotWidth,
      plotHeight: plotHeight,
    );
  }

  static EdgeInsets _allSidesPadding(FlTitlesData titlesData) {
    return EdgeInsets.only(
      left: _titlePadding(
        titlesData.show,
        titlesData.leftTitles,
      ),
      top: _titlePadding(
        titlesData.show,
        titlesData.topTitles,
      ),
      right: _titlePadding(
        titlesData.show,
        titlesData.rightTitles,
      ),
      bottom: _titlePadding(
        titlesData.show,
        titlesData.bottomTitles,
      ),
    );
  }

  static double _titlePadding(bool showTitles, AxisTitles axisTitles) {
    if (!showTitles) return 0;
    final alignment = axisTitles.sideTitleAlignment;
    final reservedSize = _totalReservedSize(axisTitles);
    if (alignment == SideTitleAlignment.inside) {
      return 0;
    } else if (alignment == SideTitleAlignment.border) {
      return reservedSize / 2;
    }
    return reservedSize;
  }

  static double _totalReservedSize(AxisTitles axisTitles) {
    var size = 0.0;
    if (axisTitles.showAxisTitles) {
      size += axisTitles.axisNameSize;
    }
    if (axisTitles.showSideTitles) {
      size += axisTitles.sideTitles.reservedSize;
    }
    return size;
  }

  static double _borderHorizontal(Border border) {
    return border.left.width + border.right.width;
  }

  static double _borderVertical(Border border) {
    return border.top.width + border.bottom.width;
  }
}

extension _BorderVisibility on Border {
  bool isVisible() {
    if (left.width == 0 &&
        top.width == 0 &&
        right.width == 0 &&
        bottom.width == 0) {
      return false;
    }
    if (left.color.a == 0.0 &&
        top.color.a == 0.0 &&
        right.color.a == 0.0 &&
        bottom.color.a == 0.0) {
      return false;
    }
    return true;
  }
}
