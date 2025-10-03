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
          primary: const Color(0xFF5d7d5f), // Green
          onPrimary: const Color(0xFFfbe9ce), // Cream
          
          // Secondary colors
          secondary: const Color(0xFFFFFFFF), // White
          onSecondary: Colors.grey, // Default Material text color (grey[900])

          tertiary: const Color(0xFFe87d5f), // Orange
          onTertiary: Colors.white,
          
          // Surface colors
          surface: const Color(0xFFfbe9ce), // Cream
          // onSurface: const Color(0xFF5d7d5f), // Green
                    
          // Error colors (keeping red for errors)
          error: const Color(0xFFe87d5f),
          onError: Colors.white,
          
          // Outline colors
          // outline: const Color(0xFF5D7D5F),
          // outlineVariant: const Color(0xFF608162),
          
          // Inverse colors
          inversePrimary: const Color(0xFF5d7d5f),
          // inverseSurface: const Color(0xFF202C1F),
          // onInverseSurface: const Color(0xFFFBE9CE),
        ),
        useMaterial3: true,
      ),
      home: const WeightTrackingApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}
