import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';

class ConfigService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<bool> exportToFile() async {
    try {
      final data = await _db.exportAll();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Configuration',
        fileName: 'water_tasks_config.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path == null) return false;
      await File(path).writeAsString(json);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Configuration',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return false;
      final file = File(result.files.single.path!);
      final json = await file.readAsString();
      final data = (jsonDecode(json) as List<dynamic>).cast<Map<String, dynamic>>();
      await _db.importAll(data);
      return true;
    } catch (_) {
      return false;
    }
  }
}
