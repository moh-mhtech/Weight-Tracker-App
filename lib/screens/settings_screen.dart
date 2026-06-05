import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/settings_provider.dart';
import '../services/csv_service.dart';
import '../services/import_export_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;
  
  const SettingsScreen({super.key, this.onDataChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ImportExportService _importExportService = ImportExportService();
  late TextEditingController _averagePeriodController;
  
  @override
  void initState() {
    super.initState();
    _averagePeriodController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  @override
  void dispose() {
    _averagePeriodController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _averagePeriodController.text = settingsProvider.runningAverageDays.toString();
  }


  Future<void> _importData() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    try {
      final result = await _importExportService.pickAndParseCsv(
        settingsProvider.dateFormat,
      );

      if (!mounted || result.cancelled) {
        return;
      }

      if (!result.hasEntries) {
        final errorMessage = result.errors.isNotEmpty
            ? result.errors.join('\n')
            : 'No valid entries found in the selected file';
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Failed'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      if (result.errors.isNotEmpty && mounted) {
        final continueImport = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Warnings'),
            content: Text(
              '${result.errors.length} row(s) could not be parsed:\n\n'
              '${result.errors.take(5).join('\n')}'
              '${result.errors.length > 5 ? '\n...' : ''}\n\n'
              'Import ${result.entries!.length} valid entries anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Import'),
              ),
            ],
          ),
        );

        if (continueImport != true) {
          return;
        }
      }

      if (!mounted) {
        return;
      }

      final fileLabel = result.fileName ?? 'selected file';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: Text(
            'Import ${result.entries!.length} entries from $fileLabel?\n\n'
            'Entries will be added to existing data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }

      await _dbHelper.importWeightEntries(result.entries!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${result.entries!.length} entries'),
          ),
        );
        widget.onDataChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing data: $e')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    try {
      final entries = await _dbHelper.getAllWeightEntries();

      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to export')),
          );
        }
        return;
      }

      final content = CsvService.buildCsvContent(
        entries,
        settingsProvider.dateFormat,
        settingsProvider.runningAverageDays,
      );

      await _importExportService.exportCsv(
        content: content,
        fileName: CsvService.generateDefaultFilename(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
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
          // Notify the parent screen that data has changed
          widget.onDataChanged?.call();
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
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Weight Unit Setting
              Card(
                child: ListTile(
                  title: const Text('Weight Unit'),
                  trailing: DropdownButton<String>(
                    value: settingsProvider.weightUnit,
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        await settingsProvider.setWeightUnit(newValue);
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
                    value: settingsProvider.dateFormat,
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        await settingsProvider.setDateFormat(newValue);
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
                              await settingsProvider.setRunningAverageDays(parsedValue);
                            }
                          },
                        ),
                      ),
                      
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Data'),
                  subtitle: const Text('Save weight data as CSV'),
                  onTap: _exportData,
                ),
              ),

              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Import Data'),
                  subtitle: const Text('Import weight data from CSV'),
                  onTap: _importData,
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
            ],
          );
        },
      ),
    );
  }
}
