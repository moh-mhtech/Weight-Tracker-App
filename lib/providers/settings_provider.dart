import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _weightUnitKey = 'weight_unit';
  static const String _dateFormatKey = 'date_format';
  static const String _runningAverageDaysKey = 'running_average_days';

  // Default values
  static const String _defaultWeightUnit = 'kg';
  static const String _defaultDateFormat = 'dd/MM/yyyy';
  static const int _defaultRunningAverageDays = 5;

  // Current settings state
  String _weightUnit = _defaultWeightUnit;
  String _dateFormat = _defaultDateFormat;
  int _runningAverageDays = _defaultRunningAverageDays;

  // Getters
  String get weightUnit => _weightUnit;
  String get dateFormat => _dateFormat;
  int get runningAverageDays => _runningAverageDays;

  // Initialize settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _weightUnit = prefs.getString(_weightUnitKey) ?? _defaultWeightUnit;
    _dateFormat = prefs.getString(_dateFormatKey) ?? _defaultDateFormat;
    _runningAverageDays = prefs.getInt(_runningAverageDaysKey) ?? _defaultRunningAverageDays;
    
    notifyListeners();
  }

  // Update weight unit
  Future<void> setWeightUnit(String unit) async {
    if (_weightUnit != unit) {
      _weightUnit = unit;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_weightUnitKey, unit);
      notifyListeners();
    }
  }

  // Update date format
  Future<void> setDateFormat(String format) async {
    if (_dateFormat != format) {
      _dateFormat = format;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dateFormatKey, format);
      notifyListeners();
    }
  }

  // Update running average days
  Future<void> setRunningAverageDays(int days) async {
    if (_runningAverageDays != days) {
      _runningAverageDays = days;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_runningAverageDaysKey, days);
      notifyListeners();
    }
  }

  // Helper method to get weight unit display text
  String getWeightUnitDisplay(String unit) {
    return unit == 'lbs' ? 'lbs' : 'kg';
  }

  // Helper method to get weight unit label text
  String getWeightUnitLabel(String unit) {
    return unit == 'lbs' ? 'Weight (lbs)' : 'Weight (kg)';
  }
}
