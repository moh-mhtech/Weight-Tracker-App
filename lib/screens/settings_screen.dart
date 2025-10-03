import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SettingsService _settingsService = SettingsService();
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
    final unit = await _settingsService.getWeightUnit();
    final format = await _settingsService.getDateFormat();
    final days = await _settingsService.getRunningAverageDays();
    
    setState(() {
      _weightUnit = unit;
      _dateFormat = format;
      _runningAverageDays = days;
    });
    _averagePeriodController.text = _runningAverageDays.toString();
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
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    setState(() {
                      _weightUnit = newValue;
                    });
                    await _settingsService.setWeightUnit(newValue);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'lbs', child: Text('lbs')),
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
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    setState(() {
                      _dateFormat = newValue;
                    });
                    await _settingsService.setDateFormat(newValue);
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Average Period',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      textAlign: TextAlign.right,
                      controller: _averagePeriodController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Days',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) async {
                        final parsedValue = int.tryParse(value);
                        if (parsedValue != null && parsedValue > 0) {
                          setState(() {
                            _runningAverageDays = parsedValue;
                          });
                          await _settingsService.setRunningAverageDays(parsedValue);
                        }
                      },
                    ),
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
