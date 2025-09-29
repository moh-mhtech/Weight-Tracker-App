import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showGraph;

  const AppLogo({
    super.key,
    this.size = 40.0,
    this.color,
    this.showGraph = true,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Theme.of(context).colorScheme.primary;
    final graphColor = logoColor.withOpacity(0.7);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: DigitalScalePainter(
          color: logoColor,
          graphColor: graphColor,
          showGraph: showGraph,
        ),
      ),
    );
  }
}

class DigitalScalePainter extends CustomPainter {
  final Color color;
  final Color graphColor;
  final bool showGraph;

  DigitalScalePainter({
    required this.color,
    required this.graphColor,
    required this.showGraph,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final graphPaint = Paint()
      ..color = graphColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scaleWidth = size.width * 0.8;
    final scaleHeight = size.height * 0.6;

    // Draw the scale base (platform)
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY + scaleHeight * 0.3),
        width: scaleWidth,
        height: scaleHeight * 0.4,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(baseRect, fillPaint);
    canvas.drawRRect(baseRect, paint);

    // Draw the scale platform (top surface)
    final platformRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY - scaleHeight * 0.1),
        width: scaleWidth * 0.9,
        height: scaleHeight * 0.2,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(platformRect, fillPaint);
    canvas.drawRRect(platformRect, paint);

    // Draw the digital display
    final displayRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY - scaleHeight * 0.4),
        width: scaleWidth * 0.6,
        height: scaleHeight * 0.25,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(displayRect, fillPaint);
    canvas.drawRRect(displayRect, paint);

    // Draw the graph line in the display if enabled
    if (showGraph) {
      final displayLeft = centerX - scaleWidth * 0.3;
      final displayBottom = centerY - scaleHeight * 0.28;

      // Draw a simple trending line (moving average style)
      final path = Path();
      path.moveTo(displayLeft, displayBottom);
      path.lineTo(displayLeft + scaleWidth * 0.1, displayBottom - scaleHeight * 0.05);
      path.lineTo(displayLeft + scaleWidth * 0.2, displayBottom - scaleHeight * 0.08);
      path.lineTo(displayLeft + scaleWidth * 0.3, displayBottom - scaleHeight * 0.12);
      path.lineTo(displayLeft + scaleWidth * 0.4, displayBottom - scaleHeight * 0.1);
      path.lineTo(displayLeft + scaleWidth * 0.5, displayBottom - scaleHeight * 0.15);
      path.lineTo(displayLeft + scaleWidth * 0.6, displayBottom - scaleHeight * 0.18);

      canvas.drawPath(path, graphPaint);

      // Draw small dots for data points
      final dotPaint = Paint()
        ..color = graphColor
        ..style = PaintingStyle.fill;

      final dotPositions = [
        Offset(displayLeft + scaleWidth * 0.1, displayBottom - scaleHeight * 0.05),
        Offset(displayLeft + scaleWidth * 0.3, displayBottom - scaleHeight * 0.12),
        Offset(displayLeft + scaleWidth * 0.5, displayBottom - scaleHeight * 0.15),
      ];

      for (final dot in dotPositions) {
        canvas.drawCircle(dot, 1.5, dotPaint);
      }
    }

    // Draw weight value text (simplified as lines)
    final textPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw "75.2" as simple lines
    final textY = centerY - scaleHeight * 0.35;
    final textSpacing = scaleWidth * 0.08;

    // Draw "7"
    canvas.drawLine(
      Offset(centerX - textSpacing * 1.5, textY),
      Offset(centerX - textSpacing * 1.5, textY + scaleHeight * 0.08),
      textPaint,
    );
    canvas.drawLine(
      Offset(centerX - textSpacing * 1.5, textY),
      Offset(centerX - textSpacing * 1.0, textY),
      textPaint,
    );

    // Draw "5"
    canvas.drawLine(
      Offset(centerX - textSpacing * 0.5, textY),
      Offset(centerX - textSpacing * 0.5, textY + scaleHeight * 0.04),
      textPaint,
    );
    canvas.drawLine(
      Offset(centerX - textSpacing * 0.5, textY + scaleHeight * 0.04),
      Offset(centerX, textY + scaleHeight * 0.04),
      textPaint,
    );
    canvas.drawLine(
      Offset(centerX, textY + scaleHeight * 0.04),
      Offset(centerX, textY + scaleHeight * 0.08),
      textPaint,
    );

    // Draw "."
    canvas.drawCircle(
      Offset(centerX + textSpacing * 0.3, textY + scaleHeight * 0.06),
      1.0,
      textPaint,
    );

    // Draw "2"
    canvas.drawLine(
      Offset(centerX + textSpacing * 0.5, textY),
      Offset(centerX + textSpacing * 1.0, textY),
      textPaint,
    );
    canvas.drawLine(
      Offset(centerX + textSpacing * 1.0, textY),
      Offset(centerX + textSpacing * 1.0, textY + scaleHeight * 0.04),
      textPaint,
    );
    canvas.drawLine(
      Offset(centerX + textSpacing * 1.0, textY + scaleHeight * 0.04),
      Offset(centerX + textSpacing * 0.5, textY + scaleHeight * 0.08),
      textPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is DigitalScalePainter &&
        (oldDelegate.color != color ||
            oldDelegate.graphColor != graphColor ||
            oldDelegate.showGraph != showGraph);
  }
}
