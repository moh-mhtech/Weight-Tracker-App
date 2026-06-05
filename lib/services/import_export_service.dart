import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';
    final xFile = XFile.fromData(
      bytes,
      name: fileName,
      mimeType: 'text/csv',
      path: filePath,
    );

    await Share.shareXFiles(
      [xFile],
      subject: 'Weight data export',
      text: 'Weight data export',
    );
  }
}
