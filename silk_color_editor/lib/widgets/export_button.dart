import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/editor_state.dart';
import '../services/hsb_processor.dart';
import '../services/image_compositor.dart';
import '../services/export/export_service.dart';

class ExportButton extends StatelessWidget {
  const ExportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorState>(
      builder: (context, state, _) {
        return state.isExporting
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : IconButton(
                onPressed: () => _export(context, state),
                icon: const Icon(Icons.save_alt),
                tooltip: 'Export Image',
              );
      },
    );
  }

  Future<void> _export(BuildContext context, EditorState state) async {
    if (state.baseImageBytes == null || state.overlayImageBytes == null) {
      _showMessage(context, 'Images not loaded yet', isError: true);
      return;
    }

    state.setExporting(true);

    try {
      // Process base image with HSB adjustments
      final processedBase = await HSBProcessor.processImage(
        ProcessingParams(
          sourceBytes: state.baseImageBytes!,
          hue: state.hue,
          saturation: state.saturation,
          brightness: state.brightness,
        ),
      );

      // Composite with overlay
      final composite = await ImageCompositor.createComposite(
        CompositeParams(
          baseBytes: processedBase,
          overlayBytes: state.overlayImageBytes!,
        ),
      );

      // Export
      final exportService = createExportService();
      final success = await exportService.exportImage(
        composite,
        'SILK_Export_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      if (context.mounted) {
        if (success) {
          _showMessage(context, 'Image exported successfully!');
        } else {
          _showMessage(context, 'Export cancelled', isError: false);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Export failed: $e', isError: true);
      }
    } finally {
      state.setExporting(false);
    }
  }

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
