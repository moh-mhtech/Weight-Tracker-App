import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/weight_entry.dart';
import '../database/database_helper.dart';
import '../widgets/weight_entry_form.dart';
import '../widgets/weight_chart.dart';
import '../widgets/app_logo.dart';
import '../widgets/weight_entry_table.dart';
import '../services/sample_data_service.dart';
import 'settings_screen.dart';

class WeightTrackingApp extends StatefulWidget {
  const WeightTrackingApp({super.key});

  @override
  State<WeightTrackingApp> createState() => _WeightTrackingAppState();
}

class _WeightTrackingAppState extends State<WeightTrackingApp> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<WeightEntry> _weightEntries = [];
  bool _isLoading = true;
  int _visibleEntriesCount = 15;

  @override
  void initState() {
    super.initState();
    _loadWeightEntries();
  }

  void _loadMoreEntries() {
    setState(() {
      _visibleEntriesCount += 15;
    });
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  Future<void> _loadWeightEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add sample data if needed (only in debug mode)
      await SampleDataService.addSampleDataIfNeeded();
      
      final entries = await _dbHelper.getAllWeightEntries();
      setState(() {
        _weightEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading weight entries: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(
              size: 32,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 12),
            const Text('Weight Graph'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(),
          ),
          if (kDebugMode && _weightEntries.length >= 30) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'SAMPLE DATA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onTertiary),
                ),
              ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WeightEntryForm(onWeightAdded: _loadWeightEntries),
                    WeightChart(weightEntries: _weightEntries),
                    if (_weightEntries.isNotEmpty) ...[
                      WeightEntryTable(
                        weightEntries: _weightEntries,
                        visibleEntriesCount: _visibleEntriesCount,
                        onEditEntry: _editWeightEntry,
                        onDeleteEntry: _deleteWeightEntry,
                        onLoadMore: _loadMoreEntries,
                        hasMoreEntries: _weightEntries.length > _visibleEntriesCount,
                      ),
                      const SizedBox(height: 16), // Extra padding for system navigation
                    ],
                  ],
                ),
              ),
            ),
    );
  }


  Future<void> _editWeightEntry(WeightEntry entry) async {
    final TextEditingController weightController = TextEditingController(
      text: entry.weight.toStringAsFixed(1),
    );
    DateTime selectedDate = entry.date;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Weight Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return 'Please enter a valid weight';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final weight = double.tryParse(weightController.text);
                if (weight != null && weight > 0) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final weight = double.parse(weightController.text);
      final updatedEntry = WeightEntry(
        id: entry.id,
        weight: weight,
        date: selectedDate,
      );

      try {
        if (updatedEntry.id != null) {
          await _dbHelper.updateWeightEntry(updatedEntry);
          _loadWeightEntries();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Weight entry updated!')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating weight entry: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteWeightEntry(WeightEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Weight Entry'),
        content: Text(
          'Are you sure you want to delete the weight entry of ${entry.weight.toStringAsFixed(1)} kg from ${entry.date.day}/${entry.date.month}/${entry.date.year}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && entry.id != null) {
      try {
        await _dbHelper.deleteWeightEntry(entry.id!);
        _loadWeightEntries();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Weight entry deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting weight entry: $e')),
          );
        }
      }
    }
  }
}
