import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'export_service.dart';

class PlatformExportService implements ExportService {
  @override
  Future<bool> exportImage(Uint8List imageBytes, String suggestedName) async {
    try {
      // Create blob from bytes
      final blob = html.Blob([imageBytes], 'image/png');

      // Create download URL
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create anchor element and trigger download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', suggestedName)
        ..style.display = 'none';

      html.document.body!.children.add(anchor);
      anchor.click();

      // Cleanup
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return true;
    } catch (e) {
      print('Web export error: $e');
      return false;
    }
  }
}

ExportService createExportService() => PlatformExportService();
