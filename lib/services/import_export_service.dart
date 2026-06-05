import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../models/weight_entry.dart';
import 'csv_service.dart';

class ImportResult {
  final List<WeightEntry>? entries;
  final List<String> errors;
  final String? fileName;
  final bool cancelled;

  const ImportResult({
    this.entries,
    this.errors = const [],
    this.fileName,
    this.cancelled = false,
  });

  bool get hasEntries => entries != null && entries!.isNotEmpty;
}

class ImportExportService {
  Future<ImportResult> pickAndParseCsv(String dateFormat) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return const ImportResult(cancelled: true);
    }

    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null) {
      return const ImportResult(
        errors: ['Could not read the selected file'],
      );
    }

    final content = utf8.decode(bytes);
    final parseResult = CsvService.parseCsvContent(content, dateFormat);

    if (parseResult.errors.isNotEmpty && !parseResult.hasEntries) {
      return ImportResult(
        errors: parseResult.errors,
        fileName: file.name,
      );
    }

    return ImportResult(
      entries: parseResult.entries,
      errors: parseResult.errors,
      fileName: file.name,
    );
  }

  Future<void> exportCsv({
    required String content,
    required String fileName,
  }) async {
    final bytes = utf8.encode(content);

    await FilePicker.platform.saveFile(
      fileName: fileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
  }
}
