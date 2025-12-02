import 'dart:typed_data';

// Conditional export for factory
export 'export_stub.dart'
    if (dart.library.io) 'export_desktop.dart'
    if (dart.library.html) 'export_web.dart';

abstract class ExportService {
  Future<bool> exportImage(Uint8List imageBytes, String suggestedName);
}
