import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weight_entry.dart';
import '../providers/settings_provider.dart';
import '../services/average_calculation_service.dart';

class WeightEntryTable extends StatefulWidget {
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
  State<WeightEntryTable> createState() => _WeightEntryTableState();
}

class _WeightEntryTableState extends State<WeightEntryTable> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        // Show only the visible entries (newest first)
        final visibleEntries = widget.weightEntries.reversed.take(widget.visibleEntriesCount).toList();

        // Calculate running averages for entry dates
        final dateToRunningAverage = AverageCalculationService.calcDateAverages(
          widget.weightEntries,
          settingsProvider.runningAverageDays,
        );

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            ...visibleEntries.map((entry) {
              // Normalize the entry date to match the keys in dateToRunningAverage
              final normalizedDate = DateTime.utc(entry.date.year, entry.date.month, entry.date.day);
              final runningAvg = dateToRunningAverage[normalizedDate] ?? 0.0;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                // decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date row
                    Text(
                      DateFormat(settingsProvider.dateFormat).format(entry.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontWeight: FontWeight.w500,
                        
                      ),
                    ),
                    
                    // Measurement, average, and actions row
                    Container(
                      // decoration: BoxDecoration(color: Colors.red.withAlpha(50)),
                      padding: const EdgeInsets.only(left: 8.0),
                      // padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                            Text(
                              '${entry.weight.toStringAsFixed(1)} ${settingsProvider.getWeightUnitDisplay(settingsProvider.weightUnit)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              overflow: TextOverflow.visible
                            ),
                          RichText(
                              // decoration: BoxDecoration(color: Colors.red.withAlpha(50)),
                              overflow: TextOverflow.visible,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'avg ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.tertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${runningAvg.toStringAsFixed(1)} ${settingsProvider.getWeightUnitDisplay(settingsProvider.weightUnit)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context).colorScheme.tertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            // mainAxisSize: MainAxisSize.min,
                            // crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                iconSize: 22,
                                icon: const Icon(Icons.edit),
                                color: Theme.of(context).colorScheme.onSecondary,
                                    onPressed: () => widget.onEditEntry(entry),
                                padding: EdgeInsets.zero,
                                style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                visualDensity: VisualDensity(horizontal: -2.0, vertical: -4.0),
                                // constraints: const BoxConstraints(),
                                // visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
                                  ),
                              
                              IconButton(
                                  iconSize: 22,
                                  icon: const Icon(Icons.delete),
                                  color: Theme.of(context).colorScheme.onSecondary,
                                  style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  onPressed: () => widget.onDeleteEntry(entry),
                                  padding: EdgeInsets.zero,
                                  // constraints: const BoxConstraints(),
                                  // constraints: const BoxConstraints(minWidth: 0, minHeight: 0, maxHeight: 12),
                                  visualDensity: VisualDensity(horizontal: -2.0, vertical: -4.0),
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
            if (widget.hasMoreEntries && widget.onLoadMore != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: widget.onLoadMore,
                    icon: const Icon(Icons.expand_more),
                    label: Text('Load More (${widget.weightEntries.length - widget.visibleEntriesCount} remaining)'),
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
      },
    );
  }
}
