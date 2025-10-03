import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TextEditingController _averagePeriodController;
  
  // Settings state
  String _weightUnit = 'kg';
  String _dateFormat = 'dd/MM/yyyy';
  int _runningAverageDays = 5;
  
  @override
  void initState() {
    super.initState();
    _averagePeriodController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _averagePeriodController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
        
    setState(() {
      _weightUnit = prefs.getString('weight_unit') ?? 'kg';
      _dateFormat = prefs.getString('date_format') ?? 'dd/MM/yyyy';
      _runningAverageDays = prefs.getInt('running_average_days') ?? 5;
    });
    _averagePeriodController.text = _runningAverageDays.toString();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weight_unit', _weightUnit);
    await prefs.setString('date_format', _dateFormat);
    await prefs.setInt('running_average_days', _runningAverageDays);
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all weight entries? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.clearAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All data has been cleared')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing data: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Weight Unit Setting
          Card(
            child: ListTile(
              title: const Text('Weight Unit'),
              trailing: DropdownButton<String>(
                value: _weightUnit,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _weightUnit = newValue;
                    });
                    _saveSettings();
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('Kilograms (kg)')),
                  DropdownMenuItem(value: 'lbs', child: Text('Pounds (lbs)')),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Date Format Setting
          Card(
            child: ListTile(
              title: const Text('Date Format'),
              trailing: DropdownButton<String>(
                value: _dateFormat,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _dateFormat = newValue;
                    });
                    _saveSettings();
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('dd/MM/yyyy')),
                  DropdownMenuItem(value: 'MM/dd/yyyy', child: Text('MM/dd/yyyy')),
                  DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('yyyy-MM-dd')),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Running Average Days Setting
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Average Period',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  TextField(
                      controller: _averagePeriodController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Days',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final parsedValue = int.tryParse(value);
                        if (parsedValue != null && parsedValue > 0) {
                          setState(() {
                            _runningAverageDays = parsedValue;
                          });
                          _saveSettings();
                        }
                      },
                    ),
                  
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          
          // Clear All Data
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Clear All Data'),
              // subtitle: const Text('Delete all weight entries'),
              onTap: _clearAllData,
            ),
          ),
          
          // const SizedBox(height: 8),
          
          // // Export Data
          // Card(
          //   child: ListTile(
          //     leading: const Icon(Icons.download),
          //     title: const Text('Export Data'),
          //     // subtitle: const Text('Copy data to clipboard as CSV'),
          //     onTap: _exportData,
          //   ),
          // ),
          
          // const SizedBox(height: 8),
          
          // // Import Data
          // Card(
          //   child: ListTile(
          //     leading: const Icon(Icons.upload),
          //     title: const Text('Import Data'),
          //     // subtitle: const Text('Import data from clipboard CSV'),
          //     onTap: _importData,
          //   ),
          // ),
        ],
      ),
    );
  }
}
