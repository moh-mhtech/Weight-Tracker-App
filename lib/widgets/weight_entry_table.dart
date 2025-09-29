import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weight_entry.dart';

class WeightEntryTable extends StatelessWidget {
  final List<WeightEntry> weightEntries;
  final int visibleEntriesCount;
  final Function(WeightEntry) onEditEntry;
  final Function(WeightEntry) onDeleteEntry;
  final VoidCallback? onLoadMore;
  final bool hasMoreEntries;

  const WeightEntryTable({
    super.key,
    required this.weightEntries,
    required this.visibleEntriesCount,
    required this.onEditEntry,
    required this.onDeleteEntry,
    this.onLoadMore,
    this.hasMoreEntries = false,
  });

  @override
  Widget build(BuildContext context) {
    // Show only the visible entries (newest first)
    final visibleEntries = weightEntries.reversed.take(visibleEntriesCount).toList();

    // Calculate running averages for all entries
    final runningAverages = _calculateRunningAverages(weightEntries);
    
    // Create a map of entry index to running average
    final Map<int, double> entryToRunningAverage = {};
    for (int i = 0; i < weightEntries.length; i++) {
      entryToRunningAverage[i] = runningAverages[i];
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            ...visibleEntries.map((entry) {
              final entryIndex = weightEntries.indexOf(entry);
              final runningAvg = entryToRunningAverage[entryIndex] ?? 0.0;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date row
                    Text(
                      DateFormat('dd/MM/yy').format(entry.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    // Measurement, average, and actions row
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${entry.weight.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'avg ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${runningAvg.toStringAsFixed(1)} kg',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey, size: 22),
                                onPressed: () => onEditEntry(entry),
                                padding: EdgeInsets.zero,
                                // constraints: const BoxConstraints( minWidth: 28 ),
                                constraints: BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey, size: 22),
                                onPressed: () => onDeleteEntry(entry),
                                padding: EdgeInsets.zero,
                                // constraints: const BoxConstraints( minWidth: 28 ),
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // const SizedBox(height: 8),
                    // const Divider(height: 1),
                  ],
                ),
              );
            }),
            // Load More button
            if (hasMoreEntries && onLoadMore != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: onLoadMore,
                    icon: const Icon(Icons.expand_more),
                    label: Text('Load More (${weightEntries.length - visibleEntriesCount} remaining)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
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
}
