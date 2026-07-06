import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Saves bytes to the device Downloads (or Documents) folder.
/// Returns the full file path on success.
Future<String> saveExcelFile(List<int> bytes, String fileName) async {
  Directory? dir;
  try { dir = await getDownloadsDirectory(); } catch (_) {}
  dir ??= await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
  return file.path;
}
