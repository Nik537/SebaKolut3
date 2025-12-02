import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class CompositeParams {
  final Uint8List baseBytes;
  final Uint8List overlayBytes;

  CompositeParams({
    required this.baseBytes,
    required this.overlayBytes,
  });
}

class ImageCompositor {
  /// Merge base image with overlay in a background isolate
  static Future<Uint8List> createComposite(CompositeParams params) async {
    return compute(_compositeIsolate, params);
  }

  static Uint8List _compositeIsolate(CompositeParams params) {
    final base = img.decodeImage(params.baseBytes);
    final overlay = img.decodeImage(params.overlayBytes);

    if (base == null || overlay == null) {
      throw Exception('Failed to decode images');
    }

    // Resize overlay to match base if needed
    img.Image resizedOverlay;
    if (overlay.width != base.width || overlay.height != base.height) {
      resizedOverlay = img.copyResize(
        overlay,
        width: base.width,
        height: base.height,
        interpolation: img.Interpolation.linear,
      );
    } else {
      resizedOverlay = overlay;
    }

    // Composite: draw overlay on top of base using alpha blending
    img.compositeImage(
      base,
      resizedOverlay,
      dstX: 0,
      dstY: 0,
    );

    return Uint8List.fromList(img.encodePng(base));
  }
}
