import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/weight_entry.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _weightEntriesKey = 'weight_entries';

  Future<List<WeightEntry>> getAllWeightEntries() async {
    if (kIsWeb) {
      return await _getWeightEntriesFromWeb();
    }
    return [];
  }

  Future<int> insertWeightEntry(WeightEntry entry) async {
    if (kIsWeb) {
      return await _insertWeightEntryToWeb(entry);
    }
    return 0;
  }

  Future<int> updateWeightEntry(WeightEntry entry) async {
    if (kIsWeb) {
      return await _updateWeightEntryInWeb(entry);
    }
    return 0;
  }

  Future<int> deleteWeightEntry(int id) async {
    if (kIsWeb) {
      return await _deleteWeightEntryFromWeb(id);
    }
    return 0;
  }

  Future<List<WeightEntry>> getWeightEntriesForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (kIsWeb) {
      return await _getWeightEntriesForDateRangeFromWeb(startDate, endDate);
    }
    return [];
  }

  Future<List<WeightEntry>> getLastNWeightEntries(int count) async {
    if (kIsWeb) {
      return await _getLastNWeightEntriesFromWeb(count);
    }
    return [];
  }

  Future<List<WeightEntry>> _getWeightEntriesFromWeb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? entriesJson = prefs.getString(_weightEntriesKey);
      
      if (entriesJson == null) {
        return [];
      }
      
      final List<dynamic> entriesList = jsonDecode(entriesJson);
      return entriesList.map((json) => WeightEntry.fromMap(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> _insertWeightEntryToWeb(WeightEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<WeightEntry> entries = await _getWeightEntriesFromWeb();
      
      // Generate a simple ID for web storage
      final int newId = entries.isEmpty ? 1 : entries.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      final WeightEntry entryWithId = entry.copyWith(id: newId);
      
      entries.add(entryWithId);
      entries.sort((a, b) => a.date.compareTo(b.date));
      
      final String entriesJson = jsonEncode(entries.map((e) => e.toMap()).toList());
      await prefs.setString(_weightEntriesKey, entriesJson);
      
      return newId;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _updateWeightEntryInWeb(WeightEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<WeightEntry> entries = await _getWeightEntriesFromWeb();
      
      final int index = entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        entries[index] = entry;
        
        final String entriesJson = jsonEncode(entries.map((e) => e.toMap()).toList());
        await prefs.setString(_weightEntriesKey, entriesJson);
        
        return 1;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<List<WeightEntry>> _getWeightEntriesForDateRangeFromWeb(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final List<WeightEntry> allEntries = await _getWeightEntriesFromWeb();
      return allEntries.where((entry) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        return entryDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               entryDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<WeightEntry>> _getLastNWeightEntriesFromWeb(int count) async {
    try {
      final List<WeightEntry> allEntries = await _getWeightEntriesFromWeb();
      allEntries.sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
      return allEntries.take(count).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> _deleteWeightEntryFromWeb(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<WeightEntry> entries = await _getWeightEntriesFromWeb();
      
      entries.removeWhere((entry) => entry.id == id);
      
      final String entriesJson = jsonEncode(entries.map((e) => e.toMap()).toList());
      await prefs.setString(_weightEntriesKey, entriesJson);
      
      return 1;
    } catch (e) {
      return 0;
    }
  }

  Future<void> clearAllData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_weightEntriesKey);
    }
  }
}
