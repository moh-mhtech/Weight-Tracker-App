import 'package:flutter/material.dart';
import 'screens/weight_tracking_app.dart';

void main() {
  runApp(const WeightTrackerApp());
}

class WeightTrackerApp extends StatelessWidget {
  const WeightTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weight Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WeightTrackingApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}
