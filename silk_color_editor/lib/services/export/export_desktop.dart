import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'export_service.dart';

class PlatformExportService implements ExportService {
  @override
  Future<bool> exportImage(Uint8List imageBytes, String suggestedName) async {
    try {
      // Show save dialog
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Image',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (result == null) return false; // User cancelled

      // Ensure .png extension
      String filePath = result;
      if (!filePath.toLowerCase().endsWith('.png')) {
        filePath += '.png';
      }

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      return true;
    } catch (e) {
      print('Export error: $e');
      return false;
    }
  }
}

ExportService createExportService() => PlatformExportService();
