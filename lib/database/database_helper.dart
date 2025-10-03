import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/weight_entry.dart';
import '../services/storage_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize database factory for desktop platforms
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                    defaultTargetPlatform == TargetPlatform.linux || 
                    defaultTargetPlatform == TargetPlatform.macOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), 'weight_tracking.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE weight_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        date INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertWeightEntry(WeightEntry entry) async {
    if (kIsWeb) {
      return await StorageService().insertWeightEntry(entry);
    } else {
      final db = await database;
      return await db.insert('weight_entries', entry.toMap());
    }
  }

  Future<List<WeightEntry>> getAllWeightEntries() async {
    if (kIsWeb) {
      return await StorageService().getAllWeightEntries();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'weight_entries',
        orderBy: 'date ASC',
      );
      return List.generate(maps.length, (i) {
        return WeightEntry.fromMap(maps[i]);
      });
    }
  }

  Future<List<WeightEntry>> getWeightEntriesForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (kIsWeb) {
      return await StorageService().getWeightEntriesForDateRange(startDate, endDate);
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'weight_entries',
        where: 'date >= ? AND date <= ?',
        whereArgs: [
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch,
        ],
        orderBy: 'date ASC',
      );
      return List.generate(maps.length, (i) {
        return WeightEntry.fromMap(maps[i]);
      });
    }
  }

  Future<List<WeightEntry>> getLastNWeightEntries(int count) async {
    if (kIsWeb) {
      return await StorageService().getLastNWeightEntries(count);
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'weight_entries',
        orderBy: 'date DESC',
        limit: count,
      );
      return List.generate(maps.length, (i) {
        return WeightEntry.fromMap(maps[i]);
      }).reversed.toList();
    }
  }

  Future<int> updateWeightEntry(WeightEntry entry) async {
    if (kIsWeb) {
      return await StorageService().updateWeightEntry(entry);
    } else {
      final db = await database;
      return await db.update(
        'weight_entries',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    }
  }

  Future<int> deleteWeightEntry(int id) async {
    if (kIsWeb) {
      return await StorageService().deleteWeightEntry(id);
    } else {
      final db = await database;
      return await db.delete(
        'weight_entries',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> clearAllData() async {
    if (kIsWeb) {
      return await StorageService().clearAllData();
    } else {
      final db = await database;
      await db.delete('weight_entries');
    }
  }

  Future<void> importWeightEntries(List<WeightEntry> entries) async {
    for (final entry in entries) {
      await insertWeightEntry(entry);
    }
  }

  Future<void> close() async {
    if (!kIsWeb) { // Only close for non-web platforms
      final db = await database;
      db.close();
    }
  }
}
