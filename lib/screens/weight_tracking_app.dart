import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/weight_entry.dart';
import '../database/database_helper.dart';
import '../widgets/weight_entry_form.dart';
import '../widgets/weight_chart.dart';
import '../services/sample_data_service.dart';

class WeightTrackingApp extends StatefulWidget {
  const WeightTrackingApp({super.key});

  @override
  State<WeightTrackingApp> createState() => _WeightTrackingAppState();
}

class _WeightTrackingAppState extends State<WeightTrackingApp> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<WeightEntry> _weightEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeightEntries();
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
        title: const Text('Weight Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (kDebugMode && _weightEntries.length >= 30) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                'SAMPLE DATA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () async {
                await SampleDataService.regenerateSampleData();
                _loadWeightEntries();
              },
              tooltip: 'Regenerate Sample Data',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeightEntries,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  WeightEntryForm(onWeightAdded: _loadWeightEntries),
                  WeightChart(weightEntries: _weightEntries),
                  if (_weightEntries.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildWeightHistory(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildWeightHistory() {
    // Show all entries
    final allEntries = _weightEntries;

    // Calculate running averages for all entries
    final runningAverages = _calculateRunningAverages(_weightEntries);
    
    // Create a map of entry index to running average
    final Map<int, double> entryToRunningAverage = {};
    for (int i = 0; i < _weightEntries.length; i++) {
      entryToRunningAverage[i] = runningAverages[i];
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Measurements',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Average',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 48), // Account for trailing icon space
                ],
              ),
            ),
            const Divider(),
            ...allEntries.reversed.map((entry) {
              final entryIndex = _weightEntries.indexOf(entry);
              final runningAvg = entryToRunningAverage[entryIndex] ?? 0.0;
              
              return ListTile(
                dense: true,
                leading: const Icon(Icons.monitor_weight),
                title: Row(
                  children: [
                    Text('${entry.weight.toStringAsFixed(1)} kg'),
                    const SizedBox(width: 16),
                    Text(
                      '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${runningAvg.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black),
                      onPressed: () => _editWeightEntry(entry),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => _deleteWeightEntry(entry),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<double> _calculateRunningAverages(List<WeightEntry> entries) {
    final averages = <double>[];
    
    // Group entries by date and calculate daily averages
    final Map<String, List<WeightEntry>> dailyGroups = {};
    for (final entry in entries) {
      final dateKey = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
      dailyGroups.putIfAbsent(dateKey, () => []).add(entry);
    }
    
    // Calculate daily averages
    final List<WeightEntry> dailyAverages = [];
    dailyGroups.forEach((dateKey, dayEntries) {
      final sum = dayEntries.fold<double>(0, (sum, entry) => sum + entry.weight);
      final average = sum / dayEntries.length;
      dailyAverages.add(WeightEntry(
        weight: average,
        date: dayEntries.first.date,
      ));
    });
    
    // Sort by date
    dailyAverages.sort((a, b) => a.date.compareTo(b.date));
    
    // Calculate running averages using daily averages
    for (int i = 0; i < entries.length; i++) {
      final currentDate = entries[i].date;
      final startDate = currentDate.subtract(const Duration(days: 4));
      
      final relevantDailyAverages = dailyAverages.where((entry) {
        return entry.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
               entry.date.isBefore(currentDate.add(const Duration(days: 1)));
      }).toList();
      
      if (relevantDailyAverages.isNotEmpty) {
        final sum = relevantDailyAverages.fold<double>(0, (sum, entry) => sum + entry.weight);
        averages.add(sum / relevantDailyAverages.length);
      } else {
        averages.add(entries[i].weight);
      }
    }
    
    return averages;
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
