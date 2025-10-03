import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weight_entry.dart';
import '../database/database_helper.dart';
import '../services/settings_service.dart';

class WeightEntryForm extends StatefulWidget {
  final Function()? onWeightAdded;

  const WeightEntryForm({super.key, this.onWeightAdded});

  @override
  State<WeightEntryForm> createState() => _WeightEntryFormState();
}

class _WeightEntryFormState extends State<WeightEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SettingsService _settingsService = SettingsService();
  String _weightUnit = 'kg';
  String _dateFormat = 'dd/MM/yyyy';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh settings when returning from settings
    _loadSettings();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final unit = await _settingsService.getWeightUnit();
    final format = await _settingsService.getDateFormat();
    setState(() {
      _weightUnit = unit;
      _dateFormat = format;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveWeight() async {
    if (_formKey.currentState!.validate()) {
      final weight = double.parse(_weightController.text);
      final entry = WeightEntry(
        weight: weight,
        date: _selectedDate,
      );

      try {
        await _dbHelper.insertWeightEntry(entry);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Weight entry saved successfully!')),
          );
          _weightController.clear();
          widget.onWeightAdded?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving weight: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (value) {
                        if (_formKey.currentState!.validate()) {
                          _saveWeight();
                        }
                      },
                      // style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                      decoration: InputDecoration(
                        labelText: _settingsService.getWeightUnitLabel(_weightUnit),
                        border: const OutlineInputBorder(),
                        // prefixIcon: Icon(Icons.monitor_weight),
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          // prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat(_dateFormat).format(_selectedDate),
                          // style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: _saveWeight,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
