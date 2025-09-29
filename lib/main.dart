import 'package:flutter/material.dart';
import 'screens/weight_tracking_app.dart';

void main() {
  runApp(const WeightGraphApp());
}

class WeightGraphApp extends StatelessWidget {
  const WeightGraphApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeightGraph',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D7D5F), // Primary green from logo
          brightness: Brightness.light,
        ).copyWith(
          // Primary colors (matching logo greens)
          primary: const Color(0xFF5D7D5F),
          onPrimary: const Color(0xFFFBE9CE), // Cream text on green
          
          // Secondary colors
          secondary: const Color(0xFF608162),
          onSecondary: const Color(0xFFFBE9CE),
          
          // Surface colors
          surface: const Color(0xFFFBE9CE), // Cream background
          onSurface: const Color(0xFF202C1F), // Dark green text
          
          // Background colors
          background: const Color(0xFFFBE9CE),
          onBackground: const Color(0xFF202C1F),
          
          // Error colors (keeping red for errors)
          error: const Color(0xFFD32F2F),
          onError: Colors.white,
          
          // Outline colors
          outline: const Color(0xFF5D7D5F),
          outlineVariant: const Color(0xFF608162),
          
          // Inverse colors
          inversePrimary: const Color(0xFF41553F),
          inverseSurface: const Color(0xFF202C1F),
          onInverseSurface: const Color(0xFFFBE9CE),
        ),
        useMaterial3: true,
      ),
      home: const WeightTrackingApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}
