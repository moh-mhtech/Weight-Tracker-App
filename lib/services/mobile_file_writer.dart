import 'dart:io';

Future<String> writeCsvToTempDir(
  String directory,
  String fileName,
  List<int> bytes,
) async {
  final file = File('$directory/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
