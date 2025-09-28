import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SimplePanZoomChart extends StatefulWidget {
  const SimplePanZoomChart({super.key});

  @override
  State<SimplePanZoomChart> createState() => _SimplePanZoomChartState();
}

class _SimplePanZoomChartState extends State<SimplePanZoomChart> {
  List<FlSpot> _spots = [];
  bool _isPanEnabled = true;
  bool _isScaleEnabled = true;

  @override
  void initState() {
    super.initState();
    _generateMockData();
  }

  void _generateMockData() {
    final spots = <FlSpot>[];
    // Generate 100 data points
    for (int i = 0; i < 100; i++) {
      final x = i.toDouble();
      final y = 50 + (i * 0.5) + (i % 10) * 2.0 + (i % 20) * 1.0;
      spots.add(FlSpot(x, y));
    }
    setState(() {
      _spots = spots;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Pan and Zoom Test Chart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Pan'),
              Switch(
                value: _isPanEnabled,
                onChanged: (value) {
                  setState(() {
                    _isPanEnabled = value;
                  });
                },
              ),
              const SizedBox(width: 16),
              const Text('Scale'),
              Switch(
                value: _isScaleEnabled,
                onChanged: (value) {
                  setState(() {
                    _isScaleEnabled = value;
                  });
                },
              ),
            ],
          ),
        ),
        
        // Chart
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 10,
                  verticalInterval: 10,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: 99,
                minY: 40,
                maxY: 120,
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blue.withOpacity(0.8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        return LineTooltipItem(
                          'X: ${touchedSpot.x.toStringAsFixed(1)}\nY: ${touchedSpot.y.toStringAsFixed(1)}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Instructions
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Try dragging to pan and pinching to zoom. Toggle the switches above to enable/disable features.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
