import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';

// Color constants
const Color _primaryGreen = Color(0xFF5d7d5f);
const Color _creamColor = Color(0xFFfbe9ce);
const Color _orangeColor = Color(0xFFe87d5f);

void main() {
  runApp(const WeightGraphApp());
}

class WeightGraphApp extends StatelessWidget {
  const WeightGraphApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsProvider()..loadSettings(),
      child: MaterialApp(
        title: 'WeightGraph',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _primaryGreen,
            brightness: Brightness.light,
          ).copyWith(
            primary: _primaryGreen,
            onPrimary: _creamColor,
            secondary: Colors.white,
            onSecondary: Colors.grey,
            tertiary: _orangeColor,
            onTertiary: Colors.white,
            surface: _creamColor,
            error: _orangeColor,
            onError: Colors.white,
            inversePrimary: _creamColor,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
