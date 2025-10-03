import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _weightUnitKey = 'weight_unit';
  static const String _dateFormatKey = 'date_format';
  static const String _runningAverageDaysKey = 'running_average_days';

  // Default values
  static const String _defaultWeightUnit = 'kg';
  static const String _defaultDateFormat = 'dd/MM/yyyy';
  static const int _defaultRunningAverageDays = 5;

  Future<String> getWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_weightUnitKey) ?? _defaultWeightUnit;
  }

  Future<String> getDateFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dateFormatKey) ?? _defaultDateFormat;
  }

  Future<int> getRunningAverageDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_runningAverageDaysKey) ?? _defaultRunningAverageDays;
  }

  Future<void> setWeightUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weightUnitKey, unit);
  }

  Future<void> setDateFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateFormatKey, format);
  }

  Future<void> setRunningAverageDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_runningAverageDaysKey, days);
  }

  // Helper method to get weight unit display text
  String getWeightUnitDisplay(String unit) {
    switch (unit) {
      case 'kg':
        return 'kg';
      case 'lbs':
        return 'lbs';
      default:
        return 'kg';
    }
  }

  // Helper method to get weight unit label text
  String getWeightUnitLabel(String unit) {
    switch (unit) {
      case 'kg':
        return 'Weight (kg)';
      case 'lbs':
        return 'Weight (lbs)';
      default:
        return 'Weight (kg)';
    }
  }
}
