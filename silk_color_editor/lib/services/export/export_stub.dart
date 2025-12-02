import 'dart:typed_data';
import 'export_service.dart';

class PlatformExportService implements ExportService {
  @override
  Future<bool> exportImage(Uint8List imageBytes, String suggestedName) {
    throw UnsupportedError('Export not supported on this platform');
  }
}

ExportService createExportService() => PlatformExportService();
